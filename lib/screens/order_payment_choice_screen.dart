import 'package:flutter/material.dart';
import 'package:molo/screens/main_screen.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../models/delivery_estimate_model.dart';
import '../providers/order_provider.dart';
import '../providers/map_provider.dart';
import '../payment/payment_handler.dart';
import '../widgets/payment_animation.dart';
import '../widgets/order_route_map_widget.dart';

class OrderPaymentChoiceScreen extends StatefulWidget {
  static const String routeName = '/order-payment-choice';
  final String userId;
  final LocationModel pickupLocation;
  final LocationModel dropoffLocation;
  final Map<String, dynamic> orderData;

  const OrderPaymentChoiceScreen({
    super.key,
    required this.userId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.orderData,
  });

  @override
  State<OrderPaymentChoiceScreen> createState() =>
      _OrderPaymentChoiceScreenState();
}

class _OrderPaymentChoiceScreenState extends State<OrderPaymentChoiceScreen> {
  bool _isLoading = false;
  bool _isEstimating = true;
  DeliveryEstimateModel? _estimate;
  String? _estimateError;
  bool _isInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    _estimateOrder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Payment', style: TextStyle(color: Colors.black)),
            elevation: 0,
            backgroundColor: const Color.fromARGB(0, 0, 0, 0),
            foregroundColor: Colors.black,
            surfaceTintColor: Colors.black,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MainScreen()),
                ),
                icon: Icon(Icons.close, color: Colors.black87),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Map Section
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isInfoExpanded) {
                        setState(() {
                          _isInfoExpanded = false;
                        });
                      }
                    },
                    child: Stack(
                      children: [
                        const OrderRouteMapWidget(),

                        // Delivery Info Overlay - Collapsible
                        if (_estimate != null && !_isEstimating)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isInfoExpanded = !_isInfoExpanded;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                padding: EdgeInsets.all(
                                  _isInfoExpanded ? 16 : 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    _isInfoExpanded ? 16 : 28,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _isInfoExpanded
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (widget
                                                      .orderData['distance_km'] !=
                                                  null)
                                                _buildInfoItem(
                                                  Icons.route,
                                                  '${widget.orderData['distance_km']} km',
                                                  'Distance',
                                                ),
                                              if (_estimate!
                                                      .estimate
                                                      .estimatedDurationMinutes !=
                                                  null) ...[
                                                const SizedBox(width: 24),
                                                _buildInfoItem(
                                                  Icons.access_time,
                                                  '${_estimate!.estimate.estimatedDurationMinutes} min',
                                                  'Duration',
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      )
                                    : const Icon(
                                        Icons.access_time_outlined,
                                        color: Color.fromARGB(255, 0, 184, 40),
                                        size: 24,
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Payment Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading or Error State
                      if (_isEstimating)
                        _buildLoadingState(context)
                      else if (_estimateError != null)
                        _buildErrorState(context)
                      else if (_estimate != null) ...[
                        // Total Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${_estimate!.estimate.currency} ${_estimate!.estimate.total.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Payment Method Label
                        Text(
                          'Select Payment Method',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Online Payment Button
                        ElevatedButton(
                          onPressed: () => _payOnline(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 0,
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Pay Online',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Cash Payment Button
                        OutlinedButton(
                          onPressed: () => _payWithCash(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(
                              color: colorScheme.outline,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: colorScheme.onSurface,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Pay with Cash',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(child: PaymentAnimation()),
          ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Calculating price...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to calculate price',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _estimateError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _estimateOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _estimateOrder() async {
    setState(() {
      _isEstimating = true;
      _estimateError = null;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final estimate = await orderProvider.estimateOrder(
        pickupLocation: widget.pickupLocation,
        dropoffLocation: widget.dropoffLocation,
        orderData: widget.orderData,
      );

      if (mounted) {
        setState(() {
          _estimate = estimate;
          _isEstimating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estimateError = 'Failed to get estimate: $e';
          _isEstimating = false;
        });
      }
    }
  }

  void _initializeMap() {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    mapProvider.setOrderLocations(
      widget.pickupLocation,
      widget.dropoffLocation,
    );
    mapProvider.calculateRoute(widget.pickupLocation, widget.dropoffLocation);
  }

  void _payOnline(BuildContext context) async {
    if (_estimate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for price calculation'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      final onlineOrderData = Map<String, dynamic>.from(widget.orderData);
      onlineOrderData['payment_method'] = 'credit_card';
      onlineOrderData['client_id'] = widget.userId;
      onlineOrderData['pickup_address'] = widget.pickupLocation.address ?? '';
      onlineOrderData['dropoff_address'] = widget.dropoffLocation.address ?? '';

      final createdOrder = await orderProvider.createOrder(onlineOrderData);
      if (createdOrder != null && context.mounted) {
        PaymentHandler.navigateToPayment(
          context: context,
          orderId: createdOrder.id,
          amount: _estimate!.estimate.total,
          currency: _estimate!.estimate.currency,
          userId: widget.userId,
          pickupLocation: widget.pickupLocation,
          dropoffLocation: widget.dropoffLocation,
          order: createdOrder,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _payWithCash(BuildContext context) async {
    if (_estimate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for price calculation'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final cashOrderData = Map<String, dynamic>.from(widget.orderData);
      cashOrderData['payment_method'] = 'cash';
      cashOrderData['client_id'] = widget.userId;
      cashOrderData['pickup_address'] = widget.pickupLocation.address ?? '';
      cashOrderData['dropoff_address'] = widget.dropoffLocation.address ?? '';

      final createdOrder = await orderProvider.createOrder(cashOrderData);
      if (createdOrder != null && context.mounted) {
        PaymentHandler.navigateToCashPayment(
          context: context,
          pickupLocation: widget.pickupLocation,
          dropoffLocation: widget.dropoffLocation,
          order: createdOrder,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
