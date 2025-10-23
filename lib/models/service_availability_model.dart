class ServiceAvailabilityModel {
  final String serviceId;
  final bool isAvailable;
  final String? message; // e.g., "Service available", "Currently unavailable in your area"
  final String? estimatedWaitTime; // e.g., "10-15 minutes"
  final Map<String, dynamic>? operationalHours; // e.g., {"monday": "9am-5pm", ...}
  // Add any other relevant fields

  ServiceAvailabilityModel({
    required this.serviceId,
    required this.isAvailable,
    this.message,
    this.estimatedWaitTime,
    this.operationalHours,
  });

  factory ServiceAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return ServiceAvailabilityModel(
      serviceId: json['service_id'] as String,
      isAvailable: json['is_available'] as bool,
      message: json['message'] as String?,
      estimatedWaitTime: json['estimated_wait_time'] as String?,
      operationalHours: json['operational_hours'] != null
          ? Map<String, dynamic>.from(json['operational_hours'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'is_available': isAvailable,
      'message': message,
      'estimated_wait_time': estimatedWaitTime,
      'operational_hours': operationalHours,
    };
  }
}
