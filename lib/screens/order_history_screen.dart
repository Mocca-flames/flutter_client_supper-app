import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:molo/providers/order_provider.dart';
import 'package:molo/models/order_model.dart';
import 'package:molo/widgets/order_status_card.dart';
import 'package:molo/screens/order_details_screen.dart';
import 'package:molo/screens/order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load orders on first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      provider.getOrderHistory(forceRefresh: true);
    });
  }

  Future<void> _refresh(BuildContext context) async {
    await Provider.of<OrderProvider>(context, listen: false)
        .getOrderHistory(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        // Loading state
        if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your orders...'),
                ],
              ),
            ),
          );
        }

        // Error state
        if (orderProvider.hasError && orderProvider.orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    orderProvider.lastError ?? 'Failed to load orders.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _refresh(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        // Empty state
        if (orderProvider.orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Icon(Icons.inbox, size: 72, color: Colors.grey),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(height: 6),
                Center(
                  child: Text(
                    'When you place orders, they will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        // List of orders
        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: orderProvider.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final order = orderProvider.orders[index];
              return Column(
                children: [
                  OrderStatusCard(order: order),
                  _buildActionsRow(context, orderProvider, order),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionsRow(
    BuildContext context,
    OrderProvider orderProvider,
    OrderModel order,
  ) {
    final bool canTrack = order.isActive();
    final bool canCancel =
        order.status == OrderStatus.pending || order.status == OrderStatus.accepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // View Details
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(orderId: order.id),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Details'),
            ),
          ),
          const SizedBox(width: 8),
          // Track
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canTrack
                  ? () async {
                      await orderProvider.trackOrder(order.id);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(orderId: order.id),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.my_location),
              label: const Text('Track'),
            ),
          ),
          const SizedBox(width: 8),
          // Cancel
          IconButton.filledTonal(
            onPressed: canCancel
                ? () async {
                    final confirm = await _confirmCancel(context);
                    if (confirm != true) return;
                    final ok = await orderProvider.cancelOrder(order.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Order cancelled' : 'Failed to cancel order',
                        ),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.close),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
  }
}
