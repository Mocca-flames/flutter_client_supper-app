import 'dart:async';
import 'package:flutter/foundation.dart';
// For SnackBar, if needed, but generally avoid UI in providers
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:molo/models/location_model.dart';

class LocationProvider with ChangeNotifier {
  LocationModel _userLocation = LocationModel(
    latitude: 0,
    longitude: 0,
    address: "Fetching location...",
  );
  LocationModel get userLocation => _userLocation;

  bool _isLoadingLocation = true;
  bool get isLoadingLocation => _isLoadingLocation;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  StreamSubscription<Position>? _positionStreamSubscription;

  LocationProvider() {
    _initializeUserLocation();
  }

  Future<void> _initializeUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    _isLoadingLocation = true;
    notifyListeners();

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _userLocation = LocationModel(
        latitude: 0,
        longitude: 0,
        address: "Location services disabled",
      );
      _isLoadingLocation = false;
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _userLocation = LocationModel(
          latitude: 0,
          longitude: 0,
          address: "Location permission denied",
        );
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _userLocation = LocationModel(
        latitude: 0,
        longitude: 0,
        address: "Location permission denied forever",
      );
      _isLoadingLocation = false;
      notifyListeners();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateUserLocationFromCoordinates(
        position.latitude,
        position.longitude,
      );

      _positionStreamSubscription = Geolocator.getPositionStream().listen((
        Position? newPosition,
      ) {
        if (newPosition != null) {
          _updateUserLocationFromCoordinates(
            newPosition.latitude,
            newPosition.longitude,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error getting location: $e");
      }
      _userLocation = LocationModel(
        latitude: 0,
        longitude: 0,
        address: "Could not get location",
      );
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> _updateUserLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    String address = "Fetching address...";
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address =
            "${p.street ?? ''}${p.street != null && p.locality != null ? ', ' : ''}${p.locality ?? ''}"
                .trim();
        if (address.isEmpty) {
          address =
              "${p.subLocality ?? ''}${p.subLocality != null && p.administrativeArea != null ? ', ' : ''}${p.administrativeArea ?? ''}"
                  .trim();
        }
        if (address.isEmpty) {
          address = "Near current location";
        }
      } else {
        address = "Unknown location";
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting address: $e");
      }
      address = "Could not fetch address";
    }

    _userLocation = LocationModel(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    _isRefreshing = true;
    notifyListeners();
    await _initializeUserLocation();
    _isRefreshing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
