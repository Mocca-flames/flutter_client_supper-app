import 'package:flutter/material.dart';
import 'package:molo/screens/payment_webview_screen.dart' as payment_webview;
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/order_details_screen.dart';
import '../screens/order_tracking_screen.dart';
import '../screens/confirm_order_details_screen.dart' as confirm;
import '../screens/find_driver_screen.dart';
import '../screens/order_management_screen.dart';
import '../screens/main_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/payment_callbacks/payment_success_screen.dart';
import '../screens/payment_callbacks/payment_cancel_screen.dart';
import '../screens/payment_callbacks/payment_notify_screen.dart';
import '../screens/order_payment_choice_screen.dart';
import '../models/location_model.dart';
import '../models/order_model.dart';

class AppRouter {
  // Route Names
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String mainRoute = '/main';
  static const String confirmOrderDetailsRoute = '/confirm-order-details';
  static const String findDriverRoute = '/find-driver';
  static const String orderManagementRoute = '/order-management';
  static const String orderDetailsRoute = '/order-details';
  static const String orderTrackingRoute = '/order-tracking';
  static const String settingsRoute = '/settings';
  static const String paymentRoute = '/payment';
  static const String paymentWebViewRoute = '/payment-webview';
  static const String orderPaymentChoiceRoute = '/order-payment-choice';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return _buildRoute(const SplashScreen(), settings);
      case loginRoute:
        return _buildRoute(const LoginScreen(), settings);
      case registerRoute:
        return _buildRoute(const RegisterScreen(), settings);
      case homeRoute:
        return _buildRoute(const HomeScreen(), settings);
      case mainRoute:
        return _buildRoute(const MainScreen(), settings);
      case confirmOrderDetailsRoute:
        return _buildRoute(const confirm.ConfirmOrderDetailsScreen(), settings);
      case orderManagementRoute:
        return _buildRoute(const OrderManagementScreen(), settings);
      case orderDetailsRoute:
        final String? orderId = settings.arguments as String?;
        if (orderId != null) {
          return _buildRoute(OrderDetailsScreen(orderId: orderId), settings);
        }
        return _errorRoute(settings, "Order ID missing for order details");
      case orderTrackingRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        final String? orderId = args != null ? args['orderId'] as String? : null;
        if (orderId != null) {
          return _buildRoute(OrderTrackingScreen(orderId: orderId), settings);
        }
        return _errorRoute(settings, "Order ID missing for order tracking");
      case settingsRoute:
        return _buildRoute(const SettingsScreen(), settings);
      case paymentRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null &&
            args.containsKey('orderId') &&
            args.containsKey('amount') &&
            args.containsKey('currency') &&
            args.containsKey('userId')) {
          return _buildRoute(
            PaymentScreen(
              orderId: args['orderId'] as String,
              amount: args['amount'] as double,
              currency: args['currency'] as String,
              userId: args['userId'] as String,
              pickupLocation: args['pickupLocation'] as LocationModel?,
              dropoffLocation: args['dropoffLocation'] as LocationModel?,
              order: args['order'] as OrderModel?,
            ),
            settings,
          );
        }
        return _errorRoute(
          settings,
          "Missing required arguments for payment screen",
        );
      case paymentWebViewRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null &&
            args.containsKey('authorizationUrl') &&
            args.containsKey('orderId')) {
          return _buildRoute(
            payment_webview.PaymentWebViewScreen(
              authorizationUrl: args['authorizationUrl'] as String,
              orderId: args['orderId'] as String,
              pickupLocation: args['pickupLocation'] as LocationModel?,
              dropoffLocation: args['dropoffLocation'] as LocationModel?,
              order: args['order'] as OrderModel?,
            ),
            settings,
          );
        }
        return _errorRoute(
          settings,
          "Missing required arguments for payment webview (authorizationUrl or orderId)",
        );
      case findDriverRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null &&
            args.containsKey('order') &&
            args.containsKey('pickupLocation') &&
            args.containsKey('dropoffLocation')) {
          return _buildRoute(
            FindDriverScreen(
              pickupLocation: args['pickupLocation'] as LocationModel,
              dropoffLocation: args['dropoffLocation'] as LocationModel,
              order: args['order'] as OrderModel,
            ),
            settings,
          );
        }
        return _errorRoute(
          settings,
          "Missing order argument for find driver screen",
        );
      case orderPaymentChoiceRoute:
        print('DEBUG: Generating route for orderPaymentChoiceRoute');
        final args = settings.arguments as Map<String, dynamic>?;
        print('DEBUG: Route arguments received: $args');

        if (args != null &&
            args.containsKey('userId') &&
            args.containsKey('pickupLocation') &&
            args.containsKey('dropoffLocation') &&
            args.containsKey('orderData')) {
          print('DEBUG: All required arguments present, creating OrderPaymentChoiceScreen');
          return _buildRoute(
            OrderPaymentChoiceScreen(
              userId: args['userId'] as String,
              pickupLocation: args['pickupLocation'] as LocationModel,
              dropoffLocation: args['dropoffLocation'] as LocationModel,
              orderData: args['orderData'] as Map<String, dynamic>,
            ),
            settings,
          );
        }
        print('DEBUG: Missing required arguments for order payment choice screen');
        print('DEBUG: Available keys: ${args?.keys.toList()}');
        return _errorRoute(
          settings,
          "Missing required arguments for order payment choice screen",
        );
      case '/payment-success':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _buildRoute(
          PaymentSuccessScreen(arguments: args),
          settings,
        );
      case '/payment-cancel':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _buildRoute(
          PaymentCancelScreen(arguments: args),
          settings,
        );
      case '/payment-notify':
        final args = settings.arguments as Map<String, String>? ?? {};
        return _buildRoute(
          PaymentNotifyScreen(queryParams: args),
          settings,
        );
      default:
        return _errorRoute(settings, "Unknown route: ${settings.name}");
    }
  }

  static MaterialPageRoute _buildRoute(Widget widget, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => widget, settings: settings);
  }

  static Route<dynamic> _errorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Routing Error: $message')),
      ),
    );
  }

  // Helper method to check if context is valid
  static bool _isContextValid(BuildContext context) {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  // Static Navigation Methods with Context Safety
  static void navigateToLogin(BuildContext context) {
    if (!_isContextValid(context)) return;
    Navigator.of(context).pushNamedAndRemoveUntil(loginRoute, (route) => false);
  }

  static void navigateToHome(BuildContext context) {
    if (!_isContextValid(context)) return;
    Navigator.of(context).pushNamedAndRemoveUntil(mainRoute, (route) => false);
  }

  static Future<dynamic>? navigateToOrderTracking(
    BuildContext context,
    String orderId,
  ) {
    if (!_isContextValid(context)) return null;
    return Navigator.of(
      context,
    ).pushNamed(orderTrackingRoute, arguments: {'orderId': orderId});
  }

  static Future<dynamic>? navigateToOrderDetails(
    BuildContext context,
    String orderId,
  ) {
    if (!_isContextValid(context)) return null;
    return Navigator.of(
      context,
    ).pushNamed(orderDetailsRoute, arguments: orderId);
  }

  static Future<dynamic>? navigateToConfirmOrderDetails(BuildContext context) {
    if (!_isContextValid(context)) return null;
    return Navigator.of(context).pushNamed(confirmOrderDetailsRoute);
  }

  static Future<dynamic>? navigateToOrderManagement(BuildContext context) {
    if (!_isContextValid(context)) return null;
    return Navigator.of(context).pushNamed(orderManagementRoute);
  }

  static Future<dynamic>? navigateToFindDriver(
    BuildContext context, {
    required LocationModel pickupLocation,
    required LocationModel dropoffLocation,
    required OrderModel order,
  }) {
    if (!_isContextValid(context)) return null;
    return Navigator.of(context).pushNamed(
      findDriverRoute,
      arguments: {
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'order': order,
      },
    );
  }

  static Future<dynamic>? navigateToOrderPaymentChoice(
    BuildContext context, {
    required String userId,
    required LocationModel pickupLocation,
    required LocationModel dropoffLocation,
    required Map<String, dynamic> orderData,
  }) {
    print('DEBUG: AppRouter.navigateToOrderPaymentChoice called');
    print('DEBUG: Context valid: ${_isContextValid(context)}');
    print('DEBUG: Navigation arguments: userId=$userId');

    if (!_isContextValid(context)) {
      print('DEBUG: Context is not valid, returning null');
      return null;
    }

    try {
      final result = Navigator.of(context).pushNamed(
        orderPaymentChoiceRoute,
        arguments: {
          'userId': userId,
          'pickupLocation': pickupLocation,
          'dropoffLocation': dropoffLocation,
          'orderData': orderData,
        },
      );
      print('DEBUG: Navigator.pushNamed completed successfully');
      return result;
    } catch (e) {
      print('DEBUG: Navigator.pushNamed failed with error: $e');
      print('DEBUG: Error stack trace: ${StackTrace.current}');
      return null;
    }
  }

  static Future<dynamic>? navigateToPayment(
    BuildContext context, {
    required String orderId,
    required double amount,
    required String currency,
    required String userId,
    LocationModel? pickupLocation,
    LocationModel? dropoffLocation,
    OrderModel? order,
  }) {
    if (!_isContextValid(context)) {
      print('Context is no longer valid, skipping payment navigation');
      return null;
    }

    return Navigator.of(context).pushNamed(
      paymentRoute,
      arguments: {
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
        'userId': userId,
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'order': order,
      },
    );
  }

  static Future<dynamic>? navigateToRegister(BuildContext context) {
    if (!_isContextValid(context)) return null;
    return Navigator.of(context).pushNamed(registerRoute);
  }
  static Future<dynamic>? navigateToPaymentWebView(
    BuildContext context, {
    required String authorizationUrl,
    required String orderId,
    LocationModel? pickupLocation,
    LocationModel? dropoffLocation,
    OrderModel? order,
  }) {
    if (!_isContextValid(context)) return null;
    return Navigator.of(context).pushNamed(
      paymentWebViewRoute,
      arguments: {
        'authorizationUrl': authorizationUrl,
        'orderId': orderId,
        'pickupLocation': pickupLocation,
        'dropoffLocation': dropoffLocation,
        'order': order,
      },
    );
  }
}
