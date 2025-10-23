import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:molo/providers/auth_provider.dart';
import 'package:molo/providers/map_provider.dart';
import 'package:molo/providers/notification_provider.dart';
import 'package:molo/providers/order_provider.dart';
import 'package:molo/providers/payment_provider.dart'; // Import PaymentProvider
import 'package:molo/providers/websocket_provider.dart';
import 'package:molo/providers/location_provider.dart'; // Import LocationProvider
import 'package:molo/services/api_service.dart';
import 'package:molo/services/config_service.dart'; // Import ConfigService
import 'package:molo/services/firebase_auth_service.dart';
import 'package:molo/services/google_map_service.dart'; // Import GoogleMapService
import 'package:molo/services/payment_service.dart'; // Import PaymentService
import 'package:molo/services/websocket_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routing/app_router.dart';
import 'providers/app_state_provider.dart';
import 'providers/error_provider.dart'; // Import 0
import 'package:molo/theme/app_theme.dart'; // Added theme import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure Firebase is initialized
  // If you are using flutterfire_cli and have firebase_options.dart, use:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // Otherwise, if you've configured Firebase manually (e.g., google-services.json),
  // Firebase.initializeApp() without options might work for Android/iOS if setup correctly.
  // For this example, we'll assume a basic initialization.
  // You might need to add specific platform configurations if not using firebase_options.dart
  try {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print("Firebase initialized successfully");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Firebase initialization failed: $e");
    }
    // Handle initialization error (e.g., show an error message or exit)
    // For now, we'll let it proceed, but in a real app, this should be handled.
  }

  // Initialize NotificationProvider
  final notificationProvider = NotificationProvider();
  await notificationProvider.initialize();

  // Initialize services
  final firebaseAuthService = FirebaseAuthService();
  final dio = Dio();
  final firestore = FirebaseFirestore.instance; // Firestore instance

  // Initialize ConfigService and fetch config
  final configService = ConfigService(firestore);
  await configService.initialize(); // Ensure config is loaded

  final apiService = ApiService(
    dio,
    firebaseAuthService,
    configService,
  ); // Pass ConfigService
  final webSocketService = WebSocketService();
  final googleMapService = GoogleMapService(); // Instantiate GoogleMapService
  final paymentService = PaymentService(apiService); // Initialize PaymentService with ApiService argument
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MyApp(
      firebaseAuthService: firebaseAuthService,
      apiService: apiService,
      webSocketService: webSocketService,
      googleMapService: googleMapService, // Pass GoogleMapService
      paymentService: paymentService, // Pass PaymentService
      sharedPreferences: prefs,
      configService: configService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final FirebaseAuthService firebaseAuthService;
  final ApiService apiService;
  final WebSocketService webSocketService;
  final GoogleMapService googleMapService; // Added GoogleMapService field
  final PaymentService paymentService; // Added PaymentService field
  final SharedPreferences sharedPreferences;
  final ConfigService configService;

  const MyApp({
    super.key,
    required this.firebaseAuthService,
    required this.apiService,
    required this.webSocketService,
    required this.googleMapService, // Added to constructor
    required this.paymentService, // Added to constructor
    required this.sharedPreferences,
    required this.configService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide ConfigService
        Provider<ConfigService>.value(value: configService),
        // Provide ApiService (which now uses ConfigService)
        Provider<ApiService>.value(value: apiService),
        // Provide GoogleMapService
        Provider<GoogleMapService>.value(value: googleMapService),
        // Provide PaymentService
        Provider<PaymentService>.value(value: paymentService),
        // MapProvider depends on GoogleMapService and ApiService
        ChangeNotifierProxyProvider2<GoogleMapService, ApiService, MapProvider>(
          create: (context) {
            final mapProvider = MapProvider(
              Provider.of<GoogleMapService>(context, listen: false),
              Provider.of<ApiService>(context, listen: false),
            );
            mapProvider.initializeMap(); // Initialize map state eagerly
            return mapProvider;
          },
          update: (_, googleMapSvc, apiSvc, previousMapProvider) => MapProvider(
            googleMapSvc,
            apiSvc,
          ),
        ),
        // Provide WebSocketService directly
        Provider<WebSocketService>.value(value: webSocketService),
        // WebSocketProvider depends on WebSocketService and MapProvider
        ChangeNotifierProxyProvider2<WebSocketService, MapProvider, WebSocketProvider>(
          create: (context) => WebSocketProvider(
            webSocketService,
            Provider.of<MapProvider>(context, listen: false),
          ),
          update: (_, webSocketSvc, mapProvider, previousWebSocketProvider) => WebSocketProvider(
            webSocketSvc,
            mapProvider,
          ),
        ),
        // NotificationProvider
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        // AuthProvider depends on FirebaseAuthService, ApiService, SharedPreferences
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            firebaseAuthService,
            apiService,
            sharedPreferences,
          ),
        ),
        // OrderProvider depends on ApiService, WebSocketProvider, and NotificationProvider
        ChangeNotifierProxyProvider3<ApiService, WebSocketProvider, NotificationProvider, OrderProvider>(
          create: (context) => OrderProvider(
            apiService,
            Provider.of<WebSocketProvider>(context, listen: false),
            Provider.of<NotificationProvider>(context, listen: false),
          ),
          update: (_, api, webSocketProvider, notificationProvider, previousOrderProvider) => OrderProvider(
            api,
            webSocketProvider,
            notificationProvider,
          ),
        ),
        // PaymentProvider depends on PaymentService and AuthProvider
        ChangeNotifierProxyProvider2<PaymentService, AuthProvider, PaymentProvider>(
          create: (context) => PaymentProvider(
            Provider.of<PaymentService>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (_, paymentService, authProvider, previousPaymentProvider) => PaymentProvider(
            paymentService,
            authProvider,
          ),
        ),
        // Add AppStateProvider
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider(),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(),
        ),
        // Add ErrorProvider
        ChangeNotifierProvider<ErrorProvider>(
          create: (_) => ErrorProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Patient App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // Apply the custom theme
        // Use AppRouter for navigation
        initialRoute: AppRouter.splashRoute,
        onGenerateRoute: AppRouter.generateRoute,
        // The home and routes properties are now managed by AppRouter
        // home: const SplashScreen(), // Removed
        // routes: { // Removed
        //   '/home': (context) => const HomeScreen(),
        // },
      ),
    );
  }
}
