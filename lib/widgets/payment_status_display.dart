import 'package:flutter/material.dart';
import 'package:molo/models/payment_model.dart';

class PaymentStatusDisplay extends StatelessWidget {
  final PaymentModel payment;

  const PaymentStatusDisplay({
    Key? key,
    required this.payment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Payment Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Payment ID: ${payment.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 8),
            Text(
              'Amount: ${payment.amount} ${payment.currency}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Method: ${_getMethodName(payment.paymentMethod)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Chip(
                  label: Text(payment.getStatusText()),
                  backgroundColor: _getStatusColor(payment.status),
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(payment.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (payment.transactionDetails != null &&
                payment.transactionDetails!.containsKey('message')) ...[
              SizedBox(height: 8),
              Text(
                'Message: ${payment.transactionDetails!['message']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.credit_card:
        return 'Credit/Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
      case PaymentMethod.mobile_money:
        return 'Mobile Money';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }

  Color _getStatusColor(PaymentStatus status) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}