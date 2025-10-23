import 'package:flutter/material.dart';
import 'package:molo/models/payment_model.dart';
import 'package:molo/services/api_service.dart';

class PaymentService {
  final ApiService _apiService;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  PaymentService(this._apiService);

  Future<List<PaymentModel>> getOrderPayments({required String orderId}) async {
    try {
      final response = await _apiService.get('/api/payments/order/$orderId');
      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw PaymentException('Failed to fetch payments: ${e.toString()}');
    }
  }

  Future<PaymentModel> createPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required PaymentMethod paymentMethod,
    String paymentType = 'client_payment',
    String? transactionId,
    Map<String, dynamic>? transactionDetails,
    String? gateway,
  }) async {
    isLoading.value = true;
    try {
      final response = await _apiService.createPayment(
        userId: userId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod.toString().split('.').last,
        paymentType: paymentType,
        gateway: gateway,
      );
      return PaymentModel.fromJson(response['payment'] ?? response);
    } catch (e) {
      throw PaymentException('Payment failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> initializePaystackPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required PaymentMethod paymentMethod,
    String paymentType = 'client_payment',
  }) async {
    isLoading.value = true;
    try {
      final response = await _apiService.initializePaystackPayment(
        userId: userId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod.toString().split('.').last,
        paymentType: paymentType,
      );
      return response;
    } catch (e) {
      throw PaymentException('Paystack initialization failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteOrder() async {
    try {
      // Assuming the order deletion endpoint is DELETE /api/orders/{orderId}
      await _apiService.delete('/api/orders/delete_all');
    } catch (e) {
      // Log or handle error, but don't re-throw if deletion is best effort after payment failure
      print('Warning: Failed to delete All Orders');
    }
  }

  Future<bool> verifyPaystackPayment(String reference) async {
    isLoading.value = true;
    try {
      // Call ApiService.verifyPaystackPayment for consistency
      final response = await _apiService.verifyPaystackPayment(reference);

      // Normalize status from various possible response shapes
      String? status;
      status = response['status'] ??
               response['data']?['status'] ??
               response['payment']?['status'] ??
               response['gateway_response']?['status'];
    
      // Broaden success criteria: accept success, completed, paid, approved, verified
      final normalizedStatus = status?.toLowerCase();
      final isSuccess = normalizedStatus == 'success' ||
                        normalizedStatus == 'completed' ||
                        normalizedStatus == 'paid' ||
                        normalizedStatus == 'approved' ||
                        normalizedStatus == 'verified' ||
                        (response['verified'] == true) ||
                        (response['approved'] == true);

      return isSuccess;
    } catch (e) {
      throw PaymentException('Paystack verification failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> queryPaymentStatus(String reference) async {
    try {
      // Use the existing verifyPaystackPayment method for status queries
      final response = await _apiService.verifyPaystackPayment(reference);
      if (response is Map<String, dynamic>) {
        return response;
      } else if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      // Fallback: wrap non-map responses
      return {'data': response};
    } catch (e) {
      throw PaymentException('Failed to query payment status: ${e.toString()}');
    }
  }
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
}
