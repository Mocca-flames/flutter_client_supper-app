import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/driver_location_model.dart';
import 'package:molo/models/route_model.dart';
import 'package:molo/services/google_map_service.dart';
import 'package:molo/services/api_service.dart';
import 'package:molo/utils/geo_utils.dart';
import 'dart:math';

class MapProvider with ChangeNotifier {
  final GoogleMapService _googleMapService;
  final ApiService _apiService;

  GoogleMapController? _googleMapController;
  LocationModel? _currentLocation;
  DriverLocationModel? _driverLocation;
  LocationModel? _pickupLocation;
  LocationModel? _dropoffLocation;
  LocationModel? _mapCenterLocation; // New: Tracks the center of the map view
  RouteModel? _currentRoute;
  String? _dropoffDuration;
  Map<String, Marker> _activeMarkers = {};
  bool _isMapReady = false;
  bool _followUserLocation = false;
  bool _isAnimatingCamera = false;
  bool _isSelectingDropoff = false; // New: Flag to indicate if map center should be used for dropoff

  MapProvider(this._googleMapService, this._apiService);

  GoogleMapController? get googleMapController => _googleMapController;
  LocationModel? get currentLocation => _currentLocation;
  DriverLocationModel? get driverLocation => _driverLocation;
  LocationModel? get pickupLocation => _pickupLocation;
  LocationModel? get dropoffLocation => _dropoffLocation;
  LocationModel? get mapCenterLocation => _mapCenterLocation;
  RouteModel? get currentRoute => _currentRoute;
  ApiService get apiService => _apiService;
  String? get dropoffDuration => _dropoffDuration;
  Map<String, Marker> get activeMarkers => _activeMarkers;
  bool get isMapReady => _isMapReady;
  bool get followUserLocation => _followUserLocation;
  bool get isSelectingDropoff => _isSelectingDropoff;

  void setIsSelectingDropoff(bool value) {
    _isSelectingDropoff = value;
    if (!value) {
      // Clear center marker when stopping selection
      _activeMarkers.remove('map_center');
    }
    notifyListeners();
  }

  Set<Marker> getMarkers() {
    return _activeMarkers.values.toSet();
  }

  Set<Polyline> _activePolylines = {};

  Set<Polyline> get activePolylines => _activePolylines;

  void initializeMap() {
    // Initialize map settings
    // Set default camera position or prepare initial state
    // This can be called early to prepare map state before the widget is rendered
    // For now, we can set any initial flags or preload data that doesn't require the controller
    _isMapReady =
        false; // Ensure map is not marked ready until controller is available
    // Optionally, preload any static data or settings here
  }

  void onMapCreated(GoogleMapController controller) {
    // Dispose of the previous controller if it exists
    _googleMapController?.dispose();
    _googleMapController = controller;
    _isMapReady = true;
    notifyListeners();
  }

  void updateDriverLocation(DriverLocationModel location) {
    _driverLocation = location;
    _updateDriverMarker();
    notifyListeners();
  }

  void _updateDriverMarker() {
    if (_driverLocation != null) {
      final marker = Marker(
        markerId: MarkerId(_driverLocation!.driverId),
        position: LatLng(_driverLocation!.latitude, _driverLocation!.longitude),
        icon: BitmapDescriptor.defaultMarker,
      );
      _activeMarkers[_driverLocation!.driverId] = marker;
    }
  }

  void setOrderLocations(
    LocationModel pickup,
    LocationModel dropoff, {
    String? duration,
  }) {
    _pickupLocation = pickup;
    _dropoffLocation = dropoff;
    _dropoffDuration = duration;
    _addPickupAndDropoffMarkers();
    notifyListeners();
  }

  void _addPickupAndDropoffMarkers() {
    if (_pickupLocation != null && _dropoffLocation != null) {
      final pickupMarker = Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation!.toLatLng(),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      final dropoffMarker = Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffLocation!.toLatLng(),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Dropoff Location',
          snippet: _dropoffDuration != null
              ? 'Duration: $_dropoffDuration'
              : null,
        ),
      );
      _activeMarkers['pickup'] = pickupMarker;
      _activeMarkers['dropoff'] = dropoffMarker;
    }
  }

  void calculateRoute(
    LocationModel start,
    LocationModel end, {
    String mode = 'driving',
  }) async {
    try {
      final data = await _apiService.directions(
        origin: start,
        destination: end,
        mode: mode,
      );
      if (data != null) {
        _currentRoute = RouteModel.fromGoogleDirections(data);
        _drawRoute(_currentRoute!.toPolylineCoordinates());
        // Fit camera to show the route after it's calculated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_googleMapController != null &&
              _pickupLocation != null &&
              _dropoffLocation != null) {
            fitToRoute();
          }
        });
      }
    } catch (e) {
      // Optionally log error or surface via ErrorProvider
    }
    notifyListeners();
  }

  void _drawRoute(List<LatLng> coordinates) {
    final polyline = Polyline(
      polylineId: const PolylineId('current_route'),
      points: coordinates,
      color: Colors.blue,
      width: 5,
    );
    _activePolylines = {polyline};
    notifyListeners();
  }

  void clearRoute() {
    _activePolylines.clear();
    _currentRoute = null;
    notifyListeners();
  }

  void centerOnLocation(LocationModel location, {double zoom = 14.0}) {
    if (_googleMapController != null && !_isAnimatingCamera) {
      try {
        _isAnimatingCamera = true;
        _googleMapController!
            .animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: location.toLatLng(), zoom: zoom),
              ),
            )
            .then((_) {
              _isAnimatingCamera = false;
            })
            .catchError((error) {
              _isAnimatingCamera = false;
              debugPrint('Error centering on location: $error');
            });
      } catch (e) {
        _isAnimatingCamera = false;
        debugPrint('Error centering on location: $e');
      }
    }
  }

  void fitToRoute() {
    if (_pickupLocation != null &&
        _dropoffLocation != null &&
        _googleMapController != null &&
        !_isAnimatingCamera) {
      try {
        _isAnimatingCamera = true;

        // Calculate distance between pickup and dropoff
        final distance = GeoUtils.calculateDistance(
          _pickupLocation!.latitude,
          _pickupLocation!.longitude,
          _dropoffLocation!.latitude,
          _dropoffLocation!.longitude,
        );

        // Determine zoom level based on distance
        double zoomLevel;
        if (distance < 1) {
          zoomLevel = 16.0; // Very close, high zoom
        } else if (distance < 5) {
          zoomLevel = 14.0; // Close, medium-high zoom
        } else if (distance < 20) {
          zoomLevel = 12.0; // Medium distance
        } else if (distance < 100) {
          zoomLevel = 10.0; // Far distance
        } else {
          zoomLevel = 8.0; // Very far distance
        }

        // Calculate center point between pickup and dropoff
        final centerLat =
            (_pickupLocation!.latitude + _dropoffLocation!.latitude) / 2;
        final centerLng =
            (_pickupLocation!.longitude + _dropoffLocation!.longitude) / 2;

        _googleMapController!
            .animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(centerLat, centerLng),
                  zoom: zoomLevel,
                ),
              ),
            )
            .then((_) {
              _isAnimatingCamera = false;
            })
            .catchError((error) {
              _isAnimatingCamera = false;
              debugPrint('Error fitting route to camera: $error');
            });
      } catch (e) {
        _isAnimatingCamera = false;
        // Handle camera animation errors gracefully
        debugPrint('Error fitting route to camera: $e');
      }
    }
  }

  void toggleLocationTracking() {
    _followUserLocation = !_followUserLocation;
    notifyListeners();
  }

  // Implement other methods as needed

  void setInitialPickupLocation(LocationModel location) {
    if (_pickupLocation == null) {
      _pickupLocation = location;
      // Also set map center to pickup location initially
      _mapCenterLocation = location;
      centerOnLocation(location);
      notifyListeners();
    }
  }

  void updateMapCenter(LatLng position) {
    // Update map center coordinates without fetching address immediately
    _mapCenterLocation = LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      address: _mapCenterLocation?.address ?? 'Map Center',
    );

    // Update center marker if selecting dropoff
    if (_isSelectingDropoff) {
      _activeMarkers['map_center'] = Marker(
        markerId: const MarkerId('map_center'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Blue for center
        infoWindow: const InfoWindow(title: 'Dropoff Location'),
      );
    }

    // Do not notify listeners here to avoid excessive rebuilds during panning.
    // The UI should listen to a separate state change (e.g., when selection is confirmed).
  }

  Future<void> setDropoffLocationFromMapCenter() async {
    if (_mapCenterLocation != null) {
      // Fetch address for the map center location
      final addressData = await _apiService.reverseGeocode(
        lat: _mapCenterLocation!.latitude,
        lng: _mapCenterLocation!.longitude,
      );

      if (addressData != null) {
        _dropoffLocation = LocationModel.fromAddressModel(addressData);
      } else {
        // Fallback to coordinates if address fetch fails
        _dropoffLocation = LocationModel(
          latitude: _mapCenterLocation!.latitude,
          longitude: _mapCenterLocation!.longitude,
          address: 'Selected Location',
        );
      }

      // Update markers to show the new dropoff location
      _addPickupAndDropoffMarkers();
      notifyListeners();
    }
  }
}
