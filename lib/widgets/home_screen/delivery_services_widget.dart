import 'package:flutter/material.dart';
import 'package:molo/models/delivery_service_model.dart';

class DeliveryServicesWidget extends StatelessWidget {
  static const List<String> _disabledServiceIds = [
    'parcel_delivery',
    'food_delivery',
  ];

  final List<DeliveryService> deliveryServices;
  final Animation<double> fadeAnimation;
  final Function(DeliveryService) onDeliveryServiceSelected;
  final String? title;

  final int crossAxisCount;
  final double childAspectRatio;

  const DeliveryServicesWidget({
    super.key,
    required this.deliveryServices,
    required this.fadeAnimation,
    required this.onDeliveryServiceSelected,
    this.title = "Delivery Services",

    this.crossAxisCount = 2,
    this.childAspectRatio = 1.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: deliveryServices.length,
            itemBuilder: (context, index) {
              final service = deliveryServices[index];
              return FadeTransition(
                opacity: fadeAnimation,
                child: _buildServiceCard(context, service),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, DeliveryService service) {
    final bool isDisabled = _disabledServiceIds.contains(service.id);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: isDisabled
              ? () => _showComingSoonSnackBar(context)
              : () => onDeliveryServiceSelected(service),
          borderRadius: BorderRadius.circular(16.0),
          splashColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PNG Icon - centered and larger
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: _buildServiceIcon(context, service),
                  ),
                ),
                const SizedBox(height: 12),
                // Service name
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Service subtitle
                Expanded(
                  child: Text(
                    service.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 1),
                // Bottom action indicator
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon(BuildContext context, DeliveryService service) {
    // Prioritize PNG asset path
    if (service.imageAssetPath != null) {
      return Image.asset(
        service.imageAssetPath!,
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default icon if image fails to load
          return Icon(
            Icons.local_shipping,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          );
        },
      );
    }

    // Fallback to icon if available
    return Icon(
      service.icon,
      size: 42,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "We're cooking up something great! This service will be available soon.",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
