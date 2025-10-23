import 'package:flutter/material.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/order_model.dart';
import 'package:molo/models/payment_model.dart';
import 'package:molo/routing/app_router.dart';
import 'package:molo/services/payment_service.dart';
import 'package:provider/provider.dart';

class PaymentHandler {
  static void navigateToPayment({
    required BuildContext context,
    required String orderId,
    required double amount,
    required String currency,
    required String userId,
    required LocationModel pickupLocation,
    required LocationModel dropoffLocation,
    required OrderModel order,
  }) {
    if (!context.mounted) {
      print('Widget not mounted, skipping navigation');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.mounted) {
        try {
          // Initialize Paystack payment
          final paymentService = PaymentService(Provider.of(context, listen: false));
          final paystackResponse = await paymentService.initializePaystackPayment(
            userId: userId,
            orderId: orderId,
            amount: amount,
            currency: currency,
            paymentMethod: PaymentMethod.credit_card, // Default to credit_card for online payment
          );

          final authorizationUrl = paystackResponse['authorization_url'];
          if (authorizationUrl != null && authorizationUrl is String) {
            // Navigate to PaymentWebviewScreen for in-app payment
            // PaymentWebViewScreen handles navigation directly on success
            final result = await AppRouter.navigateToPaymentWebView(
              context,
              authorizationUrl: authorizationUrl,
              orderId: orderId,
              pickupLocation: pickupLocation,
              dropoffLocation: dropoffLocation,
              order: order,
            );

            // Only delete order if payment was explicitly cancelled/failed
            if (result == false && context.mounted) {
              await paymentService.deleteOrder();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment cancelled. Order deleted.')),
              );
            }
            // If result is null or true, navigation was handled by PaymentWebViewScreen
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to initialize payment')),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment initialization failed: $e')),
            );
          }
        }
      }
    });
  }

  static void navigateToCashPayment({
    required BuildContext context,
    required LocationModel pickupLocation,
    required LocationModel dropoffLocation,
    required OrderModel order,
  }) {
    if (!context.mounted) {
      print('Widget not mounted, skipping navigation');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.mounted) {
        try {
          // Create cash payment record
          final paymentService = PaymentService(Provider.of(context, listen: false));
          await paymentService.createPayment(
            userId: order.clientId,
            orderId: order.id,
            amount: order.price ?? 0.0,
            currency: 'ZAR', // Assuming ZAR as default
            paymentMethod: PaymentMethod.cash,
          );

          // Navigate to FindDriver screen
          AppRouter.navigateToFindDriver(
            context,
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            order: order,
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to process cash payment: $e')),
            );
          }
        }
      }
    });
  }
}
