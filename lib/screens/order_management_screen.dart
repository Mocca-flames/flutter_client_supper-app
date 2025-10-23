import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/error_provider.dart'; // Import ErrorProvider

class OrderManagementScreen extends StatefulWidget {
  static const String routeName = '/order-management';

  const OrderManagementScreen({super.key});

  @override
  OrderManagementScreenState createState() => OrderManagementScreenState();
}

class OrderManagementScreenState extends State<OrderManagementScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    try {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent:
              _animationController!, // Assert non-null as it's in the same try block
          curve: Curves.easeInOut,
        ),
      );
    } catch (e, s) {
      if (kDebugMode) {
        print('[OrderManagementScreen] Error initializing animations: $e\n$s');
      }
      // _animationController and _fadeAnimation will remain null
    }

    // Fetch orders when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if the widget is still in the tree
        _loadOrders(context);
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose(); // Null-safe dispose
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders(BuildContext context, {bool refresh = false}) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final errorProvider = Provider.of<ErrorProvider>(
      context,
      listen: false,
    ); // Get ErrorProvider
    if (refresh) {
      if (kDebugMode) {
        print('[OrderManagementScreen] Refreshing orders...');
      }
      await orderProvider.refreshOrders();
    } else {
      if (orderProvider.orders.isEmpty || errorProvider.currentError != null) {
        // Use errorProvider
        if (kDebugMode) {
          print(
            '[OrderManagementScreen] Loading orders for the first time or after an error...',
          );
        }
        await orderProvider.getOrderHistory();
      } else {
        if (kDebugMode) {
          print(
            '[OrderManagementScreen] Orders already loaded, skipping fetch.',
          );
        }
      }
    }
    // Start animation only if controller was initialized and not already running
    if (_animationController?.isAnimating == false) {
      _animationController?.forward();
    } else if (_animationController != null &&
        _animationController?.value == 0.0) {
      _animationController?.forward();
    }
  }

  void _filterOrders() {
    if (kDebugMode) {
      print('[OrderManagementScreen] Filter orders action triggered.');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Filter Orders',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildFilterOption('All Orders', Icons.all_inclusive),
            _buildFilterOption('Delivered', Icons.check_circle),
            _buildFilterOption('In Progress', Icons.local_shipping),
            _buildFilterOption('Cancelled', Icons.cancel),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title filter applied')));
      },
    );
  }

  void _navigateToOrderDetails(BuildContext context, String orderId) {
    if (kDebugMode) {
      print(
        '[OrderManagementScreen] Navigating to details for order ID: $orderId',
      );
    }
    Navigator.of(context).pushNamed('/order-details', arguments: orderId);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in progress':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final errorProvider = Provider.of<ErrorProvider>(
      context,
    ); // Get ErrorProvider

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadOrders(context, refresh: true),
                child: _buildBody(
                  context,
                  orderProvider,
                  errorProvider,
                ), // Pass errorProvider
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Order Management',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _filterOrders,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search orders...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderProvider orderProvider,
    ErrorProvider errorProvider,
  ) {
    // Add ErrorProvider
    if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
      return _buildLoadingState();
    }

    if (errorProvider.currentError != null && orderProvider.orders.isEmpty) {
      // Use errorProvider
      return _buildErrorState(errorProvider.currentError!); // Use errorProvider
    }

    if (orderProvider.orders.isEmpty) {
      return _buildEmptyState();
    }

    final filteredOrders = orderProvider.orders
        .where((order) {
          if (_searchQuery.isEmpty) return true;
          return order.id.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) || // Use orderId
              order.getStatusText().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) || // Use getStatusText
              order.pickupAddress.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) || // Use pickupLocation.address
              order.dropoffAddress.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ); // Use dropoffLocation.address
        })
        .where((order) => order.getStatusText().toLowerCase() != 'cancelled')
        .toList(); // Exclude cancelled orders by default

    if (filteredOrders.isEmpty) {
      return _buildNoResultsState();
    }

    if (_fadeAnimation == null || _animationController == null) {
      // Fallback: render without fade animation if initialization failed
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredOrders.length,
        itemBuilder: (ctx, i) {
          final order = filteredOrders[i];
          return _buildOrderCard(order, i);
        },
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation!, // Assert non-null after check
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredOrders.length,
        itemBuilder: (ctx, i) {
          final order = filteredOrders[i];
          return _buildOrderCard(order, i);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your orders...',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadOrders(context, refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order history will appear here once you place your first order.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, int index) {
    final statusColor = _getStatusColor(order.getStatusText());
    final statusIcon = _getStatusIcon(order.getStatusText());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToOrderDetails(
            context,
            order.id,
          ), // Use id instead of orderId
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Removed orderType as it's not a direct property
                          // Text(
                          //   order.orderType.replaceAll('_', ' ').toUpperCase(),
                          //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          //     color: Colors.grey[600],
                          //     fontWeight: FontWeight.w500,
                          //   ),
                          // ),
                          Text(
                            'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}', // Use id instead of orderId
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor..withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.getStatusText().replaceAll('_', ' '),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLocationRow(
                  Icons.location_on_outlined,
                  'Pickup',
                  order
                      .pickupAddress, // Use pickupAddress instead of pickupLocation.address
                ),
                const SizedBox(height: 8),
                _buildLocationRow(
                  Icons.location_on,
                  'Dropoff',
                  order
                      .dropoffAddress, // Use dropoffAddress instead of dropoffLocation.address
                ),
                if (order.price != null) ...[
                  // Use price instead of totalAmount
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${order.price!.toStringAsFixed(2)}', // Use price instead of totalAmount
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/create-order',
                          arguments:
                              order, // Pass the entire order object for editing
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
