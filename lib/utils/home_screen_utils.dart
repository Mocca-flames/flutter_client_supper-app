import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:molo/models/delivery_service_model.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/quick_action_model.dart';
import 'package:molo/providers/auth_provider.dart';
import 'package:molo/providers/location_provider.dart';
import 'package:molo/providers/map_provider.dart';
import 'package:molo/providers/order_provider.dart';
import 'package:molo/providers/websocket_provider.dart';
import 'package:molo/providers/notification_provider.dart'; // Import NotificationProvider
import 'package:molo/screens/confirm_order_details_screen.dart';
import 'package:molo/services/api_service.dart';
import 'package:molo/services/config_service.dart';
import 'package:molo/services/firebase_auth_service.dart';
import 'package:molo/services/websocket_service.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

class HomeScreenUtils {
  // Default destination for ride hailing service
  static final LocationModel jubileeMallLocation = LocationModel(
    latitude: -25.40581062494095,
    longitude: 28.269929870480787,
    placeName: "Jubile Mall",
    address: "Jubile Mall, Pretoria",
  );

  static Future<void> onDeliveryServiceSelected(
    BuildContext context,
    DeliveryService service,
  ) async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // For patient transport, check profile completeness first
    if (service.id == 'patient_transport') {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to continue')),
        );
        return;
      }

      // Ensure user profile is loaded from API if null (forceRefresh: true is used to bypass cache if needed)
      if (authProvider.userProfile == null) {
        await authProvider.loadUserProfile(forceRefresh: true);
      }

      final userProfile = authProvider.userProfile;

      // Check if profile has required fields (using userProfile which is synced with backend)
      final profileComplete =
          userProfile != null &&
          userProfile.displayName != null &&
          userProfile.displayName!.isNotEmpty &&
          userProfile.phoneNumber != null &&
          userProfile.phoneNumber!.isNotEmpty;

      if (kDebugMode) {
        print('[Patient Transport Check] Profile Complete: $profileComplete');
        print('  - userProfile: ${userProfile?.toString()}');
        print('  - displayName: ${userProfile?.displayName}');
        print('  - phoneNumber: ${userProfile?.phoneNumber}');
      }

      if (!profileComplete) {
        _showProfileUpdateDialog(context, authProvider);
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ProxyProvider<ConfigService, ApiService>(
              update: (_, configService, previous) =>
                  ApiService(Dio(), FirebaseAuthService(), configService),
            ),
            Provider<WebSocketService>(create: (_) => WebSocketService()),
            ChangeNotifierProvider<WebSocketProvider>(
              create: (context) {
                final mapProvider = Provider.of<MapProvider>(
                  context,
                  listen: false,
                );
                final wsProvider = WebSocketProvider(
                  context.read<WebSocketService>(),
                  mapProvider,
                );
                if (kDebugMode) {
                  print('[HomeScreen Nav] WebSocketProvider instance created.');
                }
                return wsProvider;
              },
            ),
            ChangeNotifierProvider<OrderProvider>(
              create: (context) => OrderProvider(
                context.read<ApiService>(),
                context.read<WebSocketProvider>(), // Pass WebSocketProvider
                context
                    .read<NotificationProvider>(), // Pass NotificationProvider
              ),
            ),
          ],
          child: ConfirmOrderDetailsScreen(
            initialPickupLocation: locationProvider.userLocation,
            initialDropoffLocation: service.id == 'ride_hailing'
                ? jubileeMallLocation
                : null,
            selectedOrderType: service.id,
          ),
        ),
      ),
    );
  }

  static void _showProfileUpdateDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final userProfile = authProvider.userProfile;
    final fullNameController = TextEditingController(
      text: userProfile?.displayName ?? '',
    );
    final phoneController = TextEditingController(
      text: userProfile?.phoneNumber ?? '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Your Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'To use Patient Transport, please provide your full name and phone number. This helps us communicate with you and match your hospital records.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final fullName = fullNameController.text.trim();
              final phone = phoneController.text.trim();

              if (fullName.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill in both fields')),
                );
                return;
              }

              try {
                // Update profile via API
                await authProvider.updateProfile({
                  'full_name': fullName,
                  'phone_number': phone,
                });

                // Check if the profile update was successful and the required fields are now present
                final updatedProfile = authProvider.userProfile;
                final profileComplete =
                    updatedProfile != null &&
                    updatedProfile.displayName != null &&
                    updatedProfile.displayName!.isNotEmpty &&
                    updatedProfile.phoneNumber != null &&
                    updatedProfile.phoneNumber!.isNotEmpty;

                if (kDebugMode) {
                  print(
                    '[Profile Update] Success check result: $profileComplete',
                  );
                  print('  - Updated Profile: ${updatedProfile?.toString()}');
                }

                Navigator.of(dialogContext).pop();

                if (profileComplete) {
                  // Now proceed with navigation
                  onDeliveryServiceSelected(
                    context,
                    DeliveryService(
                      id: 'patient_transport',
                      name: 'Patient Transport',
                      subtitle:
                          'Emergency medical transport to Molodoc Hospital',
                      imageAssetPath: 'lib/assets/wheelchair.png',
                      icon: Icons.accessible_forward,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Profile updated, but required fields are still missing. Please try again.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $e')),
                );
              }
            },
            child: const Text('Update & Continue'),
          ),
        ],
      ),
    );
  }

  static List<QuickAction> getQuickActions(BuildContext context) {
    return [
      QuickAction(
        title: "MacDonald's",
        imageAsset: 'lib/assets/mcdonalds.png',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Track Order feature coming soon!')),
          );
        },
      ),
      QuickAction(
        title: "Jubilee Mall",
        imageAsset: 'lib/assets/jubilee.png',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule feature coming soon!')),
          );
        },
      ),
      QuickAction(
        title: "Cliff Cafe",
        imageAsset: 'lib/assets/clif.png',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order history coming soon!')),
          );
        },
      ),
      QuickAction(
        title: "MacDonald's",
        imageAsset: 'lib/assets/mcdonalds.png',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Track Order feature coming soon!')),
          );
        },
      ),
    ];
  }
}
