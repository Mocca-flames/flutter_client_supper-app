import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import all necessary classes
import 'package:flutter/material.dart'; // For BitmapDescriptor.defaultMarkerWithHue

class DriverLocationModel {
  final String orderId;
  final String driverId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? heading;
  final double? speed;

  DriverLocationModel({
    required this.orderId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.heading,
    this.speed,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      orderId: json['orderId'] as String,
      driverId: json['driverId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'heading': heading,
      'speed': speed,
    };
  }

  bool isRecent() {
    return DateTime.now().difference(timestamp).inSeconds < 30; // Consider recent if within 30 seconds
  }

  double distanceFrom(LatLng location) {
    // Simple distance calculation (Haversine formula could be used for accuracy)
    // For now, a basic Euclidean distance for quick checks
    double dx = latitude - location.latitude;
    double dy = longitude - location.longitude;
    return (dx * dx + dy * dy); // Returns squared distance for comparison
  }

  Marker toGoogleMapsMarker() {
    return Marker(
      markerId: MarkerId(driverId),
      position: LatLng(latitude, longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Example blue marker
      infoWindow: InfoWindow(
        title: 'Driver: $driverId',
        snippet: 'Speed: ${speed?.toStringAsFixed(1) ?? 'N/A'} km/h',
      ),
      rotation: heading ?? 0.0, // Apply heading for rotation
      anchor: const Offset(0.5, 0.5), // Center the marker icon
    );
  }

  @override
  String toString() {
    return 'DriverLocationModel(orderId: $orderId, driverId: $driverId, latitude: $latitude, longitude: $longitude, timestamp: $timestamp, heading: $heading, speed: $speed)';
  }
}
