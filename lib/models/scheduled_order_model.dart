import 'location_model.dart'; // For pickup/dropoff locations
// Potentially import OrderModel if ScheduledOrder shares many fields
// import 'order_model.dart'; 

class ScheduledOrderModel {
  final String id;
  final String userId;
  final String serviceType; // e.g., "parcel_delivery", "food_delivery"
  final LocationModel pickupLocation;
  final LocationModel dropoffLocation;
  final DateTime scheduledPickupTime;
  final DateTime? scheduledDropoffTime; // Could be an estimate
  final String status; // e.g., "scheduled", "confirmed", "cancelled"
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduledOrderModel({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.scheduledPickupTime,
    this.scheduledDropoffTime,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduledOrderModel.fromJson(Map<String, dynamic> json) {
    return ScheduledOrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      serviceType: json['service_type'] as String,
      pickupLocation: LocationModel.fromJson(json['pickup_location'] as Map<String, dynamic>),
      dropoffLocation: LocationModel.fromJson(json['dropoff_location'] as Map<String, dynamic>),
      scheduledPickupTime: DateTime.parse(json['scheduled_pickup_time'] as String),
      scheduledDropoffTime: json['scheduled_dropoff_time'] != null
          ? DateTime.tryParse(json['scheduled_dropoff_time'] as String)
          : null,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'service_type': serviceType,
      'pickup_location': pickupLocation.toJson(),
      'dropoff_location': dropoffLocation.toJson(),
      'scheduled_pickup_time': scheduledPickupTime.toIso8601String(),
      'scheduled_dropoff_time': scheduledDropoffTime?.toIso8601String(),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
