class EstimateDetails {
  final double baseFare;
  final double distanceFare;
  final double serviceFee;
  final double total;
  final int? estimatedDurationMinutes;
  final String currency;
  final double surgeMultiplier;
  final double medicalSurcharge;
  final double packageSurcharge;
  final double deliveryFee;

  EstimateDetails({
    required this.baseFare,
    required this.distanceFare,
    required this.serviceFee,
    required this.total,
    this.estimatedDurationMinutes,
    required this.currency,
    required this.surgeMultiplier,
    required this.medicalSurcharge,
    required this.packageSurcharge,
    required this.deliveryFee,
  });

  factory EstimateDetails.fromJson(Map<String, dynamic> json) {
    return EstimateDetails(
      baseFare: (json['base_fare'] as num).toDouble(),
      distanceFare: (json['distance_fare'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
      currency: json['currency'] as String,
      surgeMultiplier: (json['surge_multiplier'] as num).toDouble(),
      medicalSurcharge: (json['medical_surcharge'] as num).toDouble(),
      packageSurcharge: (json['package_surcharge'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_fare': baseFare,
      'distance_fare': distanceFare,
      'service_fee': serviceFee,
      'total': total,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'currency': currency,
      'surge_multiplier': surgeMultiplier,
      'medical_surcharge': medicalSurcharge,
      'package_surcharge': packageSurcharge,
      'delivery_fee': deliveryFee,
    };
  }
}

class DeliveryEstimateModel {
  final EstimateDetails estimate;
  final String validUntil;
  final String? specialInstructions;

  DeliveryEstimateModel({
    required this.estimate,
    required this.validUntil,
    this.specialInstructions,
  });

  factory DeliveryEstimateModel.fromJson(Map<String, dynamic> json) {
    return DeliveryEstimateModel(
      estimate: EstimateDetails.fromJson(json['estimate'] as Map<String, dynamic>),
      validUntil: json['valid_until'] as String,
      specialInstructions: json['special_instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimate': estimate.toJson(),
      'valid_until': validUntil,
      'special_instructions': specialInstructions,
    };
  }
}
