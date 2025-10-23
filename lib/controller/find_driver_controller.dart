import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/order_model.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';

class FindDriverController extends ChangeNotifier {
  final BuildContext context;
  final LocationModel pickupLocation;
  final LocationModel dropoffLocation;
  final OrderModel order;

  FindDriverController({
    required this.context,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.order,
  });

  late final OrderProvider _orderProvider;
  late final AuthProvider _authProvider;
  bool _providersInitialized = false;

  void _initializeProviders() {
    if (_providersInitialized) return;

    _orderProvider = Provider.of<OrderProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _orderProvider.addListener(_onOrderProviderChanged);
    _providersInitialized = true;
  }

  bool _disposed = false;

  // Safe state update method that checks if the controller is disposed
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _onOrderProviderChanged() {
    debugPrint('FindDriverController: _onOrderProviderChanged() called');
    _safeNotifyListeners();
  }

  bool get isLoading {
    _initializeProviders();
    return _orderProvider.isLoading;
  }

  double? get estimatedPrice {
    _initializeProviders();
    return _orderProvider.currentOrder?.price;
  }

  bool get isDriverFound {
    _initializeProviders();
    return _orderProvider.currentOrder?.status == OrderStatus.accepted;
  }

  String? get errorMessage {
    _initializeProviders();
    return _orderProvider.lastError;
  }

  Future<void> findDriver() async {
    _initializeProviders();

    final clientId = _authProvider.currentUser?.uid;
    if (clientId == null) {
      throw Exception('User not authenticated');
    }

    if (kDebugMode) {
      print('FindDriverController: Starting findDriver process for client: $clientId');
    }

    // Create order payload from the provided order and locations
    final orderData = {
      'client_id': clientId,
      'order_type': order.orderType == OrderType.delivery ? 'delivery' : 'pickup',
      'pickup_address': pickupLocation.address,
      'pickup_latitude': pickupLocation.latitude,
      'pickup_longitude': pickupLocation.longitude,
      'dropoff_address': dropoffLocation.address,
      'dropoff_latitude': dropoffLocation.latitude,
      'dropoff_longitude': dropoffLocation.longitude,
      'special_instructions': order.specialInstructions,
    };

    await _orderProvider.createOrder(orderData);

    if (kDebugMode) {
      print('FindDriverController: findDriver process completed, order created and WebSocket connection active');
    }
  }


  @override
  void dispose() {
    debugPrint('FindDriverController: dispose() called');
    _disposed = true;
    if (_providersInitialized) {
      _orderProvider.removeListener(_onOrderProviderChanged);
    }
    super.dispose();
    debugPrint('FindDriverController: dispose() completed');
  }
}