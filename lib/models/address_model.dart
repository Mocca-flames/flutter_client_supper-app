class AddressModel {
  final String? id;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? fullAddress; // For a concatenated full address string

  AddressModel({
    this.id,
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    this.fullAddress,
    this.placeId,
    this.placeName,
  });

  final String? placeId;
  final String? placeName;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String?,
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fullAddress: json['full_address'] as String? ??
                   _buildFullAddress(json), // Fallback to build from parts
      placeId: json['place_id'] as String?,
      placeName: json['place_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'street': street,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'full_address': fullAddress,
      'place_id': placeId,
      'place_name': placeName,
    };
  }

  // Helper to construct a full address if not provided directly
  static String _buildFullAddress(Map<String, dynamic> json) {
    List<String> parts = [];
    if (json['street'] != null) parts.add(json['street']);
    if (json['city'] != null) parts.add(json['city']);
    if (json['state'] != null) parts.add(json['state']);
    if (json['postal_code'] != null) parts.add(json['postal_code']);
    if (json['country'] != null) parts.add(json['country']);
    return parts.join(', ');
  }
}
