import 'package:flutter/material.dart';
import 'package:molo/models/payment_model.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod?> onChanged;
  final List<PaymentMethod>? allowedMethods;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedMethod,
    required this.onChanged,
    this.allowedMethods,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final methodsToShow = allowedMethods ?? PaymentMethod.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 16),
        ...methodsToShow.map((method) {
          return RadioListTile<PaymentMethod>(
            title: Text(_getMethodName(method)),
            value: method,
            groupValue: selectedMethod,
            onChanged: onChanged,
            secondary: _getMethodIcon(method),
          );
        }).toList(),
      ],
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

  Widget _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.credit_card:
        return Icon(Icons.credit_card);
      case PaymentMethod.paypal:
        return Icon(Icons.paypal);
      case PaymentMethod.bank_transfer:
        return Icon(Icons.account_balance);
      case PaymentMethod.mobile_money:
        return Icon(Icons.phone_android);
      case PaymentMethod.cash:
        return Icon(Icons.payments_outlined);
    }
  }
}