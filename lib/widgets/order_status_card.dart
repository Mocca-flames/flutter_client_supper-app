import 'package:flutter/material.dart';
import 'package:molo/models/order_model.dart';
import 'package:molo/models/payment_model.dart';
import 'package:provider/provider.dart';
import 'package:molo/providers/payment_provider.dart';

class OrderStatusCard extends StatelessWidget {
  final OrderModel order;

  const OrderStatusCard({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Order #${order.id}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Status: ${order.getStatusText()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Type: ${order.orderType == OrderType.delivery ? 'Delivery' : 'Ride'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),
            Text(
              'From: ${order.pickupAddress}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'To: ${order.dropoffAddress}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 8),

            // Payment information
            if (order.paymentId != null) ...[
              Divider(),
              SizedBox(height: 8),
              Text(
                'Payment ID: ${order.paymentId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Payment Status: ${order.paymentStatus ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            // Payment status from PaymentProvider
            Consumer<PaymentProvider>(
              builder: (context, paymentProvider, child) {
                final payment = paymentProvider.getPaymentByOrderId(order.id);
                if (payment != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(),
                      SizedBox(height: 8),
                      Text(
                        'Payment Status: ${payment.getStatusText()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getPaymentStatusColor(payment.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Amount: ${payment.amount} ${payment.currency}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
      case PaymentStatus.cancelled:
        return Colors.grey;
      }
  }
}
