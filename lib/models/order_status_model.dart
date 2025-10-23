// Assuming LocationModel might be used for driver location
import 'location_model.dart'; 

class OrderStatusModel {
  final String orderId;
  final String status; // e.g., "pending", "processing", "out_for_delivery", "delivered", "cancelled"
  final DateTime? estimatedDeliveryTime;
  final DateTime? lastUpdateTime;
  final String? currentStepDescription; // e.g., "Driver is picking up your order"
  final LocationModel? driverLocation; // Optional: if tracking driver location

  OrderStatusModel({
    required this.orderId,
    required this.status,
    this.estimatedDeliveryTime,
    this.lastUpdateTime,
    this.currentStepDescription,
    this.driverLocation,
  });

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      orderId: json['order_id'] as String,
      status: json['status'] as String,
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.tryParse(json['estimated_delivery_time'] as String)
          : null,
      lastUpdateTime: json['last_update_time'] != null
          ? DateTime.tryParse(json['last_update_time'] as String)
          : null,
      currentStepDescription: json['current_step_description'] as String?,
      driverLocation: json['driver_location'] != null
          ? LocationModel.fromJson(json['driver_location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'status': status,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'last_update_time': lastUpdateTime?.toIso8601String(),
      'current_step_description': currentStepDescription,
      'driver_location': driverLocation?.toJson(),
    };
  }
}
