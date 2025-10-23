import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'address_model.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeId; // Place identifier (e.g., Google Place ID)
  final String? placeName; // Formatted place name
  final List<dynamic>? context; // Place context (city, region, etc.)

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeId,
    this.placeName,
    this.context,
  });

  // Factory constructor to create a LocationModel from a JSON object
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      placeId: json['placeId'] as String?,
      placeName: json['placeName'] as String?,
      context: json['context'] as List<dynamic>?,
    );
  }

  // Method to convert LocationModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeId': placeId,
      'placeName': placeName,
      'context': context,
    };
  }

  // Method to calculate distance to another LocationModel
  // Returns distance in kilometers
  double distanceTo(LocationModel other) {
    const R = 6371; // Radius of the earth in km
    var dLat = _deg2rad(other.latitude - latitude);
    var dLon = _deg2rad(other.longitude - longitude);
    var a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(latitude)) * cos(_deg2rad(other.latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    var d = R * c; // Distance in km
    return d;
  }

  double _deg2rad(deg) {
    return deg * (pi / 180);
  }


  // Converts to Google Maps LatLng format
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  // Creates LocationModel from Google Maps LatLng
  factory LocationModel.fromLatLng(LatLng latLng, {String? address}) {
    return LocationModel(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      address: address,
    );
  }

  // Creates LocationModel from AddressModel (e.g., from reverse geocoding)
  factory LocationModel.fromAddressModel(AddressModel addressModel) {
    return LocationModel(
      latitude: addressModel.latitude ?? 0.0,
      longitude: addressModel.longitude ?? 0.0,
      address: addressModel.fullAddress,
      placeId: addressModel.placeId,
      placeName: addressModel.placeName,
    );
  }

  @override
  String toString() {
    return 'LocationModel(latitude: $latitude, longitude: $longitude, address: $address, placeId: $placeId, placeName: $placeName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is LocationModel &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.address == address &&
      other.placeId == placeId &&
      other.placeName == placeName &&
      _listEquals(other.context, context);
  }

  bool _listEquals(List<dynamic>? a, List<dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      address.hashCode ^
      placeId.hashCode ^
      placeName.hashCode ^
      (context != null ? context!.fold(0, (prev, e) => prev ^ (e?.hashCode ?? 0)) : 0);
}
