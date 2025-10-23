import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

class RouteModel {
  final String routeId;
  final List<LatLng> coordinates;
  final double distance; // in meters
  final double duration; // in seconds
  final List<String>? instructions;

  RouteModel({
    required this.routeId,
    required this.coordinates,
    required this.distance,
    required this.duration,
    this.instructions,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      routeId: json['routeId'],
      coordinates: (json['coordinates'] as List)
          .map((coord) => LatLng(coord['latitude'], coord['longitude']))
          .toList(),
      distance: json['distance'],
      duration: json['duration'],
      instructions: json['instructions'] != null
          ? List<String>.from(json['instructions'])
          : null,
    );
  }

  // Mapbox Directions factory removed per ADR-005 (use fromGoogleDirections)

  factory RouteModel.fromGoogleDirections(Map<String, dynamic> response) {
    final routes = response['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No routes found in Google Directions response');
    }

    final route = routes.first as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>?;
    final legs = (route['legs'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Decode polyline
    final String? polyline = overview?['points'] as String?;
    final List<LatLng> coords =
        polyline != null ? _decodePolyline(polyline) : <LatLng>[];

    // Aggregate distance/duration from legs (meters / seconds)
    double totalDistance = 0;
    double totalDuration = 0;
    final List<String> instrs = [];

    for (final leg in legs) {
      final dist = leg['distance']?['value'];
      final dur = leg['duration']?['value'];
      if (dist is num) totalDistance += dist.toDouble();
      if (dur is num) totalDuration += dur.toDouble();

      final steps = (leg['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final step in steps) {
        final instruction = step['html_instructions'];
        if (instruction is String && instruction.isNotEmpty) {
          // Strip basic HTML tags from html_instructions
          instrs.add(instruction.replaceAll(RegExp(r'<[^>]*>'), ''));
        }
      }
    }

    return RouteModel(
      routeId: DateTime.now().millisecondsSinceEpoch.toString(),
      coordinates: coords,
      distance: totalDistance,
      duration: totalDuration,
      instructions: instrs.isNotEmpty ? instrs : null,
    );
  }

  // Google Encoded Polyline Algorithm Format decoder
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }
  List<LatLng> toPolylineCoordinates() {
    return coordinates;
  }

  DateTime getEstimatedArrival(DateTime startTime) {
    return startTime.add(Duration(seconds: duration.round()));
  }

  @override
  String toString() {
    return 'RouteModel(routeId: $routeId, distance: ${distance.toStringAsFixed(2)}m, duration: ${duration.toStringAsFixed(0)}s, coordinates: ${coordinates.length} points)';
  }
}
