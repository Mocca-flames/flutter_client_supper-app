import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../providers/error_provider.dart'; // Import ErrorProvider

class OrderDetailsScreen extends StatefulWidget {
  static const String routeName = '/order-details';
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails(context);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails(
    BuildContext context, {
    bool refresh = false,
  }) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final errorProvider = Provider.of<ErrorProvider>(context, listen: false);
    if (kDebugMode) {
      print(
        '[OrderDetailsScreen] Loading details for order ID: ${widget.orderId}',
      );
    }

    if (refresh ||
        orderProvider.currentOrder?.id != widget.orderId ||
        errorProvider.currentError != null) {
      await orderProvider.getOrderById(widget.orderId);
      if (mounted) {
        _fadeController.forward();
      }
    }
  }

  Future<void> _trackOrder(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.currentOrder;

    if (order == null) {
      _showSnackBar('Order details not available for tracking.');
      return;
    }

    if (!order.isActive()) {
      _showSnackBar('This order cannot be tracked as it\'s no longer active.');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final started = await orderProvider.trackOrder(order.id);
      if (!started) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Failed to start tracking');
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/order-tracking',
          arguments: {
            'orderId': order.id,
            'pickupAddress': order.pickupAddress,
            'dropoffAddress': order.dropoffAddress,
            // 'driverId': order.driverId, // DriverId is not in OrderModel
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to start tracking: ${e.toString()}');
      }
    }
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.currentOrder;

    if (order == null) {
      _showSnackBar('Order details not available to cancel.');
      return;
    }

    // Assuming an order can be cancelled if its status is 'pending' or 'accepted'
    final bool canBeCancelled =
        order.status == OrderStatus.pending ||
        order.status == OrderStatus.accepted;

    if (!canBeCancelled) {
      _showSnackBar('This order cannot be cancelled at this time.');
      return;
    }

    final confirmed = await _showCancellationDialog();
    if (!confirmed) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final ok = await orderProvider.cancelOrder(order.id);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(
          ok ? 'Order cancelled successfully' : 'Failed to cancel order',
          isSuccess: ok,
        );
        if (ok) {
          await _loadOrderDetails(context, refresh: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Failed to cancel order: ${e.toString()}');
      }
    }
  }

  Future<bool> _showCancellationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Cancel Order'),
              ],
            ),
            content: const Text(
              'Are you sure you want to cancel this order? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep Order'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel Order'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final errorProvider = Provider.of<ErrorProvider>(context);
    final OrderModel? order = orderProvider.currentOrder?.id == widget.orderId
        ? orderProvider.currentOrder
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Order Details',
            style: TextStyle(fontSize: 20, color: Colors.black87),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadOrderDetails(context, refresh: true),
        child: _buildBody(context, orderProvider, order, errorProvider),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderProvider orderProvider,
    OrderModel? order,
    ErrorProvider errorProvider,
  ) {
    if (orderProvider.isLoading && order == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading order details...'),
          ],
        ),
      );
    }

    if (errorProvider.currentError != null && order == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Unable to load order details',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorProvider.currentError!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadOrderDetails(context, refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (order == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Order not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text('Pull down to refresh'),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildStatusCard(order),
            _buildRouteCard(order),
            _buildPricingCard(order),
            _buildActionButtons(order),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(order.status),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.getStatusText(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Removed orderType as it's not in OrderModel
                    // Text(
                    //   _getOrderTypeText(order.orderType),
                    //   style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    // ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order placed',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAddressRow(
            icon: Icons.radio_button_checked,
            iconColor: Colors.green,
            label: 'Pickup',
            address: order.pickupAddress,
          ),
          Container(
            margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            height: 30,
            width: 2,
            color: Colors.grey[300],
          ),
          _buildAddressRow(
            icon: Icons.location_on,
            iconColor: Colors.red,
            label: 'Dropoff',
            address: order.dropoffAddress,
          ),
          // Removed distanceKm as it's not in OrderModel
          // if (order.distanceKm != null) ...[
          //   const SizedBox(height: 16),
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(20),
          //     ),
          //     child: Text(
          //       '${order.distanceKm!.toStringAsFixed(1)} km',
          //       style: TextStyle(
          //         color: Theme.of(context).colorScheme.primary,
          //         fontSize: 12,
          //         fontWeight: FontWeight.w500,
          //       ),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            order.price != null ? '\$${order.price!.toStringAsFixed(2)}' : '—',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    if (!order.isActive()) return const SizedBox.shrink();

    // Assuming an order can be cancelled if its status is 'pending' or 'accepted'
    final bool canBeCancelled =
        order.status == OrderStatus.pending ||
        order.status == OrderStatus.accepted;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 80,
            child: ElevatedButton.icon(
              onPressed: () => _trackOrder(context),
              icon: const Icon(Icons.my_location),
              label: const Text('Track Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 20,
            child: OutlinedButton(
              onPressed: canBeCancelled ? () => _cancelOrder(context) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.inProgress:
        return Icons.local_shipping;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  // Removed _getOrderTypeText as orderType is not in OrderModel
  // String _getOrderTypeText(String orderType) {
  //   switch (orderType) {
  //     case 'patient_transport':
  //       return 'Patient Transport';
  //     case 'medical_product':
  //       return 'Medical Product Delivery';
  //     case 'emergency':
  //       return 'Emergency Transport';
  //     default:
  //       return orderType.replaceAll('_', ' ').toUpperCase();
  //   }
  // }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
