import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tracking_model.dart';

/// Order details card showing staff, order ID, and delivery address
class OrderDetailsCard extends StatelessWidget {
  final LiveOrderTracking tracking;
  final VoidCallback? onAddInstructions;

  const OrderDetailsCard({
    super.key,
    required this.tracking,
    this.onAddInstructions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${tracking.orderId.substring(0, 8)}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),

            // Staff info
            if (tracking.staff != null) ...[
              _buildInfoRow(
                icon: Icons.restaurant_menu,
                label: 'Preparing at',
                value: tracking.staff!.name,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 12),
            ],

            // Driver info (if assigned)
            if (tracking.driver != null) ...[
              _buildInfoRow(
                icon: Icons.person,
                label: 'Driver',
                value: tracking.driver!.name,
                primaryColor: primaryColor,
                trailing: IconButton(
                  icon: Icon(Icons.phone, color: primaryColor),
                  onPressed: () => _makePhoneCall(tracking.driver!.phone),
                  tooltip: 'Call driver',
                ),
              ),
              if (tracking.driver!.vehiclePlate != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    '${tracking.driver!.vehicleModel ?? 'Vehicle'} • ${tracking.driver!.vehiclePlate}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],

            // Delivery address
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Delivering to',
              value: tracking.address.fullAddress,
              primaryColor: primaryColor,
              trailing: TextButton(
                onPressed: onAddInstructions,
                child: Text('Edit', style: TextStyle(color: primaryColor)),
              ),
            ),

            // Delivery instructions (if available)
            if (tracking.address.deliveryInstructions != null &&
                tracking.address.deliveryInstructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tracking.address.deliveryInstructions!,
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (onAddInstructions != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onAddInstructions,
                icon: const Icon(Icons.add),
                label: const Text('Add delivery instructions'),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
