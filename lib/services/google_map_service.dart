import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../models/location_model.dart';

class GoogleMapService {
  GoogleMapController? _googleMapController;
  bool _isInitialized = false;

  GoogleMapService();

  // Initializes Google Maps SDK (if needed, often handled by the widget itself)
  void initializeGoogleMaps() {
    // This method might be more for conceptual initialization or API key setup
    // The actual map initialization happens when GoogleMap widget is created
    _isInitialized = true;
    debugPrint('Google Maps Service Initialized');
  }

  // Creates and returns GoogleMap widget
  GoogleMap createGoogleMap({
    required MapCreatedCallback onMapCreated,
    CameraPosition? initialCameraPosition,
    Set<Marker> markers = const {},
    Set<Polyline> polylines = const {},
    Set<Circle> circles = const {},
    Set<Polygon> polygons = const {},
    bool myLocationEnabled = false,
    bool myLocationButtonEnabled = false,
    bool zoomControlsEnabled = true,
    bool scrollGesturesEnabled = true,
    bool zoomGesturesEnabled = true,
    bool tiltGesturesEnabled = true,
    bool rotateGesturesEnabled = true,
    MapType mapType = MapType.normal,
    VoidCallback? onCameraIdle,
    void Function(CameraPosition)? onCameraMove,
    void Function()? onCameraMoveStarted,
    ArgumentCallback<LatLng>? onTap,
    ArgumentCallback<LatLng>? onLongPress,
  }) {
    return GoogleMap(
      onMapCreated: (controller) {
        _googleMapController = controller;
        onMapCreated(controller);
      },
      initialCameraPosition: initialCameraPosition ??
          const CameraPosition(
            target: LatLng(0, 0), // Default to center of the world
            zoom: 2,
          ),
      markers: markers,
      polylines: polylines,
      circles: circles,
      polygons: polygons,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      scrollGesturesEnabled: scrollGesturesEnabled,
      zoomGesturesEnabled: zoomGesturesEnabled,
      tiltGesturesEnabled: tiltGesturesEnabled,
      rotateGesturesEnabled: rotateGesturesEnabled,
      mapType: mapType,
      onCameraIdle: onCameraIdle,
      onCameraMove: onCameraMove,
      onCameraMoveStarted: onCameraMoveStarted,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  // Gets device location
  Future<LocationModel?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied, we cannot request permissions.');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: null, // Address will be reverse geocoded later if needed
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Adds custom markers
  Future<Marker> addMarker(LocationModel location, String markerId, {BitmapDescriptor? icon, String? title, String? snippet}) async {
    return Marker(
      markerId: MarkerId(markerId),
      position: LatLng(location.latitude, location.longitude),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
    );
  }

  // Updates map camera position
  Future<void> updateCamera(LocationModel location, {double zoom = 15.0, double? bearing, double? tilt}) async {
    if (_googleMapController != null) {
      final CameraPosition newPosition = CameraPosition(
        target: LatLng(location.latitude, location.longitude),
        zoom: zoom,
        bearing: bearing ?? 0.0,
        tilt: tilt ?? 0.0,
      );
      await _googleMapController!.animateCamera(
        CameraUpdate.newCameraPosition(newPosition),
      );
    }
  }

  // Fits map to show all locations
  Future<void> fitBounds(List<LocationModel> locations) async {
    if (_googleMapController != null && locations.isNotEmpty) {
      double minLat = locations.first.latitude;
      double maxLat = locations.first.latitude;
      double minLng = locations.first.longitude;
      double maxLng = locations.first.longitude;

      for (var loc in locations) {
        if (loc.latitude < minLat) minLat = loc.latitude;
        if (loc.latitude > maxLat) maxLat = loc.latitude;
        if (loc.longitude < minLng) minLng = loc.longitude;
        if (loc.longitude > maxLng) maxLng = loc.longitude;
      }

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await _googleMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0), // Padding of 50 pixels
      );
    }
  }

  // Draws route on map
  Polyline addPolyline(List<LatLng> coordinates, String polylineId, {Color color = Colors.blue, double width = 5}) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: coordinates,
      color: color,
      width: width.toInt(),
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  // Disposes the controller when no longer needed
  void dispose() {
    _googleMapController?.dispose();
    _googleMapController = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
  GoogleMapController? get controller => _googleMapController;
}
