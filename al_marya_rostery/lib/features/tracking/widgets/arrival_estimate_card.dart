import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tracking_model.dart';

/// Arrival estimate card showing ETA and status
class ArrivalEstimateCard extends StatelessWidget {
  final LiveOrderTracking tracking;

  const ArrivalEstimateCard({super.key, required this.tracking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final eta = tracking.eta;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(), size: 16, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        eta?.getStatusLabel() ?? 'Calculating',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (eta != null)
                  Text(
                    '${eta.getMinutesRemaining()} min',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ETA range
            if (eta != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated Arrival',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatETARange(eta),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Calculating arrival time...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Divider
            Divider(color: Colors.grey[300]),

            const SizedBox(height: 16),

            // Status message
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tracking.status.userMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            // Distance indicator (if available)
            if (eta?.distanceMeters != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.navigation, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatDistance(eta!.distanceMeters!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    if (tracking.eta == null) return Icons.hourglass_empty;

    final label = tracking.eta!.getStatusLabel();
    switch (label) {
      case 'On Time':
        return Icons.check_circle;
      case 'Slight delay':
        return Icons.schedule;
      case 'Delayed':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _formatETARange(ETAModel eta) {
    final startTime = DateFormat('h:mm a').format(eta.start);
    final endTime = DateFormat('h:mm a').format(eta.end);

    // If same hour, show cleaner format
    if (eta.start.hour == eta.end.hour) {
      return 'Between ${DateFormat('h:mm').format(eta.start)} - $endTime';
    }

    return 'Between $startTime - $endTime';
  }

  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m away';
    } else {
      final km = (meters / 1000).toStringAsFixed(1);
      return '$km km away';
    }
  }
}
