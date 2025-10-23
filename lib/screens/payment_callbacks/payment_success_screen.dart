import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/location_model.dart';
import '../../models/payment_model.dart';

class PaymentSuccessScreen extends StatefulWidget {
  static const String routeName = '/payment-success';

  final Map<String, dynamic> arguments;

  const PaymentSuccessScreen({Key? key, required this.arguments}) : super(key: key);

  @override
  PaymentSuccessScreenState createState() => PaymentSuccessScreenState();
}

class PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _navigateToFindDriver();
      }
    });
  }

  @override
  void dispose() {
    _isNavigating = false;
    super.dispose();
  }

  Future<void> _navigateToFindDriver() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final paymentId = widget.arguments['pf_payment_id']?.toString() ?? 'Unknown';
    final orderId = widget.arguments['custom_str1']?.toString() ?? widget.arguments['order_id']?.toString() ?? 'Unknown';

    print('PaymentSuccessScreen: Starting automatic navigation for Payment ID: $paymentId, Order ID: $orderId');

    if (!mounted) return;

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    // Verify payment status with Paystack (Phase 3: Payment Verification)
    print('PaymentSuccessScreen: Verifying payment status for reference: $paymentId');
    final verifiedPayment = await paymentProvider.queryPaymentStatus(paymentId);

    if (!mounted) return;

    if (verifiedPayment == null) {
      print('PaymentSuccessScreen: Payment verification failed - no response');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed. Please contact support.')),
        );
      }
      _isNavigating = false;
      return;
    }

    if (verifiedPayment.status != PaymentStatus.completed) {
      print('PaymentSuccessScreen: Payment not completed - status: ${verifiedPayment.status}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment status: ${verifiedPayment.getStatusText()}. Please try again or contact support.')),
        );
      }
      _isNavigating = false;
      return;
    }

    print('PaymentSuccessScreen: Payment verified successfully, proceeding with order fetch');

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    print('PaymentSuccessScreen: Orders in provider: ${orderProvider.orders.map((o) => o.id).toList()}');

    // Fetch order from server since local orders may be empty
    final order = await orderProvider.getOrderById(orderId);

    if (!mounted) return;

    if (order != null) {
      print('PaymentSuccessScreen: Order fetched successfully, navigating to find driver');

      final pickupLocation = LocationModel(
        address: order.pickupAddress,
        latitude: double.tryParse(order.pickupLatitude ?? '') ?? 0.0,
        longitude: double.tryParse(order.pickupLongitude ?? '') ?? 0.0,
      );
      final dropoffLocation = LocationModel(
        address: order.dropoffAddress,
        latitude: double.tryParse(order.dropoffLatitude ?? '') ?? 0.0,
        longitude: double.tryParse(order.dropoffLongitude ?? '') ?? 0.0,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/find-driver',
          arguments: {
            'pickupLocation': pickupLocation,
            'dropoffLocation': dropoffLocation,
            'order': order,
          },
        );
        print('PaymentSuccessScreen: Navigation to find driver completed');
      }
    } else {
      print('PaymentSuccessScreen: Order not found on server, navigation failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order not found. Please contact support.')),
        );
      }
    }

    _isNavigating = false;
  }

  @override
  Widget build(BuildContext context) {
    final paymentId = widget.arguments['pf_payment_id']?.toString() ?? 'Unknown';
    final orderId = widget.arguments['custom_str1']?.toString() ?? widget.arguments['order_id']?.toString() ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Success'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Your payment was successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('Payment ID: $paymentId'),
            Text('Order ID: $orderId'),
            if (widget.arguments.containsKey('url')) ...[
              const SizedBox(height: 8),
              Text('URL: ${widget.arguments['url']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            if (widget.arguments.containsKey('note')) ...[
              const SizedBox(height: 8),
              Text('Note: ${widget.arguments['note']}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ],
            const SizedBox(height: 24),
            const Text(
              'Redirecting to find driver...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}