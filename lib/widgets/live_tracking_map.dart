import 'package:flutter/material.dart';
import '../models/driver_location_model.dart';
import '../models/location_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingMap extends StatefulWidget {
  final DriverLocationModel? driverLocation;
  final LocationModel? destinationLocation;
  final Function(GoogleMapController)?
  onMapCreated; // Changed to GoogleMapController
  final CameraPosition? initialCameraPosition;

  const LiveTrackingMap({
    super.key,
    this.driverLocation,
    this.destinationLocation,
    this.onMapCreated,
    this.initialCameraPosition,
  });

  @override
  _LiveTrackingMapState createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  GoogleMapController? _mapController; // Changed to GoogleMapController

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driverLocation != oldWidget.driverLocation &&
        _mapController != null &&
        widget.driverLocation != null) {
      // Animate camera to new driver location
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              widget.driverLocation!.latitude,
              widget.driverLocation!.longitude,
            ),
            zoom: 30.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Render GoogleMap
    // Default camera position if none provided (e.g., centered on a default city or driver's last known location)
    final CameraPosition defaultInitialCameraPosition = CameraPosition(
      target: widget.driverLocation != null
          ? LatLng(
              widget.driverLocation!.latitude,
              widget.driverLocation!.longitude,
            )
          : const LatLng(-25.7479, 28.2293), // Pretoria as a sensible default
      zoom: 35.0,
    );

    return GoogleMap(
      onMapCreated: (controller) {
        _mapController =
            controller; // No cast needed, controller is already GoogleMapController
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }
      },
      initialCameraPosition: defaultInitialCameraPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: {},
      polylines: {},
    );
  }
}
