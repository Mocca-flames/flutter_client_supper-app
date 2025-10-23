class ApiConstants {
  static const String baseWebSocketUrl = 'wss://192.168.8.101:8000/ws/track/';
  static const String apiPrefix = '/api';
  static const String userProfileEndpoint = '/user/profile';
  
  // Order-related endpoints
  static const String createOrderEndpoint = '/client/orders';
  static const String getOrdersEndpoint = '/client/orders';
  static const String getOrderDetailsEndpoint = '/client/orders/';  // Append order_id
  static const String startOrderTrackingEndpoint = '/orders/';  // Append order_id/track
  static const String cancelOrderEndpoint = '/orders/';  // Append order_id/cancel
  static const String getDriverLocationEndpoint = '/orders/';  // Append order_id/location
  static const String verifyPaymentEndpoint = '/orders/';  // Append order_id/verify-payment
}
