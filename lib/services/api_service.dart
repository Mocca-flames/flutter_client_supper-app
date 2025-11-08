import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:logger/logger.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'firebase_auth_service.dart';
import 'config_service.dart'; // Import ConfigService
import '../constants/api_constants.dart'; // Import ApiConstants
import '../models/order_model.dart';
import '../models/order_payload_model.dart';
import '../models/location_model.dart'; // For Address and Location-based services
import '../models/address_model.dart';
import '../models/scheduled_order_model.dart';
import '../models/schedule_request_model.dart';
import '../models/service_availability_model.dart';
import '../models/delivery_estimate_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart'; // Import UserModel
import '../models/driver_location_model.dart'; // Added for driver location
import '../models/route_model.dart';
import '../models/tracking_session_response_model.dart';

class ApiService {
  final Dio _dio;
  final FirebaseAuthService _authService;
  final ConfigService _configService;
  late final String _baseUrl;
  var logger = Logger();

  ApiService(this._dio, this._authService, this._configService) {
    _baseUrl = _configService.baseUrl;
    if (kDebugMode) {
      print('[ApiService] Initialized with baseUrl: $_baseUrl');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _authService.getIdToken();
    if (token == null) {
      logger.d(
        'ApiService: Auth token is null. User might not be authenticated.',
      );
      throw Exception(
        'Authentication token not available. Please sign in again.',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'API Error: ${response.statusCode} ${response.statusMessage}',
      );
    }
  }

  dynamic _handleError(DioException error) {
    if (kDebugMode) {
      print('ApiService Error: ${error.message}');
    }
    if (error.response != null) {
      if (kDebugMode) {
        print('Error Response Data: ${error.response?.data}');
      }
      String errorMessage =
          error.response?.data?['detail'] ??
          error.response?.data?['message'] ??
          error.message ??
          'Unknown API error';
      throw Exception(
        'API Error: ${error.response?.statusCode} - $errorMessage',
      );
    }
    throw Exception(
      'Network Error: ${error.message ?? "Unknown network error"}',
    );
  }

  // Basic HTTP Methods
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.get(
        '$_baseUrl$endpoint',
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        '$_baseUrl$endpoint',
        data: data,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.put(
        '$_baseUrl$endpoint',
        data: data,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> patch(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.patch(
        '$_baseUrl$endpoint',
        data: data,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await _dio.delete(
        '$_baseUrl$endpoint',
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // Authentication & User Management
  Future<dynamic> registerClient(String firebaseUid) async {
    final String endpoint = '${ApiConstants.apiPrefix}/auth/register';
    final Map<String, String> queryParams = {
      'firebase_uid': firebaseUid,
      'user_type': 'client',
    };
    try {
      final headers = await _getHeaders();
      final response = await _dio.post(
        '$_baseUrl$endpoint',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 409) {
        logger.d(
          'ApiService.registerClient: User already registered (409 Conflict). Response: ${e.response?.data}',
        );
        return e.response?.data ??
            {'status': 'success', 'message': 'User already registered.'};
      } else {
        _handleError(e);
        throw Exception(
          'Unhandled API error after attempting to register client.',
        );
      }
    } catch (e) {
      logger.d('ApiService.registerClient: Unexpected error - $e');
      throw Exception(
        'Failed to register client due to an unexpected error: ${e.toString()}',
      );
    }
  }

  Future<UserModel> getUserProfile() async {
    final responseData = await get(
      '${ApiConstants.apiPrefix}${ApiConstants.userProfileEndpoint}',
    );
    if (kDebugMode) {
      print('[ApiService.getUserProfile] Raw response data: $responseData');
    }
    // Assuming the responseData is the raw JSON map containing user profile details
    // which UserModel.fromJson is now configured to handle (full_name, phone_number).
    final userModel = UserModel.fromJson(responseData as Map<String, dynamic>);
    if (kDebugMode) {
      print('[ApiService.getUserProfile] Parsed UserModel: $userModel');
    }
    return userModel;
  }

  Future<dynamic> updateUserProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    final userData = <String, dynamic>{};
    if (fullName != null) userData['full_name'] = fullName;
    if (phoneNumber != null) userData['phone_number'] = phoneNumber;

    return await put(
      '${ApiConstants.apiPrefix}${ApiConstants.userProfileEndpoint}',
      userData,
    );
  }

  Future<dynamic> updateClientProfile({String? homeAddress}) async {
    final profileData = <String, dynamic>{};
    if (homeAddress != null) profileData['home_address'] = homeAddress;

    return await put('${ApiConstants.apiPrefix}/client/profile', profileData);
  }

  // Order Management
  Future<OrderModel?> createOrder(NewOrderPayload payload) async {
    const String endpoint =
        '${ApiConstants.apiPrefix}${ApiConstants.createOrderEndpoint}';
    final orderData = payload.toJson();

    if (kDebugMode) {
      print(
        '[ApiService.createOrder] Posting to $_baseUrl$endpoint with data: $orderData',
      );
    }
    try {
      final responseData = await post(endpoint, orderData);
      if (responseData != null) {
        if (kDebugMode) {
          print('[ApiService.createOrder] Response data: $responseData');
        }
        return OrderModel.fromJson(responseData as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.createOrder] Error creating order: $e');
      }
      rethrow;
    }
  }

  Future<DeliveryEstimateModel> estimateOrder(
    Map<String, dynamic> estimateRequest,
  ) async {
    const String endpoint = '${ApiConstants.apiPrefix}/client/orders/estimate';

    if (kDebugMode) {
      print(
        '[ApiService.estimateOrder] Posting to $_baseUrl$endpoint with data: $estimateRequest',
      );
    }
    try {
      final responseData = await post(endpoint, estimateRequest);
      if (kDebugMode) {
        print('[ApiService.estimateOrder] Response data: $responseData');
      }
      return DeliveryEstimateModel.fromJson(
        responseData as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.estimateOrder] Error estimating order: $e');
      }
      rethrow;
    }
  }

  Future<List<OrderModel>> getOrders() async {
    const String endpoint = '${ApiConstants.apiPrefix}/client/orders';
    if (kDebugMode) {
      print('[ApiService.getOrders] Getting from $_baseUrl$endpoint');
    }
    try {
      final responseData = await get(endpoint);
      if (responseData != null && responseData is List) {
        if (kDebugMode) {
          print('[ApiService.getOrders] Response data: $responseData');
        }
        return responseData
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.getOrders] Error fetching orders: $e');
      }
      rethrow;
    }
  }

  Future<OrderModel?> getOrderDetails(String orderId) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}${ApiConstants.getOrderDetailsEndpoint}$orderId';
    if (kDebugMode) {
      print('[ApiService.getOrderDetails] Getting from $_baseUrl$endpoint');
    }
    try {
      final responseData = await get(endpoint);
      if (responseData != null) {
        if (kDebugMode) {
          print('[ApiService.getOrderDetails] Response data: $responseData');
        }
        return OrderModel.fromJson(responseData as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.getOrderDetails] Direct GET failed, attempting fallback via list: $e',
        );
      }
      // Fallback: some backends may not expose GET /orders/{id}. Try list + filter.
      try {
        final all = await getOrders();
        for (final o in all) {
          if (o.id == orderId) return o;
        }
        return null;
      } catch (e2) {
        if (kDebugMode) {
          print('[ApiService.getOrderDetails] Fallback via list failed: $e2');
        }
        return null;
      }
    }
  }

  Future<List<OrderModel>> getOrderHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/orders/history?page=$page&limit=$limit';
    if (kDebugMode) {
      print('[ApiService.getOrderHistory] Getting from $_baseUrl$endpoint');
    }
    try {
      final responseData = await get(endpoint);
      if (responseData != null && responseData['orders'] is List) {
        return (responseData['orders'] as List)
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.getOrderHistory] Error fetching order history: $e');
      }
      rethrow;
    }
  }

  Future<OrderModel?> cancelOrder(String orderId) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}${ApiConstants.cancelOrderEndpoint}$orderId/cancel';
    if (kDebugMode) {
      print('[ApiService.cancelOrder] Patching to $_baseUrl$endpoint');
    }
    try {
      final responseData = await patch(endpoint, {});
      if (kDebugMode) {
        print('[ApiService.cancelOrder] Response data: $responseData');
      }
      return OrderModel.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.cancelOrder] Error cancelling order: $e');
      }
      rethrow;
    }
  }

  Future<OrderModel> updateOrderStatus(String orderId, String newStatus) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/client/orders/$orderId/status';
    if (kDebugMode) {
      print(
        '[ApiService.updateOrderStatus] Patching to $_baseUrl$endpoint with status: $newStatus',
      );
    }
    try {
      final responseData = await patch(endpoint, {'status': newStatus});
      if (kDebugMode) {
        print(
          '[ApiService.updateOrderStatus] Response data for order $orderId: $responseData',
        );
      }
      return OrderModel.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.updateOrderStatus] Error updating status for order $orderId: $e',
        );
      }
      rethrow;
    }
  }

  Future<OrderModel> editOrder(String orderId, OrderModel updatedOrder) async {
    final String endpoint = '${ApiConstants.apiPrefix}/client/orders/$orderId';
    if (kDebugMode) {
      print(
        '[ApiService.editOrder] Putting to $_baseUrl$endpoint with data: ${updatedOrder.toJson()}',
      );
    }
    try {
      final responseData = await put(endpoint, updatedOrder.toJson());
      if (kDebugMode) {
        print(
          '[ApiService.editOrder] Response data for order $orderId: $responseData',
        );
      }
      return OrderModel.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.editOrder] Error editing order $orderId: $e');
      }
      rethrow;
    }
  }

  // Order Tracking & Routes
  Future<RouteModel?> getOrderRoute(String orderId) async {
    final String endpoint = '${ApiConstants.apiPrefix}/orders/$orderId/route';
    if (kDebugMode) {
      print('[ApiService.getOrderRoute] Getting from $_baseUrl$endpoint');
    }
    try {
      final responseData = await get(endpoint);
      if (responseData != null) {
        if (kDebugMode) {
          print('[ApiService.getOrderRoute] Response data: $responseData');
        }
        return RouteModel.fromJson(responseData as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.getOrderRoute] Error fetching order route: $e');
      }
      rethrow;
    }
  }

  Future<TrackingSessionResponse?> startOrderTracking(String orderId) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}${ApiConstants.startOrderTrackingEndpoint}$orderId/track';
    if (kDebugMode) {
      print('[ApiService.startOrderTracking] Posting to $_baseUrl$endpoint');
    }
    try {
      final responseData = await post(endpoint, {});
      if (kDebugMode) {
        print('[ApiService.startOrderTracking] Response data: $responseData');
      }
      if (responseData != null && responseData is Map<String, dynamic>) {
        return TrackingSessionResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.startOrderTracking] Error starting tracking: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> recalculateOrderRoute(String orderId) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/orders/$orderId/recalculate-route';
    if (kDebugMode) {
      print('[ApiService.recalculateOrderRoute] Posting to $_baseUrl$endpoint');
    }
    try {
      final responseData = await post(endpoint, {});
      if (kDebugMode) {
        print(
          '[ApiService.recalculateOrderRoute] Response data: $responseData',
        );
      }
      return responseData;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.recalculateOrderRoute] Error recalculating route: $e',
        );
      }
      rethrow;
    }
  }

  // Driver Location & Tracking
  Future<DriverLocationModel?> getDriverLocation(String driverId) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/client/driver/$driverId/location';
    if (kDebugMode) {
      print('[ApiService.getDriverLocation] Getting from $_baseUrl$endpoint');
    }
    try {
      final responseData = await get(endpoint);
      if (responseData != null) {
        if (kDebugMode) {
          print(
            '[ApiService.getDriverLocation] Response data for driver $driverId: $responseData',
          );
        }
        return DriverLocationModel.fromJson(
          responseData as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.getDriverLocation] Error fetching driver location for $driverId: $e',
        );
      }
      rethrow;
    }
  }

  Future<DriverLocationModel?> getCurrentDriverLocationForOrder(
    String orderId,
  ) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/orders/$orderId/location';
    if (kDebugMode) {
      print(
        '[ApiService.getCurrentDriverLocationForOrder] Getting from $_baseUrl$endpoint',
      );
    }
    try {
      final responseData = await get(endpoint);
      if (responseData != null) {
        if (kDebugMode) {
          print(
            '[ApiService.getCurrentDriverLocationForOrder] Response data: $responseData',
          );
        }
        return DriverLocationModel.fromJson(
          responseData as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.getCurrentDriverLocationForOrder] Error fetching driver location: $e',
        );
      }
      rethrow;
    }
  }

  // Scheduling
  Future<ScheduledOrderModel> scheduleDelivery(
    ScheduleRequestModel request,
  ) async {
    const String endpoint = '${ApiConstants.apiPrefix}/orders/schedule';
    if (kDebugMode) {
      print('[ApiService.scheduleDelivery] Posting to $_baseUrl$endpoint');
    }
    try {
      final responseData = await post(endpoint, request.toJson());
      if (kDebugMode) {
        print('[ApiService.scheduleDelivery] Response data: $responseData');
      }
      return ScheduledOrderModel.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.scheduleDelivery] Error scheduling delivery: $e');
      }
      rethrow;
    }
  }

  // Service Availability & Estimates
  Future<ServiceAvailabilityModel> checkServiceAvailability(
    String serviceId,
    double lat,
    double lng,
  ) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/services/$serviceId/availability?lat=$lat&lng=$lng';
    if (kDebugMode) {
      print(
        '[ApiService.checkServiceAvailability] Getting from $_baseUrl$endpoint',
      );
    }
    try {
      final responseData = await get(endpoint);
      if (kDebugMode) {
        print(
          '[ApiService.checkServiceAvailability] Response data: $responseData',
        );
      }
      return ServiceAvailabilityModel.fromJson(
        responseData as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.checkServiceAvailability] Error checking availability: $e',
        );
      }
      rethrow;
    }
  }

  Future<DeliveryEstimateModel> getDeliveryEstimate(
    String serviceId,
    LocationModel from,
    LocationModel to,
  ) async {
    const String endpoint = '${ApiConstants.apiPrefix}/delivery/estimate';
    final requestData = {
      'service_id': serviceId,
      'pickup': {'lat': from.latitude, 'lng': from.longitude},
      'dropoff': {'lat': to.latitude, 'lng': to.longitude},
    };

    if (kDebugMode) {
      print(
        '[ApiService.getDeliveryEstimate] Posting to $_baseUrl$endpoint with data: $requestData',
      );
    }
    try {
      final responseData = await post(endpoint, requestData);
      if (kDebugMode) {
        print('[ApiService.getDeliveryEstimate] Response data: $responseData');
      }
      return DeliveryEstimateModel.fromJson(
        responseData as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.getDeliveryEstimate] Error getting estimate: $e');
      }
      rethrow;
    }
  }

  // Notifications
  Future<List<NotificationModel>> getNotifications() async {
    const String endpoint = '${ApiConstants.apiPrefix}/notifications';
    if (kDebugMode) {
      print('[ApiService.getNotifications] Getting from $_baseUrl$endpoint');
    }
    try {
      final responseData = await get(endpoint);
      if (responseData is List) {
        if (kDebugMode) {
          print('[ApiService.getNotifications] Response data: $responseData');
        }
        return responseData
            .map(
              (json) =>
                  NotificationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.getNotifications] Error fetching notifications: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> markNotificationAsRead(String notificationId) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/notifications/$notificationId/read';
    if (kDebugMode) {
      print(
        '[ApiService.markNotificationAsRead] Patching to $_baseUrl$endpoint',
      );
    }
    try {
      final responseData = await patch(endpoint, {});
      if (kDebugMode) {
        print(
          '[ApiService.markNotificationAsRead] Response data: $responseData',
        );
      }
      return responseData;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.markNotificationAsRead] Error marking notification as read: $e',
        );
      }
      rethrow;
    }
  }

  Future<dynamic> clearAllNotifications() async {
    const String endpoint = '${ApiConstants.apiPrefix}/notifications/clear';
    if (kDebugMode) {
      print('[ApiService.clearAllNotifications] Deleting $_baseUrl$endpoint');
    }
    try {
      final responseData = await delete(endpoint);
      if (kDebugMode) {
        print(
          '[ApiService.clearAllNotifications] Response data: $responseData',
        );
      }
      return responseData;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.clearAllNotifications] Error clearing notifications: $e',
        );
      }
      rethrow;
    }
  }

  // Google Places — Autocomplete (replaces Mapbox search)
  Future<List<AddressModel>> searchAddresses({
    required String query,
    double? proximityLat,
    double? proximityLng,
    int limit = 5,
    String? sessionToken,
    String components = 'country:ZA',
    int? radiusMeters,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, dynamic>{
        'input': query,
        'key': _configService.googleMapsApiKey,
        'components': components,
      };

      // Add location bias if provided
      if (proximityLat != null && proximityLng != null) {
        params['location'] = '$proximityLat,$proximityLng';
      }
      if (radiusMeters != null) {
        params['radius'] = radiusMeters;
      }
      if (sessionToken != null && sessionToken.isNotEmpty) {
        params['sessiontoken'] = sessionToken;
      }

      if (kDebugMode) {
        print(
          '[ApiService.searchAddresses] Google Places Autocomplete for: $query params: $params',
        );
      }

      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data['predictions'] != null) {
        final List<dynamic> predictions = response.data['predictions'];
        final limited = predictions.take(limit);
        final results = limited.map((p) {
          final sf = p['structured_formatting'] ?? {};
          return AddressModel(
            fullAddress: p['description'],
            placeId: p['place_id'],
            placeName: sf['main_text'] ?? p['description'],
          );
        }).toList();

        if (kDebugMode) {
          print(
            '[ApiService.searchAddresses] Found ${results.length} predictions',
          );
        }
        return results;
      } else {
        if (kDebugMode) {
          print(
            '[ApiService.searchAddresses] No predictions found or non-200 status',
          );
        }
        return [];
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[ApiService.searchAddresses] Dio error: ${e.message}');
      }
      throw Exception('Failed to search addresses: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.searchAddresses] Unexpected error: $e');
      }
      throw Exception('Failed to search addresses: $e');
    }
  }







  Future<AddressModel?> reverseGeocode({
    required double lat,
    required double lng,
    CancelToken? cancelToken,
    String components = 'country:ZA',
  }) async {
    if (kDebugMode) {
      print('[ApiService.reverseGeocode] Requesting address for: $lat, $lng using Flutter geocoding');
    }

    try {
      final flutterPlacemarks = await geocoding.placemarkFromCoordinates(lat, lng);

      if (flutterPlacemarks.isNotEmpty) {
        final p = flutterPlacemarks.first;
        final address = _buildAddressFromPlacemark(p, lat, lng);

        if (kDebugMode) {
          print('[ApiService.reverseGeocode] Successful: ${address.fullAddress}');
        }

        return address;
      }

      if (kDebugMode) {
        print('[ApiService.reverseGeocode] No placemarks found for $lat,$lng');
      }
      return null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ApiService.reverseGeocode] Error during Flutter geocoding: $e\n$stack');
      }
      throw Exception('Failed to reverse geocode using Flutter geocoding: $e');
    }
  }

  // Helper method to build AddressModel from Flutter geocoding Placemark
  AddressModel _buildAddressFromPlacemark(geocoding.Placemark placemark, double lat, double lng) {
    // Prioritize place name: street > subLocality > locality > administrativeArea > country
    String placeName = placemark.street ??
                      placemark.subLocality ??
                      placemark.locality ??
                      placemark.administrativeArea ??
                      placemark.country ??
                      'Unknown Location';

    // Build full address with better prioritization
    List<String> addressParts = [];

    // Add street if available
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }

    // Add subLocality if available and different from street
    if (placemark.subLocality != null &&
        placemark.subLocality!.isNotEmpty &&
        placemark.subLocality != placemark.street) {
      addressParts.add(placemark.subLocality!);
    }

    // Add locality (city) if available
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }

    // Add administrative area (province/state) if available
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }

    // Add country if available and no other parts
    if (addressParts.isEmpty && placemark.country != null && placemark.country!.isNotEmpty) {
      addressParts.add(placemark.country!);
    }

    String fullAddress = addressParts.isNotEmpty ? addressParts.join(', ') : 'Near current location';

    return AddressModel(
      fullAddress: fullAddress,
      latitude: lat,
      longitude: lng,
      placeName: placeName,
      street: placemark.street,
      city: placemark.locality,
      state: placemark.administrativeArea,
      country: placemark.country,
      postalCode: placemark.postalCode,
    );
  }

  // Nearby places via Google Places Nearby Search
  Future<List<AddressModel>> searchNearbyPlaces({
    required double lat,
    required double lng,
    String category = 'poi',
    int limit = 10,
    int radiusMeters = 1500,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '[ApiService.searchNearbyPlaces] Google Nearby: $category @ $lat,$lng',
        );
      }

      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'radius': radiusMeters,
          'keyword': category,
          'key': _configService.googleMapsApiKey,
        },
      );

      if (response.statusCode == 200 && response.data['results'] != null) {
        final List<dynamic> resultsJson = response.data['results'];
        final results = resultsJson.take(limit).map((r) {
          final geom = r['geometry']?['location'] ?? {};
          return AddressModel(
            fullAddress: r['vicinity'] ?? r['name'],
            latitude: (geom['lat'] as num?)?.toDouble(),
            longitude: (geom['lng'] as num?)?.toDouble(),
            placeId: r['place_id'],
            placeName: r['name'],
          );
        }).toList();
        if (kDebugMode) {
          print(
            '[ApiService.searchNearbyPlaces] Found ${results.length} nearby places',
          );
        }
        return results;
      } else {
        if (kDebugMode) {
          print('[ApiService.searchNearbyPlaces] No nearby results (Google)');
        }
        return [];
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[ApiService.searchNearbyPlaces] Dio error: ${e.message}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.searchNearbyPlaces] Unexpected error: $e');
      }
      return [];
    }
  }

  // Google Place Details and Directions
  Future<LocationModel?> placeDetails({
    required String placeId,
    String? sessionToken,
    String fields = 'geometry,name,formatted_address,place_id',
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': fields,
          'key': _configService.googleMapsApiKey,
          'sessiontoken': sessionToken,
        },
      );

      if (response.statusCode == 200 && response.data['result'] != null) {
        final r = response.data['result'];
        final loc = r['geometry']?['location'] ?? {};
        return LocationModel(
          latitude: (loc['lat'] as num).toDouble(),
          longitude: (loc['lng'] as num).toDouble(),
          address: r['formatted_address'],
          placeId: r['place_id'],
          placeName: r['name'],
        );
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[ApiService.placeDetails] Dio error: ${e.message}');
      }
      throw Exception('Failed to fetch place details: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.placeDetails] Unexpected error: $e');
      }
      throw Exception('Failed to fetch place details: $e');
    }
  }

  Future<Map<String, dynamic>?> directions({
    required LocationModel origin,
    required LocationModel destination,
    String mode = 'driving',
    bool alternatives = false,
  }) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': mode,
          'alternatives': alternatives.toString(),
          'key': _configService.googleMapsApiKey,
        },
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[ApiService.directions] Dio error: ${e.message}');
      }
      throw Exception('Failed to get directions: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.directions] Unexpected error: $e');
      }
      throw Exception('Failed to get directions: $e');
    }
  }

  // Utility Methods
  Future<bool> checkConnectivity() async {
    try {
      final response = await _dio.get(
        '$_baseUrl${ApiConstants.apiPrefix}/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.checkConnectivity] Connectivity check failed: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> getApiStatus() async {
    try {
      final response = await get('${ApiConstants.apiPrefix}/status');
      return response as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.getApiStatus] Error getting API status: $e');
      }
      return null;
    }
  }

  void dispose() {
    _dio.close();
  }

  // Payment Methods
  Future<Map<String, dynamic>> createPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
    String paymentType = 'client_payment',
    String? gateway,
  }) async {
    final String endpoint = '${ApiConstants.apiPrefix}/payments/create';
    final requestData = {
      'user_id': userId,
      'order_id': orderId,
      'payment_type': paymentType,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      if (gateway != null) 'gateway': gateway,
    };

    if (kDebugMode) {
      print(
        '[ApiService.createPayment] Posting to $_baseUrl$endpoint with data: $requestData',
      );
    }

    try {
      final responseData = await post(endpoint, requestData);
      if (kDebugMode) {
        print('[ApiService.createPayment] Response data: $responseData');
      }
      return responseData as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('[ApiService.createPayment] Error creating payment: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initializePaystackPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
    String paymentType = 'client_payment',
  }) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/payments/paystack/initialize';
    final requestData = {
      'user_id': userId,
      'order_id': orderId,
      'payment_type': paymentType,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
    };

    if (kDebugMode) {
      print(
        '[ApiService.initializePaystackPayment] Posting to $_baseUrl$endpoint with data: $requestData',
      );
    }

    try {
      final responseData = await post(endpoint, requestData);
      if (kDebugMode) {
        print(
          '[ApiService.initializePaystackPayment] Response data: $responseData',
        );
      }
      return responseData as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.initializePaystackPayment] Error initializing Paystack payment: $e',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyPaystackPayment(String reference) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}/payments/paystack/verify/$reference';

    if (kDebugMode) {
      print(
        '[ApiService.verifyPaystackPayment] Getting from $_baseUrl$endpoint',
      );
    }

    try {
      final responseData = await get(endpoint);
      if (kDebugMode) {
        print(
          '[ApiService.verifyPaystackPayment] Response data: $responseData',
        );
      }
      return responseData as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[ApiService.verifyPaystackPayment] Error verifying Paystack payment: $e',
        );
      }
      rethrow;
    }
  }

  Future<dynamic> verifyPayment(String orderId) async {
    final String endpoint =
        '${ApiConstants.apiPrefix}${ApiConstants.verifyPaymentEndpoint}$orderId/verify-payment';
    final responseData = await get(endpoint);
    return responseData;
  }
} // End of ApiService class
