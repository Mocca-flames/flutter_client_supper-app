import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:molo/models/payment_model.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/order_model.dart';
import 'package:molo/providers/payment_provider.dart';
import 'package:molo/providers/auth_provider.dart';
import 'package:molo/widgets/payment_method_selector.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String currency;
  final String userId; // Added required userId parameter

  const PaymentScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.userId,
    this.pickupLocation,
    this.dropoffLocation,
    this.order,
  }) : super(key: key);

  final LocationModel? pickupLocation;
  final LocationModel? dropoffLocation;
  final OrderModel? order;

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.credit_card;
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  // Generate a unique transaction ID
  String _generateTransactionId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}_${widget.orderId}';
  }

  // Format card number with spaces
  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += value[i];
    }
    return formatted;
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    // Clear any previous errors
    paymentProvider.clearError();

    setState(() {
      _isProcessing = true;
    });

    try {
      Map<String, dynamic>? cardDetails;

      // Prepare card details for card payments
      if (_selectedMethod == PaymentMethod.credit_card) {
        cardDetails = {
          'card_number': _cardNumberController.text.replaceAll(' ', ''),
          'expiry_date': _expiryDateController.text,
          'cvv': _cvvController.text,
          'card_holder_name': _cardHolderNameController.text.trim(),
          'card_type': _detectCardType(_cardNumberController.text),
        };
      }

      final response = await paymentProvider.initiatePayment(
        userId: widget.userId,
        orderId: widget.orderId,
        amount: widget.amount,
        currency: widget.currency,
        paymentMethod: _selectedMethod,
        transactionId: _generateTransactionId(),
        cardDetails: cardDetails,
      );

      if (response != null &&
          response.transactionDetails != null &&
          response.transactionDetails!.containsKey('payment_url') &&
          response.transactionDetails!.containsKey('form_data')) {
        // Clear sensitive card data after successful payment initiation
        _clearCardData();

        // Navigate directly to PaymentWebViewScreen (bypassing the old flow)
        if (mounted) {
          Navigator.of(context).pushNamed(
            '/payment_webview',
            arguments: {
              'authorizationUrl': response.transactionDetails!['authorization_url'],
              'orderId': widget.orderId,
              'pickupLocation': widget.pickupLocation,
              'dropoffLocation': widget.dropoffLocation,
              'order': widget.order,
            },
          );
        }
      } else {
        // Handle payment failure or unexpected response
        if (mounted) {
          final errorMessage =
              paymentProvider.lastError ?? 'Payment initiation failed. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _clearCardData() {
    _cardNumberController.clear();
    _expiryDateController.clear();
    _cvvController.clear();
    _cardHolderNameController.clear();
  }

  String _detectCardType(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');

    if (cardNumber.startsWith('4')) {
      return 'Visa';
    } else if (cardNumber.startsWith(RegExp(r'5[1-5]'))) {
      return 'MasterCard';
    } else if (cardNumber.startsWith(RegExp(r'3[47]'))) {
      return 'American Express';
    } else if (cardNumber.startsWith('6')) {
      return 'Discover';
    }
    return 'Unknown';
  }

  Widget _buildPaymentMethodForm() {
    switch (_selectedMethod) {
      case PaymentMethod.credit_card:
        return _buildCardForm();
      case PaymentMethod.paypal:
        return _buildPayPalForm();
      case PaymentMethod.bank_transfer:
        return _buildBankTransferForm();
      case PaymentMethod.mobile_money:
        return _buildMobileMoneyForm();
      default:
        return _buildCardForm();
    }
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        // Card Holder Name
        TextFormField(
          controller: _cardHolderNameController,
          decoration: InputDecoration(
            labelText: 'Card Holder Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter card holder name';
            }
            if (value.trim().length < 2) {
              return 'Please enter a valid name';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Card Number
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19), // 16 digits + 3 spaces
            TextInputFormatter.withFunction((oldValue, newValue) {
              final newText = _formatCardNumber(newValue.text);
              return TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
              );
            }),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            final cardNumber = value.replaceAll(' ', '');
            if (cardNumber.length < 16) {
              return 'Card number must be at least 16 digits';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        Row(
          children: [
            // Expiry Date
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.date_range),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    if (text.length >= 2 && !text.contains('/')) {
                      return TextEditingValue(
                        text: '${text.substring(0, 2)}/${text.substring(2)}',
                        selection: TextSelection.collapsed(
                          offset: text.length + 1,
                        ),
                      );
                    }
                    return newValue;
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                    return 'Invalid format';
                  }

                  final parts = value.split('/');
                  final month = int.tryParse(parts[0]);
                  final year = int.tryParse(parts[1]);

                  if (month == null || month < 1 || month > 12) {
                    return 'Invalid month';
                  }

                  final currentYear = DateTime.now().year % 100;
                  final currentMonth = DateTime.now().month;

                  if (year != null && year < currentYear) {
                    return 'Card expired';
                  }

                  if (year == currentYear && month < currentMonth) {
                    return 'Card expired';
                  }

                  return null;
                },
              ),
            ),
            SizedBox(width: 16),

            // CVV
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 3 || value.length > 4) {
                    return 'Invalid CVV';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayPalForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'You will be redirected to PayPal to complete your payment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.account_balance, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Bank transfer details will be provided after confirming your payment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.phone_android, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'You will receive an SMS prompt to complete the mobile money payment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    // Always show all payment methods, no filtering
    final List<PaymentMethod> allowedMethods = PaymentMethod.values;

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment Summary Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Summary',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order ID:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                widget.orderId,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Amount:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Payment Method Selector
                  PaymentMethodSelector(
                    selectedMethod: _selectedMethod,
                    onChanged: (method) {
                      setState(() {
                        _selectedMethod = method!;
                      });
                      // Clear form when payment method changes
                      _clearCardData();
                    },
                    allowedMethods: allowedMethods,
                  ),
                  SizedBox(height: 24),

                  // Payment Method Form
                  _buildPaymentMethodForm(),
                  SizedBox(height: 24),

                  // Error Display
                  if (paymentProvider.hasError) ...[
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                paymentProvider.lastError!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: paymentProvider.clearError,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Payment Button
                  ElevatedButton(
                    onPressed: (_isProcessing || paymentProvider.isLoading)
                        ? null
                        : _initiatePayment,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: (_isProcessing || paymentProvider.isLoading)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Processing...'),
                            ],
                          )
                        : Text('Make Payment'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
