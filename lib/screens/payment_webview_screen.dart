import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:molo/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:molo/services/firebase_auth_service.dart';
import 'package:molo/services/config_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:molo/services/payment_service.dart';
import 'package:logger/logger.dart';
import 'package:molo/models/location_model.dart';
import 'package:molo/models/order_model.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String orderId;
  final LocationModel? pickupLocation;
  final LocationModel? dropoffLocation;
  final OrderModel? order;

  const PaymentWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.orderId,
    this.pickupLocation,
    this.dropoffLocation,
    this.order,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  ApiService? _apiService;
  PaymentService? _paymentService;
  late final Logger _logger;
  bool _isLoading = true;
  Timer? _timeoutTimer;
  bool _isProcessing = false; // Prevent duplicate processing
  bool _isServicesInitialized = false; // Track service readiness

  @override
  void initState() {
    super.initState();
    _logger = Logger();
    _initializeServices();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            if (_isProcessing) return NavigationDecision.prevent;

            final url = request.url;
            final uri = Uri.parse(url);

            _logger.d('Navigation request: $url');

            // CRITICAL: Check for Paystack's standard close URL (cancel/close action)
            if (_isPaystackCloseUrl(url)) {
              _logger.i('Detected Paystack close/cancel URL');
              _handlePaymentResult(false);
              return NavigationDecision.prevent;
            }

            // Check for reference parameter (success/failure redirect)
            final reference =
                uri.queryParameters['reference'] ??
                uri.queryParameters['trxref'] ??
                uri.queryParameters['tx_ref'];

            if (reference != null && reference.isNotEmpty) {
              _logger.i('Detected reference parameter: $reference');
              _verifyPaymentWithBackend(reference);
              return NavigationDecision.prevent;
            }

            // Check custom callback URL patterns (if you use them)
            if (_isCallbackUrl(url)) {
              _logger.i('Detected custom callback URL pattern');
              final extractedRef = _extractReferenceFromUrl(url);
              if (extractedRef != null && extractedRef.isNotEmpty) {
                _verifyPaymentWithBackend(extractedRef);
              } else {
                _handlePaymentResult(false);
              }
              return NavigationDecision.prevent;
            }

            // Fallback: Check for explicit success/failure keywords
            if (_isSuccessUrl(url)) {
              _logger.i('Detected success URL pattern');
              final extractedRef = _extractReferenceFromUrl(url);
              if (extractedRef != null) {
                _verifyPaymentWithBackend(extractedRef);
              } else {
                _handlePaymentResult(true); // Optimistic success
              }
              return NavigationDecision.prevent;
            }

            if (_isCancelUrl(url)) {
              _logger.i('Detected cancel/failure URL pattern');
              _handlePaymentResult(false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            _logger.e('WebView error: ${error.description}');
            if (!_isProcessing) {
              _handlePaymentResult(false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));

    // Set a timeout for the entire payment process (10 minutes for bank transfers)
    _timeoutTimer = Timer(const Duration(minutes: 10), () {
      if (!_isProcessing) {
        _logger.w('Payment timeout reached');
        _handlePaymentResult(false);
      }
    });
  }

  /// Checks if URL is Paystack's standard close/cancel URL
  bool _isPaystackCloseUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('standard.paystack.co/close') ||
        lowerUrl.contains('checkout.paystack.com/close');
  }

  /// Checks if URL matches callback URL patterns
  bool _isCallbackUrl(String url) {
    final lowerUrl = url.toLowerCase();
    // Your callback URL patterns (if you set them during transaction init)
    final callbackPatterns = [
      '/payment/callback',
      '/payment-callback',
      '/api/payment/callback',
    ];

    return callbackPatterns.any((pattern) => lowerUrl.contains(pattern));
  }

  /// Enhanced success URL detection
  bool _isSuccessUrl(String url) {
    final lowerUrl = url.toLowerCase();

    // More specific success patterns
    final successPatterns = [
      'payment-success',
      'payment_success',
      'paymentsuccess',
      'Payment Successful',
      'transaction-successful',
      'transaction_successful',
      'payment-complete',
      'payment_complete',
      'order-confirmed',
      'order_confirmed',
      'thank-you',
      'thankyou',
      '/success',
      '/completed',
      '/approved',
      '/confirmed',
    ];

    // Check for Paystack checkout success indicators
    if (lowerUrl.contains('checkout.paystack.com') &&
        (lowerUrl.contains('reference=') || lowerUrl.contains('trxref='))) {
      return true;
    }

    return successPatterns.any((pattern) => lowerUrl.contains(pattern));
  }

  /// Enhanced cancel/failure URL detection
  bool _isCancelUrl(String url) {
    final lowerUrl = url.toLowerCase();

    final cancelPatterns = [
      'payment-cancelled',
      'payment_cancelled',
      'paymentcancelled',
      'payment-failed',
      'payment_failed',
      'paymentfailed',
      'transaction-failed',
      'transaction_failed',
      'payment-declined',
      'payment_declined',
      'payment-error',
      'payment_error',
      '/cancel',
      '/cancelled',
      '/failed',
      '/failure',
      '/declined',
      '/error',
      '/rejected',
    ];

    return cancelPatterns.any((pattern) => lowerUrl.contains(pattern));
  }

  /// Extracts payment reference from various URL formats
  String? _extractReferenceFromUrl(String url) {
    final uri = Uri.parse(url);

    // Check query parameters
    final reference =
        uri.queryParameters['reference'] ??
        uri.queryParameters['trxref'] ??
        uri.queryParameters['tx_ref'] ??
        uri.queryParameters['transaction_id'] ??
        uri.queryParameters['payment_id'];

    if (reference != null && reference.isNotEmpty) {
      return reference;
    }

    // Check URL path segments for reference patterns
    final pathSegments = uri.pathSegments;
    for (int i = 0; i < pathSegments.length; i++) {
      if (pathSegments[i].toLowerCase() == 'reference' &&
          i + 1 < pathSegments.length) {
        return pathSegments[i + 1];
      }
      // Look for reference-like patterns in path
      if (pathSegments[i].startsWith('ref_') ||
          pathSegments[i].startsWith('txn_') ||
          pathSegments[i].startsWith('TXN_')) {
        return pathSegments[i];
      }
    }

    return null;
  }

  void _handlePaymentResult(dynamic result) {
    if (_isProcessing) return;

    _isProcessing = true;
    _timeoutTimer?.cancel();

    // Hide loading indicator
    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (mounted) {
      _logger.i('Payment result: $result');
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _verifyPaymentWithBackend(String reference) async {
    if (_isProcessing) return;
    if (!_isServicesInitialized || _paymentService == null) {
      _logger.e('Services not initialized when attempting payment verification.');
      _handlePaymentResult(false);
      return;
    }

    _isProcessing = true;

    try {
      _logger.d(
        'Verifying payment with backend using reference: $reference for orderId: ${widget.orderId}',
      );

      // Show loading indicator
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // Use PaymentService to verify the payment
      final isSuccess = await _paymentService!.verifyPaystackPayment(reference);

      // Hide loading indicator
      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (isSuccess) {
        // Navigate directly to FindDriverScreen on success, replacing the current screen
        if (mounted &&
            widget.pickupLocation != null &&
            widget.dropoffLocation != null &&
            widget.order != null) {
          Navigator.of(context).pushReplacementNamed(
            '/find-driver',
            arguments: {
              'pickupLocation': widget.pickupLocation,
              'dropoffLocation': widget.dropoffLocation,
              'order': widget.order,
            },
          );
        } else {
          // Fallback: pop with success if we don't have the required data
          _handlePaymentResult(true);
        }
      } else {
        // Handle payment failure: delete orders and redirect to main screen
        await _handlePaymentFailure();
      }
    } catch (e) {
      _logger.e('Error verifying payment with backend: $e');
      // Hide loading indicator on error
      if (mounted) {
        setState(() => _isLoading = false);
      }
      // If verification fails due to network/API error, treat as failure
      _handlePaymentResult(false);
    }
  }

  Future<void> _initializeServices() async {
    try {
      final configService = ConfigService(FirebaseFirestore.instance);
      await configService.initialize(); // Await fetching config from Firestore

      _apiService = ApiService(
        Dio(),
        FirebaseAuthService(),
        configService,
      );
      _paymentService = PaymentService(_apiService!);

      if (mounted) {
        setState(() {
          _isServicesInitialized = true;
        });
      }
      _logger.i('Services initialized successfully with base URL: ${configService.baseUrl}');
    } catch (e) {
      _logger.e('Failed to initialize services: $e');
      // Handle critical initialization failure, e.g., show error and close screen
      if (mounted) {
        _handlePaymentResult(false);
      }
    }
  }

  Future<void> _handlePaymentFailure() async {
    try {
      // Delete all orders
      await _paymentService!.deleteOrder();

      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (Route<dynamic> route) => false, // Remove all previous routes
        );

        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed, try again'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error handling payment failure: $e');
      // Fallback: just navigate to main screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main',
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _timeoutTimer?.cancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isProcessing
                ? null
                : () {
                    _logger.i('User manually closed payment screen');
                    _handlePaymentResult(false);
                  },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Processing payment...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _logger.d('Disposing PaymentWebViewScreen');
    super.dispose();
  }
}
