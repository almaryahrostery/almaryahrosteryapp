import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tracking_service.dart';
import '../models/tracking_model.dart';
import '../widgets/tracking_map.dart';
import '../widgets/arrival_estimate_card.dart';
import '../widgets/order_status_progress.dart';
import '../widgets/order_details_card.dart';
import '../widgets/receiver_details.dart';

/// Main tracking page for live order tracking
class TrackingPage extends StatefulWidget {
  final String orderId;

  const TrackingPage({super.key, required this.orderId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late TrackingService _trackingService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _trackingService = TrackingService();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      await _trackingService.initializeTracking(widget.orderId);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tracking: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _initializeTracking,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TrackingService>.value(
      value: _trackingService,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Track Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Connection status indicator
            Consumer<TrackingService>(
              builder: (context, service, child) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: service.isConnected ? Colors.green : Colors.red,
                        boxShadow: service.isConnected
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<TrackingService>(
          builder: (context, service, child) {
            if (service.isLoading && !_isInitialized) {
              return _buildLoadingState();
            }

            if (service.error != null && service.currentTracking == null) {
              return _buildErrorState(service.error!);
            }

            if (service.currentTracking == null) {
              return _buildLoadingState();
            }

            return _buildTrackingContent(service.currentTracking!);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading tracking information...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Unable to load tracking',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeTracking,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent(LiveOrderTracking tracking) {
    return RefreshIndicator(
      onRefresh: () async {
        await _trackingService.refresh();
      },
      color: Theme.of(context).primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Live Map
            SizedBox(height: 300, child: TrackingMapWidget(tracking: tracking)),

            const SizedBox(height: 16),

            // Scrollable content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Arrival Estimate Card
                  ArrivalEstimateCard(tracking: tracking),

                  const SizedBox(height: 16),

                  // Order Status Progress
                  OrderStatusProgress(tracking: tracking),

                  const SizedBox(height: 16),

                  // Order Details Card
                  OrderDetailsCard(
                    tracking: tracking,
                    onAddInstructions: () {
                      _showAddInstructionsDialog(context);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Receiver Details
                  ReceiverDetails(
                    address: tracking.address,
                    onChangeReceiver: () {
                      _showChangeReceiverDialog(context);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Debug controls (only in debug mode)
                  if (const bool.fromEnvironment('dart.vm.product') == false)
                    _buildDebugControls(tracking),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugControls(LiveOrderTracking tracking) {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Colors.amber[800]),
                const SizedBox(width: 8),
                Text(
                  'Debug Controls',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDebugButton('Simulate Movement', () {
                  _trackingService.simulateDriverMovement(tracking.orderId);
                }),
                _buildDebugButton('Preparing', () {
                  _trackingService.updateOrderStatus(
                    tracking.orderId,
                    'preparing',
                  );
                }),
                _buildDebugButton('Picked Up', () {
                  _trackingService.updateOrderStatus(
                    tracking.orderId,
                    'picked_by_driver',
                  );
                }),
                _buildDebugButton('On the Way', () {
                  _trackingService.updateOrderStatus(
                    tracking.orderId,
                    'on_the_way',
                  );
                }),
                _buildDebugButton('Delivered', () {
                  _trackingService.updateOrderStatus(
                    tracking.orderId,
                    'delivered',
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  void _showAddInstructionsDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Delivery Instructions'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Ring the doorbell twice',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Update delivery instructions via API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delivery instructions updated')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeReceiverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Receiver'),
        content: const Text(
          'Select a different address or receiver for this delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to address selection
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Select Address'),
          ),
        ],
      ),
    );
  }
}
