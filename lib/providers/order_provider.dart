import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:molo/models/order_model.dart';
import 'package:molo/models/order_payload_model.dart' as payload;
import 'package:molo/models/delivery_estimate_model.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/services/api_service.dart';
import 'package:molo/providers/websocket_provider.dart';
import 'package:molo/providers/notification_provider.dart';
import 'package:molo/constants/api_constants.dart';

// Custom exception classes for better error handling
class OrderException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  OrderException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'OrderException: $message';
}

class OrderProvider with ChangeNotifier {
  final _logger = Logger();
  final ApiService _apiService;
  final WebSocketProvider _webSocketProvider;
  final NotificationProvider _notificationProvider;

  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _lastError;
  int _retryCount = 0;
  static const int maxRetries = 3;
  Timer? _pollingTimer;
  bool _isDisposed = false;
  bool _isDeletingAllOrders = false;

  set currentOrder(OrderModel? order) {
    if (_isDisposed) return;
    _currentOrder = order;
    debugPrint('OrderProvider: set currentOrder() - notifying listeners');
    notifyListeners();
  }

  OrderProvider(this._apiService, this._webSocketProvider, this._notificationProvider) {
    _webSocketProvider.addListener(_handleWebSocketOrderUpdates);
  }

  void _handleWebSocketOrderUpdates() {
    try {
      if (_webSocketProvider.lastOrderUpdateData != null) {
        final previousStatus = _currentOrder?.status;
        _updateOrderStatus(_webSocketProvider.lastOrderUpdateData);

        // Check if driver was just found
        if (previousStatus != OrderStatus.accepted && _currentOrder?.status == OrderStatus.accepted) {
          _onDriverFound();
        }
      }
    } catch (e) {
      _handleError('WebSocket update failed', e);
    }
  }

  void _onDriverFound() {
    _stopBackgroundPolling();
    _notificationProvider.showDriverFoundNotification(_currentOrder!.id);
  }

  // Background polling for order status updates
  void _startBackgroundPolling(String orderId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Stop polling if order is already accepted or cancelled
      if (_currentOrder?.status == OrderStatus.accepted || _currentOrder?.status == OrderStatus.cancelled) {
        timer.cancel();
        return;
      }

      try {
        if (kDebugMode) {
          print('Background polling: Making API call to GET /api/orders/$orderId');
        }

        // Make API call to check current order status
        final order = await _apiService.getOrderDetails(orderId);

        if (order != null) {
          if (kDebugMode) {
            print('Background polling: Received response for order ${order.id}, status: ${order.status}');
          }

          // Update current order with latest status
          _currentOrder = order;
          if (!_isDisposed) {
            notifyListeners();
          }

          // Check if driver was just found
          if (order.status == OrderStatus.accepted) {
            if (kDebugMode) {
              print('Background polling: Driver found! Stopping polling.');
            }
            _onDriverFound();
            timer.cancel();
          } else if (order.status == OrderStatus.cancelled) {
            // Order was cancelled by backend
            if (kDebugMode) {
              print('Background polling: Order cancelled by backend. Stopping polling.');
            }
            timer.cancel();
          }

          if (kDebugMode) {
            print('Background polling: Order ${order.id} status is ${order.status}');
          }
        } else {
          if (kDebugMode) {
            print('Background polling: No order found for $orderId');
          }
        }
      } catch (e) {
        // Continue polling even if there's an error
        if (kDebugMode) {
          print('Background polling API error: $e');
        }
      }
    });
  }

  // Getters with error state
  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;

  // Clear error state
  void clearError() {
    if (_isDisposed) return;
    _lastError = null;
    debugPrint('OrderProvider: clearError() - notifying listeners');
    notifyListeners();
  }

  // Helper method to convert order type string to enum
  payload.OrderType _getOrderTypeFromString(String? orderTypeString) {
    switch (orderTypeString) {
      case 'delivery':
        return payload.OrderType.FOOD_DELIVERY;
      case 'ride_hailing':
        return payload.OrderType.RIDE;
      case 'parcel_delivery':
        return payload.OrderType.PARCEL_DELIVERY;
      case 'medical_product':
        return payload.OrderType.MEDICAL_PRODUCT;
      case 'patient_transport':
        return payload.OrderType.PATIENT_TRANSPORT;
      default:
        return payload.OrderType.RIDE; // Default fallback
    }
  }

  // Generic error handler
  void _handleError(String operation, dynamic error) {
    if (_isDisposed) return;
    debugPrint('OrderProvider Error in $operation: $error');

    if (error is Exception) {
      _lastError = _getErrorMessage(error);
    } else {
      _lastError = 'An unexpected error occurred during $operation';
    }

    debugPrint('OrderProvider: _handleError() - notifying listeners');
    notifyListeners();
  }

  // Extract meaningful error messages
  String _getErrorMessage(Exception error) {
    if (error.toString().contains('401')) {
      return 'Authentication failed. Please log in again.';
    } else if (error.toString().contains('403')) {
      return 'Access denied. You don\'t have permission for this action.';
    } else if (error.toString().contains('404')) {
      return 'Resource not found. The requested data may no longer exist.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toString().contains('501')) {
      return 'Service temporarily unavailable. Please try again later.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  // Retry mechanism with exponential backoff
  Future<T?> _executeWithRetry<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    _retryCount = 0;

    while (_retryCount < maxRetries) {
      try {
        clearError();
        return await operation();
      } catch (e) {
        _retryCount++;

        if (_retryCount >= maxRetries) {
          _handleError(operationName, e);
          return null;
        }

        // Exponential backoff: wait 1s, 2s, 4s before retries
        await Future.delayed(Duration(seconds: 1 << (_retryCount - 1)));
      }
    }
    return null;
  }

  Future<OrderModel?> createOrder(Map<String, dynamic> orderData) async {
    _logger.i('OrderProvider: Starting createOrder API call.');
    // Validate required fields
    final requiredFields = [
      'client_id',
      'order_type',
      'pickup_address',
      'pickup_latitude',
      'pickup_longitude',
      'dropoff_address',
      'dropoff_latitude',
      'dropoff_longitude',
    ];

    for (String field in requiredFields) {
      if (!orderData.containsKey(field) || orderData[field] == null) {
        _handleError(
          'create order',
          Exception('Missing required field: $field'),
        );
        return null;
      }
    }

    try {
      final result = await _executeWithRetry<OrderModel>(() async {

        // Convert orderData to NewOrderPayload
        final orderPayload = payload.NewOrderPayload(
          clientId: orderData['client_id'],
          orderType: _getOrderTypeFromString(orderData['order_type']),
          pickupAddress: orderData['pickup_address'] ?? '',
          pickupLatitude: orderData['pickup_latitude']?.toString() ?? '',
          pickupLongitude: orderData['pickup_longitude']?.toString() ?? '',
          dropoffAddress: orderData['dropoff_address'],
          dropoffLatitude: orderData['dropoff_latitude']?.toString() ?? '',
          dropoffLongitude: orderData['dropoff_longitude']?.toString() ?? '',
          distanceKm: orderData['distance_km']?.toString() ?? '0',
          specialInstructions: orderData['special_instructions'],
          patientDetails: orderData['patient_details'],
          medicalItems: orderData['medical_items'],
          isEmergency: orderData['is_emergency'],
          conditionCode: orderData['patient_condition'],
          patientNotes: orderData['special_instructions'],
        );

        final order = await _apiService.createOrder(orderPayload);
        if (order == null) {
          throw Exception('Failed to create order');
        }
        return order;
      }, 'create order');

      if (result != null) {
        // Clear local orders list and set the new order
        _orders.clear();
        _orders.insert(0, result);
        _currentOrder = result;
        // The WebSocketProvider now handles its own connection and initial status request
        // No explicit subscription call needed here.
      }

      return result;
    } catch (e) {
      _logger.e('OrderProvider: Failed to create order.', error: e);
      _handleError('create order', e);
      return null;
    }
  }



  void _stopBackgroundPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<List<OrderModel>> fetchUserOrders(String clientId) async {
    _isLoading = true;
    if (!_isDisposed) {
      notifyListeners();
    }
    try {
      final response = await _executeWithRetry<List<OrderModel>>(() async {
        return await _apiService.getOrders();
      }, 'fetch user orders');

      if (response != null) {
        return response;
      }
      return [];
    } finally {
      _isLoading = false;
      if (!_isDisposed) {
        debugPrint('OrderProvider: fetchUserOrders() - notifying listeners');
        notifyListeners();
      }
    }
  }

  Future<void> getOrderHistory({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    print('Fetching order history for client ${_currentOrder?.clientId}...');
    _isLoading = true;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      // Fetch all orders for current client inferred by auth token
      _orders = await _apiService.getOrders();
      if (kDebugMode) {
        print('Orders fetched: ${_orders.length}');
      }
    } catch (e) {
      print('Error fetching order history: $e');
    } finally {
      _isLoading = false;
      if (!_isDisposed) {
        debugPrint('OrderProvider: getOrderHistory() - notifying listeners');
        notifyListeners();
      }
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    if (orderId.isEmpty) {
      _handleError('get order', Exception('Order ID cannot be empty'));
      return null;
    }

    _isLoading = true;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      final result = await _executeWithRetry<OrderModel>(() async {
        final order = await _apiService.getOrderDetails(orderId);
        if (order == null) throw Exception('Order not found');
        return order;
      }, 'fetch order details');

      if (result != null) {
        _currentOrder = result;
      }

      return result;
    } finally {
      _isLoading = false;
      if (!_isDisposed) {
        debugPrint('OrderProvider: getOrderById() - notifying listeners');
        notifyListeners();
      }
    }
  }

  Future<void> refreshOrders() async {
    await getOrderHistory();
  }

  void _updateOrderStatus(Map<String, dynamic> data) {
    try {
      if (!data.containsKey('order_id') || !data.containsKey('status')) {
        throw Exception('Invalid order update data');
      }

      final String orderId = data['order_id']; // Changed to 'order_id'
      final String newStatusString = data['status'];

      final OrderStatus newStatus = OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == newStatusString,
        orElse: () => OrderStatus.pending,
      );

      final int index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = OrderModel(
          id: _orders[index].id,
          clientId: _orders[index].clientId,
          driverId: _orders[index].driverId,
          status: newStatus,
          orderType: _orders[index].orderType,
          pickupAddress: _orders[index].pickupAddress,
          pickupLatitude: _orders[index].pickupLatitude,
          pickupLongitude: _orders[index].pickupLongitude,
          dropoffAddress: _orders[index].dropoffAddress,
          dropoffLatitude: _orders[index].dropoffLatitude,
          dropoffLongitude: _orders[index].dropoffLongitude,
          price: _orders[index].price,
          distanceKm: _orders[index].distanceKm,
          specialInstructions: _orders[index].specialInstructions,
          createdAt: _orders[index].createdAt,
          paymentId: _orders[index].paymentId, // Added payment information
          paymentStatus: _orders[index].paymentStatus, // Added payment status
        );
        _orders[index] = updatedOrder;
        if (_currentOrder?.id == orderId) {
          _currentOrder = updatedOrder;
        }
        notifyListeners();
      }
    } catch (e) {
      _handleError('update order status', e);
    }
  }

  Future<bool> recalculateRoute(String orderId) async {
    if (orderId.isEmpty) {
      _handleError('recalculate route', Exception('Order ID cannot be empty'));
      return false;
    }

    final result = await _executeWithRetry<bool>(() async {
      await _apiService.recalculateOrderRoute(orderId);
      return true;
    }, 'recalculate route');

    return result ?? false;
  }

  Future<bool> trackOrder(String orderId) async {
    if (orderId.isEmpty) {
      _handleError('track order', Exception('Order ID cannot be empty'));
      return false;
    }

    final result = await _executeWithRetry<bool>(() async {
      await _apiService.startOrderTracking(orderId);
      return true;
    }, 'track order');

    return result ?? false;
  }


  Future<bool> cancelOrder(String orderId) async {
    // Find the order to check its status
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    final order = orderIndex != -1 ? _orders[orderIndex] : null;

    // If order is not accepted, use delete_all instead of cancel
    if (order != null && order.status != OrderStatus.accepted) {
      try {
        await deleteAllOrders();
        // Stop background polling
        _stopBackgroundPolling();
        // Disconnect WebSocket
        _webSocketProvider.disconnect();
        return true;
      } catch (e) {
        _handleError('delete orders', e);
        return false;
      }
    }

    // If order is accepted or not found locally, try to cancel it
    final result = await _executeWithRetry<OrderModel?>(() async {
      return await _apiService.cancelOrder(orderId);
    }, 'cancel order');

    if (result != null) {
      // Update local order status
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = result;
        if (_currentOrder?.id == orderId) {
          _currentOrder = result;
        }
        notifyListeners();
      }

      // Stop background polling
      _stopBackgroundPolling();

      // Disconnect WebSocket
      _webSocketProvider.disconnect();
    }

    return result != null;
  }

  Future<OrderModel?> updateOrder(OrderModel updatedOrder) async {
    _logger.i('OrderProvider: Starting updateOrder API call for ID: ${updatedOrder.id}');
    try {
      final result = await _executeWithRetry<OrderModel>(() async {
        return await _apiService.editOrder(updatedOrder.id, updatedOrder);
      }, 'update order');

      if (result != null) {
        // Update local list
        final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
        if (index != -1) {
          _orders[index] = result;
          if (_currentOrder?.id == updatedOrder.id) {
            _currentOrder = result;
          }
          notifyListeners();
        }
      }

      return result;
    } catch (e) {
      _logger.e('OrderProvider: Failed to update order.', error: e);
      _handleError('update order', e);
      return null;
    }
  }

  Future<DeliveryEstimateModel> estimateOrder({
    required LocationModel pickupLocation,
    required LocationModel dropoffLocation,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      // Create estimate request payload (different from order creation payload)
      final estimateRequest = {
        'service_type': orderData['order_type'] == 'delivery' ? 'food_delivery' : 'ride_hailing',
        'pickup_latitude': pickupLocation.latitude,
        'pickup_longitude': pickupLocation.longitude,
        'dropoff_latitude': dropoffLocation.latitude,
        'dropoff_longitude': dropoffLocation.longitude,
        'passenger_count': 1,
        'vehicle_type': 'standard',
      };

      final estimate = await _apiService.estimateOrder(estimateRequest);
      return estimate;
    } catch (e) {
      _handleError('estimate order', e);
      rethrow;
    }
  }

  Future<void> deleteAllOrders() async {
    if (_isDeletingAllOrders) {
      _logger.w('OrderProvider: Skipping deleteAllOrders as another delete operation is in progress.');
      return;
    }

    _isDeletingAllOrders = true;
    try {
      await _executeWithRetry<void>(() async {
        await _apiService.delete('${ApiConstants.apiPrefix}/orders/delete_all');
      }, 'delete all orders');
      _orders.clear();
      _currentOrder = null;
      // No notifyListeners() here, as the screen managing the process will handle its own state.
    } catch (e) {
      _handleError('delete all orders', e);
    } finally {
      _isDeletingAllOrders = false;
    }
  }

  @override
  void dispose() {
    debugPrint('OrderProvider: dispose() called');
    _isDisposed = true;
    _stopBackgroundPolling();
    _webSocketProvider.removeListener(_handleWebSocketOrderUpdates);
    super.dispose();
    debugPrint('OrderProvider: dispose() completed');
  }
}
