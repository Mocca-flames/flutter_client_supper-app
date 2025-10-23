import 'package:flutter/material.dart';

class PaymentNotifyScreen extends StatelessWidget {
  static const String routeName = '/payment-notify';

  final Map<String, String> queryParams;

  const PaymentNotifyScreen({Key? key, required this.queryParams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This screen is typically used for server-to-server notifications.
    // For the app, we can just show a simple acknowledgement or log the params.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Notification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.notifications, color: Colors.blue, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Payment notification received.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Notification parameters:'),
              const SizedBox(height: 8),
              ...queryParams.entries.map((e) => Text('${e.key}: ${e.value}')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}