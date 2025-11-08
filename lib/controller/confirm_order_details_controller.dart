import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/order_model.dart';
import 'package:molo/models/address_model.dart';
import 'package:molo/providers/order_provider.dart';
import 'package:molo/providers/map_provider.dart';
import 'package:molo/providers/location_provider.dart';
import 'package:molo/providers/auth_provider.dart';
import 'package:molo/routing/app_router.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class ConfirmOrderDetailsController extends ChangeNotifier {
  final _logger = Logger();

  bool _isDisposed = false;

  final OrderProvider orderProvider;
  final MapProvider mapProvider;
  final LocationProvider locationProvider;
  final LocationModel? initialPickupLocation;
  final LocationModel? initialDropoffLocation;
  final String? selectedOrderType;
  final OrderModel? orderToEdit;
  final void Function(String) onError;

  // Cancel token for geocoding requests
  CancelToken? _currentGeocodeCancelToken;

  // Form state
  final TextEditingController dropoffAddressController =
      TextEditingController();
  final TextEditingController patientNotesController = TextEditingController();
  final TextEditingController medicalItemsController = TextEditingController();

  // State variables
  String? _selectedOrderType;
  bool isEmergency = false;
  String? selectedCondition;
  LocationModel? selectedDropoffAddress;
  AddressModel? selectedDropoffAddressModel;

  // Order types
  final List<String> orderTypes = [
    'delivery',
    'pickup',
    'ride_hailing',
    'medical_product',
    'patient_transport',
  ];

  ConfirmOrderDetailsController({
    required this.orderProvider,
    required this.mapProvider,
    required this.locationProvider,
    required this.initialPickupLocation,
    this.initialDropoffLocation,
    this.selectedOrderType,
    this.orderToEdit,
    required this.onError,
  }) {
    _selectedOrderType = selectedOrderType ?? 'delivery';

    // Clear any previous order markers to prevent persistence from other screens
    mapProvider.clearOrderMarkers();

    // Initialize drop-off location if provided
    if (initialDropoffLocation != null) {
      selectedDropoffAddress = initialDropoffLocation;
      // We don't have the full AddressModel here, so we rely on the LocationModel's address/placeName
      dropoffAddressController.text =
          initialDropoffLocation!.placeName ??
          initialDropoffLocation!.address ??
          'Selected Location';
      // Center map on initial drop-off location
      mapProvider.centerOnLocation(initialDropoffLocation!);
    }

    // Initialize for editing if orderToEdit is provided
    if (orderToEdit != null) {
      _initializeForEditing();
    }

    // Auto-select pickup and dropoff for patient_transport
    if (_selectedOrderType == 'patient_transport') {
      _autoSelectAddressesForPatientTransport();
    }
  }

  void _initializeForEditing() {
    // Initialize form fields from existing order
    dropoffAddressController.text = orderToEdit!.dropoffAddress;
    patientNotesController.text = orderToEdit!.specialInstructions ?? '';
    _selectedOrderType = orderToEdit!.orderType.toString().split('.').last;
    // Add other initialization logic as needed
  }

  void _autoSelectAddressesForPatientTransport() {
    // For patient transport, auto-select user's current location as pickup
    // and set dropoff to Molodoc Hospital
    // Since this is a different service, we need to set both pickup and dropoff

    // Set pickup to user's current location
    if (locationProvider.userLocation != null) {
      // For patient transport, pickup is the user's location
      // We can use initialPickupLocation or set it to user location
      // But since initialPickupLocation might be null, we'll set it here
      // Note: This assumes the controller has access to set pickup location
      // For now, we'll focus on dropoff as per the task

      // Set dropoff to Molodoc Hospital
      const double molodocHospitalLat = -25.379015319967397;
      const double molodocHospitalLng = 28.2594415380186;

      selectedDropoffAddress = LocationModel(
        latitude: molodocHospitalLat,
        longitude: molodocHospitalLng,
        address: 'Molodoc Hospital',
        placeName: 'Molodoc Hospital',
      );

      dropoffAddressController.text = 'Molodoc Hospital';

      // Center map on the hospital location
      mapProvider.centerOnLocation(selectedDropoffAddress!);

      notifyListeners();
    }
  }

  String? get selectedOrderTypeGetter => _selectedOrderType;

  void setSelectedOrderType(String? type) {
    _selectedOrderType = type;
    // Auto-select addresses for patient_transport when type changes
    if (_selectedOrderType == 'patient_transport') {
      _autoSelectAddressesForPatientTransport();
    }
    notifyListeners();
  }

  void startDropoffSelection() {
    mapProvider.setIsSelectingDropoff(true);
    // Center map on current dropoff location or a default position
    if (selectedDropoffAddress != null) {
      mapProvider.centerOnLocation(selectedDropoffAddress!);
    } else if (initialPickupLocation != null) {
      // Start near pickup location
      mapProvider.centerOnLocation(initialPickupLocation!);
    }
  }

  void stopDropoffSelection() {
    mapProvider.setIsSelectingDropoff(false);
  }

  void updateMapCenterOnMove(LatLng position) {
    // Enable dropoff selection mode if not already enabled
    if (!mapProvider.isSelectingDropoff) {
      startDropoffSelection();
    }

    // Update map center in MapProvider
    _logger.i('Updating map center to: $position');
    mapProvider.updateMapCenter(position);
  }

  void triggerReverseGeocodeForMapCenter(LatLng position) {
    // Cancel any ongoing geocoding request
    _currentGeocodeCancelToken?.cancel('New geocoding request initiated');

    // Create a new cancel token for this request
    _currentGeocodeCancelToken = CancelToken();

    // Reverse geocode and update address field
    _reverseGeocodeMapCenter(position, _currentGeocodeCancelToken);
  }

  Future<void> _reverseGeocodeMapCenter(
    LatLng position,
    CancelToken? cancelToken,
  ) async {
    try {
      final addressData = await mapProvider.apiService.reverseGeocode(
        lat: position.latitude,
        lng: position.longitude,
        cancelToken: cancelToken,
      );

      if (_isDisposed) return;

      if (addressData != null) {
        // Store the full AddressModel
        selectedDropoffAddressModel = addressData;
        // Update the address text field with the reverse geocoded address
        dropoffAddressController.text =
            addressData.placeName ??
            addressData.street ??
            addressData.fullAddress ??
            'Selected Location';
        // Also update the selectedDropoffAddress (LocationModel for compatibility)
        selectedDropoffAddress = LocationModel.fromAddressModel(addressData);
        notifyListeners();
      }
    } catch (error) {
      if (_isDisposed) return;
      
      _logger.e('Error reverse geocoding map center: $error');
      // On failure, clear structured address model and set a generic error message
      selectedDropoffAddressModel = null;
      dropoffAddressController.text =
          'Location selected, but address details failed to load.';
      selectedDropoffAddress = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: dropoffAddressController.text,
      );
      notifyListeners();
    }
  }

  Future<void> confirmDestinationAndNavigate({
    required BuildContext context,
    required bool isProcessingOrder,
    required void Function(bool) setProcessingOrder,
  }) async {
    if (isProcessingOrder) return;

    try {
      setProcessingOrder(true);

      // Validate required fields
      if (_selectedOrderType == null) {
        onError('Please select an order type');
        return;
      }

      if (_selectedOrderType != 'patient_transport' &&
          (selectedDropoffAddress == null ||
              dropoffAddressController.text.isEmpty)) {
        onError('Please select a dropoff location');
        return;
      }

      // Delete all previous orders before proceeding (run in background)
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      // Don't await to avoid context issues during navigation
      orderProvider.deleteAllOrders();

      // Prepare order data
      final orderData = <String, dynamic>{
        'order_type': _selectedOrderType,
        'pickup_latitude': initialPickupLocation?.latitude.toString() ?? '',
        'pickup_longitude': initialPickupLocation?.longitude.toString() ?? '',
        'dropoff_latitude': selectedDropoffAddress?.latitude.toString() ?? '',
        'dropoff_longitude': selectedDropoffAddress?.longitude.toString() ?? '',
        'dropoff_address': dropoffAddressController.text,
        'special_instructions': patientNotesController.text,
        'is_emergency': isEmergency,
        'patient_condition': selectedCondition,
        'medical_items': medicalItemsController.text,
      };

      // Get current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid ?? '';

      // Navigate to payment choice screen
      await AppRouter.navigateToOrderPaymentChoice(
        context,
        userId: userId,
        pickupLocation:
            initialPickupLocation ?? LocationModel(latitude: 0, longitude: 0),
        dropoffLocation:
            selectedDropoffAddress ??
            LocationModel(latitude: -33.9249, longitude: 18.4241),
        orderData: orderData,
      );
    } catch (e) {
      _logger.e('Error confirming destination: $e');
      onError('Failed to process order: $e');
    } finally {
      setProcessingOrder(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    dropoffAddressController.dispose();
    patientNotesController.dispose();
    medicalItemsController.dispose();
    super.dispose();
  }
}
