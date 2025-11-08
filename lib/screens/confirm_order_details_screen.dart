import 'package:flutter/material.dart';
import 'package:molo/controller/confirm_order_details_controller.dart';
import 'package:molo/models/location_model.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/map_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/confirm_order_map_widget.dart';
import '../widgets/confirm_order_bottom_section.dart';
import '../utils/string_extensions.dart';
import '../models/order_model.dart';

class ConfirmOrderDetailsScreen extends StatefulWidget {
  static const String routeName = '/confirm-order-details';

  final LocationModel? initialPickupLocation;
  final LocationModel? initialDropoffLocation;
  final String? selectedOrderType;
  final OrderModel? orderToEdit;

  const ConfirmOrderDetailsScreen({
    super.key,
    this.initialPickupLocation,
    this.initialDropoffLocation,
    this.selectedOrderType,
    this.orderToEdit,
  });

  @override
  ConfirmOrderDetailsScreenState createState() =>
      ConfirmOrderDetailsScreenState();
}

class ConfirmOrderDetailsScreenState extends State<ConfirmOrderDetailsScreen> {
  late ConfirmOrderDetailsController _controller;
  final _formKey = GlobalKey<FormState>();
  late OrderProvider _orderProvider;
  late MapProvider _mapProvider;
  bool _controllerInitialized = false;
  bool _markersCleared = false;

  // Track if we're currently processing an order to prevent double submissions
  bool _isProcessingOrder = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllerInitialized) {
      _orderProvider = Provider.of<OrderProvider>(context, listen: false);
      _mapProvider = Provider.of<MapProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);

      // Clear markers before initializing controller
      if (!_markersCleared) {
        _mapProvider.clearOrderMarkers();
        _markersCleared = true;
      }

      _controller = ConfirmOrderDetailsController(
        orderProvider: _orderProvider,
        mapProvider: _mapProvider,
        locationProvider: locationProvider,
        initialPickupLocation: widget.initialPickupLocation,
        initialDropoffLocation: widget.initialDropoffLocation,
        selectedOrderType: widget.selectedOrderType,
        orderToEdit: widget.orderToEdit,
        onError: _showError,
      );
      _controllerInitialized = true;
    }
  }

  // Safe error callback
  void _showError(String error) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // orderProvider is now accessed in didChangeDependencies, but we keep this line
    // if it's used for listening to state changes (e.g., orderProvider.isLoading)
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      body: orderProvider.isLoading || _isProcessingOrder
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  if (_isProcessingOrder) ...[
                    const SizedBox(height: 16),
                    const Text('Creating your order...'),
                  ],
                ],
              ),
            )
          : ChangeNotifierProvider.value(
              value: _controller,
              child: Consumer<ConfirmOrderDetailsController>(
                builder: (context, controller, child) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Order Type Selection (if not pre-selected)
                        if (widget.selectedOrderType == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Order Type',
                                border: OutlineInputBorder(),
                              ),
                              value: controller.selectedOrderTypeGetter,
                              items: controller.orderTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(
                                    type.replaceAll('_', ' ').toTitleCase(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                controller.setSelectedOrderType(newValue);
                              },
                              validator: (value) => value == null
                                  ? 'Please select an order type'
                                  : null,
                            ),
                          ),

                        // Map Section
                        const ConfirmOrderMapWidget(),

                        // Bottom Section
                        ConfirmOrderBottomSection(
                          isProcessingOrder: _isProcessingOrder,
                          onCreateOrder: () async {
                            await controller.confirmDestinationAndNavigate(
                              context: context,
                              isProcessingOrder: _isProcessingOrder,
                              setProcessingOrder: (bool value) {
                                setState(() {
                                  _isProcessingOrder = value;
                                });
                              },
                            );
                            // Navigation is handled by the controller
                          },
                          orderToEdit: widget.orderToEdit,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
  