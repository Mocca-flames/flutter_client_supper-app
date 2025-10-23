// Enum for different types of orders
// ignore_for_file: constant_identifier_names

enum OrderType {
  RIDE,
  FOOD_DELIVERY,
  PARCEL_DELIVERY,
  MEDICAL_PRODUCT,
  PATIENT_TRANSPORT,
}

// Helper function to convert OrderType enum to its string representation
String orderTypeToString(OrderType type) {
  switch (type) {
    case OrderType.RIDE:
      return 'ride_hailing';
    case OrderType.FOOD_DELIVERY:
      return 'food_delivery';
    case OrderType.PARCEL_DELIVERY:
      return 'parcel_delivery';
    case OrderType.MEDICAL_PRODUCT:
      return 'medical_product';
    case OrderType.PATIENT_TRANSPORT:
      return 'patient_transport';
  }
}

class NewOrderPayload {
  final String clientId; // Added clientId
  final OrderType orderType;
  final String pickupAddress;
  final String pickupLatitude;
  final String pickupLongitude;
  final String dropoffAddress;
  final String dropoffLatitude;
  final String dropoffLongitude;
  final String? distanceKm;
  final String? specialInstructions;
  final String? patientDetails;
  final String? medicalItems;
  final bool? isEmergency;
  final String? conditionCode;
  final String? patientNotes;

  NewOrderPayload({
    required this.clientId, // Added clientId
    required this.orderType,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    this.distanceKm,
    this.specialInstructions,
    this.patientDetails,
    this.medicalItems,
    this.isEmergency,
    this.conditionCode,
    this.patientNotes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['client_id'] = clientId; // Added clientId
    data['order_type'] = orderTypeToString(orderType); // Use helper to convert enum to string
    data['pickup_address'] = pickupAddress;
    data['dropoff_address'] = dropoffAddress;

    // Ensure all optional fields are included as strings if they have a value.
    // The .toString() is redundant if they are already strings, but ensures compliance.
    data['pickup_latitude'] = pickupLatitude.toString();
    data['pickup_longitude'] = pickupLongitude.toString();
    data['dropoff_latitude'] = dropoffLatitude.toString();
    data['dropoff_longitude'] = dropoffLongitude.toString();
    if (distanceKm != null) {
      data['distance_km'] = distanceKm;
    }
    if (specialInstructions != null) {
      data['special_instructions'] = specialInstructions;
    }
    if (patientDetails != null) {
      data['patient_details'] = patientDetails;
    }
    if (medicalItems != null) {
      data['medical_items'] = medicalItems;
    }
    if (isEmergency != null) {
      data['is_emergency'] = isEmergency;
    }
    if (conditionCode != null) {
      data['condition_code'] = conditionCode;
    }
    if (patientNotes != null) {
      data['patient_notes'] = patientNotes;
    }

    return data;
  }
}
