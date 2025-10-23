import 'package:flutter/material.dart';
import 'package:molo/providers/location_provider.dart';
import 'package:molo/models/delivery_service_model.dart';
import 'package:molo/widgets/home_screen/delivery_services_widget.dart';
import 'package:molo/widgets/home_screen/location_header_widget.dart';
import 'package:molo/widgets/home_screen/quick_actions_widget.dart';
import 'package:provider/provider.dart';
import 'package:molo/utils/home_screen_utils.dart'; // Import the new utility file

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<DeliveryService> _deliveryServices = [
    DeliveryService(
      id: 'patient_transport',
      name: "Patient Transport",
      subtitle: "Emergency medical transport to Molodoc Hospital",
      imageAssetPath: "lib/assets/wheelchair.png",
      icon: Icons.accessible_forward,
    ),
    DeliveryService(
      id: 'ride_hailing',
      name: "Ride Hailing",
      subtitle: "Ride anywhere",
      imageAssetPath: "lib/assets/car.png",
      icon: Icons.medical_services_outlined,
    ),
    DeliveryService(
      id: 'parcel_delivery',
      name: "Product Delivery",
      subtitle: "Documents & packages",
      imageAssetPath: "lib/assets/parcel.png",
      icon: Icons.inventory_2_outlined,
    ),
    DeliveryService(
      id: 'food_delivery',
      name: "Food Delivery",
      subtitle: "Restaurants & cafes",
      imageAssetPath: "lib/assets/food.png",
      icon: Icons.restaurant_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward(); // Start animation here
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  LocationHeaderWidget(
                    userLocation: locationProvider.userLocation,
                    isRefreshing: locationProvider.isRefreshing,
                    isLoadingLocation: locationProvider.isLoadingLocation,
                    onRefresh: locationProvider.refreshLocation,
                    onSelectAddress: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Address selection coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  QuickActionsWidget(
                    quickActions: HomeScreenUtils.getQuickActions(context),
                  ),
                  const SizedBox(height: 24),
                  DeliveryServicesWidget(
                    deliveryServices: _deliveryServices,
                    fadeAnimation: _fadeAnimation,
                    onDeliveryServiceSelected: (service) =>
                        HomeScreenUtils.onDeliveryServiceSelected(
                          context,
                          service,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
