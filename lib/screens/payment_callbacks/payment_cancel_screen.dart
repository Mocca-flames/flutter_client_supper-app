import 'package:flutter/material.dart';

class PaymentCancelScreen extends StatelessWidget {
  static const String routeName = '/payment-cancel';

  final Map<String, dynamic> arguments;

  const PaymentCancelScreen({Key? key, required this.arguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderId = arguments['order_id']?.toString() ?? 'Unknown';
    final reason = arguments['reason']?.toString() ?? 'Payment cancelled';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Cancelled'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            Text(
              reason,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can try again or choose a different payment method.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text('Order ID: $orderId'),
            if (arguments.containsKey('url')) ...[
              const SizedBox(height: 8),
              Text('URL: ${arguments['url']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Go back to payment screen
                  },
                  child: const Text('Try Again'),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}