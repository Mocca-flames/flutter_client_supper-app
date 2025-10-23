import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:molo/controller/confirm_order_details_controller.dart';
import 'package:logger/logger.dart';
import 'package:molo/models/order_model.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/address_model.dart';
import 'package:molo/providers/location_provider.dart';
import 'package:molo/providers/map_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/create_order/create_order_sheet.dart';

class ConfirmOrderBottomSection extends StatelessWidget {
  final bool isProcessingOrder;
  final VoidCallback onCreateOrder;
  final OrderModel? orderToEdit;

  const ConfirmOrderBottomSection({
    super.key,
    required this.isProcessingOrder,
    required this.onCreateOrder,
    this.orderToEdit,
  });

  // Helper function to check if a string looks like coordinates
  bool _looksLikeCoordinates(String? text) {
    if (text == null) return false;
    // Check for patterns like "Lat: 123.456, Lng: 789.012" or "-25.4058 , 28.2699"
    final coordRegex = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
    return coordRegex.hasMatch(text) ||
        text.contains('Lat:') ||
        text.contains('Lng:');
  }

  void _showAddressSearchBottomSheet(BuildContext context) {
    final controller = Provider.of<ConfirmOrderDetailsController>(
      context,
      listen: false,
    );
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // For ride_hailing, default to user's current location
    LocationModel? initialLocation;
    if (controller.selectedOrderTypeGetter == 'ride_hailing') {
      initialLocation = locationProvider.userLocation;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (innerContext, scrollController) => AddressSearchBottomSheet(
          scrollController: scrollController,
          initialLocation: initialLocation,
          onAddressSelected: (AddressModel address) {
            if (context.mounted) {
              // Store the full AddressModel
              controller.selectedDropoffAddressModel = address;

              // Update the text controller with the place name or street for display
              // Avoid using coordinate strings as display text
              controller.dropoffAddressController.text =
                  address.placeName ??
                  address.street ??
                  (_looksLikeCoordinates(address.fullAddress)
                      ? null
                      : address.fullAddress) ??
                  '';

              // Update LocationModel for compatibility with existing logic
              controller.selectedDropoffAddress = LocationModel(
                latitude: address.latitude ?? 0,
                longitude: address.longitude ?? 0,
              );

              if (address.latitude != null && address.longitude != null) {
                // Move the map to the selected location
                final mapProvider = Provider.of<MapProvider>(context, listen: false);
                mapProvider.centerOnLocation(LocationModel(
                  latitude: address.latitude!,
                  longitude: address.longitude!,
                  address: address.fullAddress ?? address.placeName ?? address.street ?? '',
                ));

                // Also update the controller's map center for consistency
                controller.updateMapCenterOnMove(
                  LatLng(address.latitude!, address.longitude!),
                );
              }
              Navigator.pop(sheetContext);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _logger = Logger();
    return Consumer<ConfirmOrderDetailsController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Dropoff Address
              if (controller.selectedOrderTypeGetter !=
                  'patient_transport') ...[
                GestureDetector(
                  onTap: () => _showAddressSearchBottomSheet(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dropoff Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                controller
                                        .selectedDropoffAddressModel
                                        ?.fullAddress ??
                                    controller
                                        .selectedDropoffAddressModel
                                        ?.placeName ??
                                    controller
                                        .selectedDropoffAddressModel
                                        ?.street ??
                                    (controller
                                            .dropoffAddressController
                                            .text
                                            .isEmpty
                                        ? 'Tap to select location'
                                        : controller
                                              .dropoffAddressController
                                              .text),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      controller.selectedDropoffAddressModel ==
                                              null &&
                                          controller
                                              .dropoffAddressController
                                              .text
                                              .isEmpty
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Fixed dropoff for patient transport
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              controller
                                      .selectedDropoffAddressModel
                                      ?.fullAddress ??
                                  controller
                                      .selectedDropoffAddressModel
                                      ?.placeName ??
                                  controller
                                      .selectedDropoffAddressModel
                                      ?.street ??
                                  controller.dropoffAddressController.text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),

              // Conditional Fields
              if (controller.selectedOrderTypeGetter ==
                  'patient_transport') ...[
                // Emergency Toggle
                SwitchListTile(
                  title: const Text('Is this an emergency?'),
                  value: controller.isEmergency,
                  onChanged: (value) {
                    controller.isEmergency = value;
                    controller.notifyListeners();
                  },
                ),
                const SizedBox(height: 16),

                // Condition Selector
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Patient Condition',
                    border: OutlineInputBorder(),
                  ),
                  value: controller.selectedCondition,
                  items: const [
                    DropdownMenuItem(
                      value: 'cardiac',
                      child: Text('Cardiac Emergency'),
                    ),
                    DropdownMenuItem(
                      value: 'respiratory',
                      child: Text('Respiratory Distress'),
                    ),
                    DropdownMenuItem(
                      value: 'trauma',
                      child: Text('Trauma/Injury'),
                    ),
                    DropdownMenuItem(
                      value: 'neurological',
                      child: Text('Neurological Issue'),
                    ),
                    DropdownMenuItem(
                      value: 'infection',
                      child: Text('Severe Infection'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other Medical Condition'),
                    ),
                  ],
                  onChanged: (value) {
                    controller.selectedCondition = value;
                    controller.notifyListeners();
                  },
                  validator: (value) =>
                      value == null ? 'Please select a condition' : null,
                ),
                const SizedBox(height: 16),

                // Patient Notes
                TextFormField(
                  controller: controller.patientNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],
              if (controller.selectedOrderTypeGetter == 'medical_product') ...[
                TextFormField(
                  controller: controller.medicalItemsController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Items (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],

              // Confirm Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessingOrder
                      ? null
                      : () {
                          _logger.i(
                            'Confirm Destination button pressed. Calling onCreateOrder.',
                          );
                          onCreateOrder();
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isProcessingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          orderToEdit != null
                              ? 'Confirm Update'
                              : 'Confirm Destination',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
