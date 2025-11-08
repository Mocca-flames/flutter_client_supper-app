import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:molo/controller/confirm_order_details_controller.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/providers/map_provider.dart';
import 'package:molo/providers/location_provider.dart';
import 'package:provider/provider.dart';

class ConfirmOrderMapWidget extends StatelessWidget {
  const ConfirmOrderMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConfirmOrderDetailsController, MapProvider>(
      builder: (context, controller, mapProvider, child) {
        return Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    controller.selectedOrderTypeGetter == 'patient_transport'
                        ? -25.379015319967397 // Molodoc Hospital latitude
                        : (controller.initialDropoffLocation?.latitude ??
                              controller.initialPickupLocation?.latitude ??
                              -33.9249),
                    controller.selectedOrderTypeGetter == 'patient_transport'
                        ? 28.2594415380186 // Molodoc Hospital longitude
                        : (controller.initialDropoffLocation?.longitude ??
                              controller.initialPickupLocation?.longitude ??
                              18.4241),
                  ),
                  zoom:
                      controller.selectedOrderTypeGetter == 'patient_transport'
                      ? 15
                      : 3,
                ),
                onMapCreated: (GoogleMapController mapController) {
                  mapProvider.onMapCreated(mapController);

                  if (controller.selectedOrderTypeGetter ==
                      'patient_transport') {
                    // For patient transport, center on Molodoc Hospital and disable further movement
                    final hospitalLocation = LocationModel(
                      latitude: -25.379015319967397,
                      longitude: 28.2594415380186,
                      address: 'Molodoc Hospital',
                      placeName: 'Molodoc Hospital',
                    );
                    mapProvider.centerOnLocation(hospitalLocation);
                    // Set pickup location for markers if available
                    final locationProvider = Provider.of<LocationProvider>(
                      context,
                      listen: false,
                    );
                    final pickupLocation =
                        controller.initialPickupLocation ??
                        locationProvider.userLocation;
                    mapProvider.setInitialPickupLocation(pickupLocation);
                  } else {
                    // Set initial location: prioritize drop-off for ride_hailing, otherwise pickup
                    final locationProvider = Provider.of<LocationProvider>(
                      context,
                      listen: false,
                    );
                    final pickupLocation =
                        controller.initialPickupLocation ??
                        locationProvider.userLocation;

                    if (controller.initialDropoffLocation != null) {
                      // For ride_hailing or when drop-off is pre-selected, center on drop-off
                      mapProvider.centerOnLocation(
                        controller.initialDropoffLocation!,
                      );
                      // Still set pickup location for markers
                      mapProvider.setInitialPickupLocation(pickupLocation);
                    } else {
                      mapProvider.setInitialPickupLocation(pickupLocation);
                    }
                  }
                },
                markers: mapProvider.getMarkers(),
                scrollGesturesEnabled:
                    controller.selectedOrderTypeGetter != 'patient_transport',
                zoomGesturesEnabled:
                    controller.selectedOrderTypeGetter != 'patient_transport',
                onCameraMove: (CameraPosition position) {
                  // Update map center as user pans
                  if (controller.selectedOrderTypeGetter !=
                      'patient_transport') {
                    controller.updateMapCenterOnMove(position.target);
                  }
                },
                onCameraIdle: () {
                  // Trigger reverse geocoding when camera stops moving
                  if (controller.selectedOrderTypeGetter !=
                      'patient_transport') {
                    final mapProvider = Provider.of<MapProvider>(
                      context,
                      listen: false,
                    );
                    final mapCenter = mapProvider.mapCenterLocation;
                    if (mapCenter != null) {
                      controller.triggerReverseGeocodeForMapCenter(
                        LatLng(mapCenter.latitude, mapCenter.longitude),
                      );
                    }
                  }
                },
              ),
              // Fixed center marker overlay
              Center(
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: Colors.red,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
