import 'package:flutter/material.dart';
import 'package:molo/models/payment_model.dart';
import 'package:molo/providers/auth_provider.dart';
import 'package:molo/services/payment_service.dart';


class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService;

  List<PaymentModel> _payments = [];
  PaymentModel? _currentPayment;
  bool _isLoading = false;
  String? _lastError;

  PaymentProvider(this._paymentService, AuthProvider of);

  // Getters
  List<PaymentModel> get payments => _payments;
  PaymentModel? get currentPayment => _currentPayment;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;

  // Clear error state
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Error handler
  void _handleError(String operation, dynamic error) {
    debugPrint('PaymentProvider Error in $operation: $error');

    if (error is Exception) {
      _lastError = _getErrorMessage(error);
    } else {
      _lastError = 'An unexpected error occurred during $operation';
    }

    notifyListeners();
  }

  // Extract meaningful error messages
  String _getErrorMessage(Exception error) {
    if (error.toString().contains('401')) {
      return 'Authentication failed. Please log in again.';
    } else if (error.toString().contains('403')) {
      return 'Access denied. You don\'t have permission for this action.';
    } else if (error.toString().contains('404')) {
      return 'Resource not found. The requested data may no longer exist.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (error.toString().contains('payment')) {
      return 'Payment processing error. Please check your payment details.';
    } else if (error.toString().contains('card')) {
      return 'Invalid card details. Please check your card information.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  // Updated method to match API structure
  Future<PaymentModel?> initiatePayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required PaymentMethod paymentMethod,
    required String transactionId,
    String paymentType = 'client_payment',
    Map<String, dynamic>? transactionDetails,
    Map<String, dynamic>? cardDetails,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Validate card details for card payments
      if (paymentMethod == PaymentMethod.credit_card && cardDetails != null) {
        _validateCardDetails(cardDetails);
      }

      final response = await _paymentService.createPayment(
        userId: userId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        paymentType: paymentType,
        transactionDetails: transactionDetails ?? cardDetails,
      );
      
      // response expected to contain payment_url and form_data
      return response;
    } catch (e) {
      _handleError('initiate payment', e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Separate validation method for better organization
  void _validateCardDetails(Map<String, dynamic> cardDetails) {
    if (cardDetails['card_number'] == null || 
        cardDetails['card_number'].toString().replaceAll(' ', '').length < 16) {
      throw PaymentException('Invalid card number');
    }
    
    if (cardDetails['expiry_date'] == null || 
        !RegExp(r'^\d{2}/\d{2}$').hasMatch(cardDetails['expiry_date'])) {
      throw PaymentException('Invalid expiry date format. Use MM/YY');
    }
    
    if (cardDetails['cvv'] == null || 
        cardDetails['cvv'].toString().length < 3 || 
        cardDetails['cvv'].toString().length > 4) {
      throw PaymentException('Invalid CVV');
    }

    if (cardDetails['card_holder_name'] == null || 
        cardDetails['card_holder_name'].toString().trim().isEmpty) {
      throw PaymentException('Card holder name is required');
    }
  }

  // Method to fetch all payments for a user
  

  // Helper method to get payment by order ID
  PaymentModel? getPaymentByOrderId(String orderId) {
    try {
      return _payments.firstWhere(
        (payment) => payment.orderId == orderId,
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to get payment by transaction ID
  PaymentModel? getPaymentByTransactionId(String transactionId) {
    try {
      return _payments.firstWhere(
        (payment) => payment.transactionId == transactionId,
      );
    } catch (e) {
      return null;
    }
  }

  // Enhanced method to query payment status by reference (Paystack)
  Future<PaymentModel?> queryPaymentStatus(String reference) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Use PaymentService to query Paystack payment status
      final response = await _paymentService.queryPaymentStatus(reference);
      if (response is Map<String, dynamic>) {
        final paymentModel = PaymentModel.fromJson(response);
        // Update current payment if this is the one being queried
        if (paymentModel.id == reference) {
          _currentPayment = paymentModel;
        }
        return paymentModel;
      }
      return null;
    } catch (e) {
      _handleError('query payment status', e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get payments by status
  List<PaymentModel> getPaymentsByStatus(PaymentStatus status) {
    return _payments.where((payment) => payment.status == status).toList();
  }

  // Helper method to get total amount for completed payments
  double getTotalCompletedAmount({String? currency}) {
    return _payments
        .where((payment) =>
            payment.status == PaymentStatus.completed &&
            (currency == null || payment.currency == currency))
        .fold(0.0, (sum, payment) => sum + (double.tryParse(payment.amount) ?? 0.0));
  }

  // New methods for payment history and refunds
  Future<List<PaymentModel>> getPaymentHistory({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // This would need to be implemented in PaymentService
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      _handleError('get payment history', e);
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> processRefund(String paymentId, double amount) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // This would need to be implemented in PaymentService
      // For now, return false as placeholder
      return false;
    } catch (e) {
      _handleError('process refund', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}