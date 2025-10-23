import 'location_model.dart'; // For pickup/dropoff locations

class ScheduleRequestModel {
  final String userId; // Or this might be inferred from auth token on backend
  final String serviceType;
  final LocationModel pickupLocation;
  final LocationModel dropoffLocation;
  final DateTime scheduledPickupTime;
  final DateTime? preferredDropoffTime; // Optional, backend might calculate
  final String? notes;
  // Add any other relevant fields for scheduling, e.g., payment_method_id, promo_code

  ScheduleRequestModel({
    required this.userId,
    required this.serviceType,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.scheduledPickupTime,
    this.preferredDropoffTime,
    this.notes,
  });

  // No fromJson needed if this model is only used for sending data to the API
  // factory ScheduleRequestModel.fromJson(Map<String, dynamic> json) { ... }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'service_type': serviceType,
      'pickup_location': pickupLocation.toJson(),
      'dropoff_location': dropoffLocation.toJson(),
      'scheduled_pickup_time': scheduledPickupTime.toIso8601String(),
      'preferred_dropoff_time': preferredDropoffTime?.toIso8601String(),
      'notes': notes,
    };
  }
}
