import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:molo/providers/map_provider.dart';
import 'package:molo/providers/order_provider.dart';
import 'package:molo/models/order_model.dart';
import 'package:molo/models/location_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:molo/providers/auth_provider.dart';
import 'package:molo/providers/websocket_provider.dart';
import 'package:molo/services/api_service.dart';
// Import AuthProvider

class OrderTrackingScreen extends StatefulWidget {
  static const String routeName = '/order-tracking';
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // UI State
  bool _isFollowingDriver = true;
  String _currentPhase = 'pickup'; // 'pickup' or 'dropoff'

  // Driver location polling
  Timer? _driverLocationTimer;

  // Custom map styles (can be applied via GoogleMapService if it supports it)
  static const String _mapStyle = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels.text",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#f5f1e7"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    debugPrint('OrderTrackingScreen: initState() called');
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreenData();
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _driverLocationTimer?.cancel();
    // No need to dispose mapController here, MapProvider handles it
    super.dispose();
  }

  Future<void> _initializeScreenData() async {
    debugPrint('OrderTrackingScreen: _initializeScreenData() called');
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final webSocketProvider = Provider.of<WebSocketProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Fetch the actual order details
    OrderModel? order = await orderProvider.getOrderById(widget.orderId);

    if (order != null) {
      orderProvider.currentOrder =
          order; // Set the fetched order in the provider

      // Create LocationModel objects from the order data for calculations
      final pickupLocation = LocationModel(
        latitude: double.tryParse(order.pickupLatitude ?? '') ?? 0.0,
        longitude: double.tryParse(order.pickupLongitude ?? '') ?? 0.0,
        address: order.pickupAddress,
      );

      final dropoffLocation = LocationModel(
        latitude: double.tryParse(order.dropoffLatitude ?? '') ?? 0.0,
        longitude: double.tryParse(order.dropoffLongitude ?? '') ?? 0.0,
        address: order.dropoffAddress,
      );

      // Set locations in map provider
      mapProvider.setOrderLocations(pickupLocation, dropoffLocation);

      _determineCurrentPhase(order);

      // Calculate route using lat/lng coordinates (more accurate)
      mapProvider.calculateRoute(
        pickupLocation,
        dropoffLocation,
        mode: 'driving', // Use 'driving', 'walking', or 'cycling' as needed
      );

      // Initialize WebSocket connection and subscribe to updates
      final firebaseToken = await authProvider.refreshToken();
      if (firebaseToken != null) {
        try {
          await webSocketProvider.initializeConnection(order.id);
          webSocketProvider.subscribeToDriverLocation(order.id);
          // Note: subscribeToOrderUpdates method doesn't exist in WebSocketProvider
          // The WebSocketProvider already handles order updates through its constructor
          // No additional subscription is needed
        } catch (e) {
          debugPrint('WebSocket connection failed, falling back to polling: $e');
          _showSnackBar('Real-time connection failed, using periodic updates');
          // Start polling for driver location as fallback
          _startDriverLocationPolling(order.id);
        }
      } else {
        _showSnackBar(
          'Authentication token not available for real-time tracking.',
        );
        // Start polling for driver location as fallback
        _startDriverLocationPolling(order.id);
      }
    } else {
      _showSnackBar('Could not load order details for tracking.');
      if (mapProvider.currentRoute == null) {
        _showSnackBar('Failed to calculate route.');
      }
    }
    debugPrint('OrderTrackingScreen: _initializeScreenData() completed');
  }

  void _determineCurrentPhase(OrderModel order) {
    setState(() {
      switch (order.status) {
        case OrderStatus.pending:
        case OrderStatus.accepted:
          _currentPhase = 'pickup';
          break;
        case OrderStatus.inProgress:
          _currentPhase = 'dropoff';
          break;
        case OrderStatus.completed:
        case OrderStatus.cancelled:
          _currentPhase =
              'pickup'; // Default or handle completed/cancelled differently
      }
    });
  }


  String _getPhaseDescription(MapProvider mapProvider) {
    if (mapProvider.currentRoute == null) {
      return 'Calculating route...';
    }
    return _currentPhase == 'pickup'
        ? 'Driver is heading to pickup location'
        : 'Driver is heading to destination';
  }

  String _getEstimatedArrivalTime(MapProvider mapProvider) {
    if (mapProvider.currentRoute == null) {
      return 'N/A';
    }
    final eta = mapProvider.currentRoute!.getEstimatedArrival(DateTime.now());
    return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MapProvider, OrderProvider>(
      builder: (context, mapProvider, orderProvider, child) {
        final currentOrder = orderProvider.currentOrder;

        return Scaffold(
          body: Stack(
            children: [
              GoogleMap(
                onMapCreated:
                    mapProvider.onMapCreated, // Use MapProvider's callback
                initialCameraPosition: CameraPosition(
                  target: mapProvider.pickupLocation != null
                      ? mapProvider.pickupLocation!.toLatLng()
                      : const LatLng(-25.7479, 28.2293), // Default to Pretoria
                  zoom: 14,
                ),
                markers: mapProvider.activeMarkers.values
                    .toSet(), // Convert Map values to Set
                polylines: mapProvider
                    .activePolylines, // Use polylines from MapProvider
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Custom App Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Track Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentOrder?.getStatusText() ?? 'Loading...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Map Control Buttons
              Positioned(
                right: 16,
                bottom: 200,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'follow_driver',
                      onPressed: () {
                        setState(() {
                          _isFollowingDriver = !_isFollowingDriver;
                        });
                        mapProvider
                            .toggleLocationTracking(); // Toggle tracking in MapProvider
                        if (_isFollowingDriver &&
                            mapProvider.driverLocation != null) {
                          mapProvider.centerOnLocation(
                            LocationModel.fromLatLng(
                              mapProvider.driverLocation!
                                  .toGoogleMapsMarker()
                                  .position,
                            ),
                            zoom: 16.0,
                          );
                        }
                      },
                      backgroundColor: _isFollowingDriver
                          ? Colors.blue
                          : Colors.white,
                      child: Icon(
                        Icons.my_location,
                        color: _isFollowingDriver
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'fit_markers',
                      onPressed: () => mapProvider
                          .fitToRoute(), // Use MapProvider's fitToRoute
                      backgroundColor: Colors.white,
                      child: Icon(Icons.fit_screen, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Bottom Info Panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (mapProvider.driverLocation != null) ...[
                                Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getPhaseDescription(
                                              mapProvider,
                                            ), // Pass mapProvider
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Driver ${mapProvider.driverLocation!.driverId.substring(0, 8)}...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (mapProvider.currentRoute != null) ...[
                                      // Check currentRoute instead of estimatedArrivalTime
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          _getEstimatedArrivalTime(
                                            mapProvider,
                                          ), // Use the helper method
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ] else if (currentOrder?.status ==
                                      OrderStatus.completed ||
                                  currentOrder?.status ==
                                      OrderStatus.cancelled) ...[
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Order is no longer being tracked.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ] else ...[
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Waiting for driver location...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLocationCard(
                                      icon: Icons.radio_button_checked,
                                      iconColor: Colors.green,
                                      title: 'Pickup',
                                      address:
                                          mapProvider.pickupLocation?.address ??
                                          'Loading...',
                                      isActive: _currentPhase == 'pickup',
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildLocationCard(
                                      icon: Icons.location_on,
                                      iconColor: Colors.red,
                                      title: 'Dropoff',
                                      address:
                                          mapProvider
                                              .dropoffLocation
                                              ?.address ??
                                          'Loading...',
                                      isActive: _currentPhase == 'dropoff',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _callDriver(
                                        context,
                                        mapProvider.driverLocation?.driverId,
                                      ),
                                      icon: const Icon(Icons.phone),
                                      label: const Text('Call Driver'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.info_outline),
                                      label: const Text('Order Details'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildLocationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.blue[200]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _startDriverLocationPolling(String orderId) {
    debugPrint('OrderTrackingScreen: Starting driver location polling for order $orderId');
    _driverLocationTimer?.cancel();
    _driverLocationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final mapProvider = Provider.of<MapProvider>(context, listen: false);

        final driverLocation = await apiService.getCurrentDriverLocationForOrder(orderId);
        if (driverLocation != null) {
          debugPrint('OrderTrackingScreen: Polled driver location: ${driverLocation.latitude}, ${driverLocation.longitude}');
          mapProvider.updateDriverLocation(driverLocation);
        }
      } catch (e) {
        debugPrint('OrderTrackingScreen: Error polling driver location: $e');
        // Continue polling even on error
      }
    });
  }

  Future<void> _callDriver(BuildContext context, String? driverId) async {
    if (driverId == null) {
      _showSnackBar('Driver information not available to call.');
      return;
    }

    const String phoneNumber = 'tel:+1234567890';
    final Uri phoneUri = Uri.parse(phoneNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showSnackBar('Could not launch dialer for $phoneNumber');
    }
  }
}
