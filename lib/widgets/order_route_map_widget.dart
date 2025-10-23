import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';

class OrderRouteMapWidget extends StatefulWidget {
  const OrderRouteMapWidget({super.key});

  @override
  State<OrderRouteMapWidget> createState() => _OrderRouteMapWidgetState();
}

class _OrderRouteMapWidgetState extends State<OrderRouteMapWidget> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Set the controller in the provider and fit to route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.onMapCreated(controller);
      mapProvider.fitToRoute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        return SizedBox.expand(
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0), // Will be updated when locations are set
              zoom: 0.2,
            ),
            markers: mapProvider.getMarkers(),
            polylines: mapProvider.activePolylines,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
        );
      },
    );
  }
}
