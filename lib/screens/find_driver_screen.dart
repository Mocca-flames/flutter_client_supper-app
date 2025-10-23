import 'package:flutter/material.dart';
import 'package:molo/controller/find_driver_controller.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/order_model.dart';
import 'package:provider/provider.dart';
import '../widgets/loading_widget.dart';
import '../theme/app_colors.dart';

class FindDriverScreen extends StatefulWidget {
  static const String routeName = '/find-driver';

  final LocationModel pickupLocation;
  final LocationModel dropoffLocation;
  final OrderModel order;

  const FindDriverScreen({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.order,
  });

  @override
  FindDriverScreenState createState() => FindDriverScreenState();
}

class FindDriverScreenState extends State<FindDriverScreen> {
  late FindDriverController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = FindDriverController(
      context: context,
      pickupLocation: widget.pickupLocation,
      dropoffLocation: widget.dropoffLocation,
      order: widget.order,
    );

    // Use addPostFrameCallback to ensure initialization happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController();
    });
  }

  void _initializeController() async {
    if (!_isInitialized && mounted) {
      setState(() {
        _isInitialized = true;
      });

      // Use addPostFrameCallback to ensure this happens after build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          // Find driver and start realtime tracking
          await _controller.findDriver();
        } catch (e) {
          if (mounted) {
            // Handle initialization error
            print('Error initializing controller: $e');
            // Optionally show error to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to initialize: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    debugPrint('FindDriverScreen: dispose() called');
    _controller.dispose();
    super.dispose();
    debugPrint('FindDriverScreen: dispose() completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Getting Your Driver'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isInitialized
          ? ChangeNotifierProvider.value(
              value: _controller,
              child: Consumer<FindDriverController>(
                builder: (context, controller, child) {
                  return _buildContent(controller);
                },
              ),
            )
          : const Center(
              child: LoadingWidget(message: 'Setting up your order...'),
            ),
    );
  }

  Widget _buildContent(FindDriverController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOrderCard(controller),
          const SizedBox(height: 24),
          Expanded(child: _buildMainContent(controller)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(FindDriverController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.order.orderType
                        .toString()
                        .split('.')
                        .last
                        .replaceAll('_', ' ')
                        .toTitleCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackgroundColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.trip_origin,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pick up',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.order.pickupAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.onBackgroundColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.successColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Drop off',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.order.dropoffAddress,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.onBackgroundColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (controller.order.specialInstructions != null &&
                controller.order.specialInstructions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.order.specialInstructions!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.onBackgroundColor.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(FindDriverController controller) {
    if (controller.isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingWidget(message: 'Calculating your price...'),
          const SizedBox(height: 16),
          Text(
            'Getting our drivers ready',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (controller.isDriverFound) {
      return _buildDriverFoundContent(controller);
    }

    return _buildSearchingContent(controller);
  }

  Widget _buildDriverFoundContent(FindDriverController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.successColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.successColor,
            size: 64,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Driver Ready!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackgroundColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your order has been confirmed',
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Total Price',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R${controller.estimatedPrice?.toStringAsFixed(2) ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to order tracking screen
              Navigator.of(context).pushReplacementNamed(
                '/order-tracking',
                arguments: {'orderId': widget.order.id},
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.navigate_next, size: 24),
                SizedBox(width: 8),
                Text(
                  'Track Your Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchingContent(FindDriverController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_car,
            color: AppColors.primaryColor,
            size: 64,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Getting Drivers Ready',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackgroundColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Almost there...',
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
        if (controller.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
