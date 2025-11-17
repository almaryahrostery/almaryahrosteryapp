import 'package:flutter/material.dart';
import '../models/tracking_model.dart';

/// Horizontal progress timeline showing order status steps
class OrderStatusProgress extends StatefulWidget {
  final LiveOrderTracking tracking;

  const OrderStatusProgress({super.key, required this.tracking});

  @override
  State<OrderStatusProgress> createState() => _OrderStatusProgressState();
}

class _OrderStatusProgressState extends State<OrderStatusProgress>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;

  final List<_ProgressStep> _steps = [
    _ProgressStep(
      icon: Icons.check_circle,
      label: 'Accepted',
      status: OrderStatus.acceptedByStaff,
    ),
    _ProgressStep(
      icon: Icons.restaurant,
      label: 'Preparing',
      status: OrderStatus.preparing,
    ),
    _ProgressStep(
      icon: Icons.inventory,
      label: 'Ready',
      status: OrderStatus.readyForHandover,
    ),
    _ProgressStep(
      icon: Icons.local_shipping,
      label: 'Picked Up',
      status: OrderStatus.pickedByDriver,
    ),
    _ProgressStep(
      icon: Icons.directions_car,
      label: 'On the Way',
      status: OrderStatus.onTheWay,
    ),
    _ProgressStep(
      icon: Icons.location_on,
      label: 'Arriving',
      status: OrderStatus.arriving,
    ),
    _ProgressStep(
      icon: Icons.done_all,
      label: 'Delivered',
      status: OrderStatus.delivered,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      _steps.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
    }).toList();

    _updateAnimations();
  }

  @override
  void didUpdateWidget(OrderStatusProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracking.status != widget.tracking.status) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    final currentProgress = widget.tracking.status.progressValue;

    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].status.progressValue <= currentProgress) {
        _controllers[i].forward();
      } else {
        _controllers[i].reverse();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final currentProgress = widget.tracking.status.progressValue;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_steps.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    // Connector line
                    final stepIndex = index ~/ 2;
                    final isCompleted =
                        _steps[stepIndex].status.progressValue <
                        currentProgress;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 40,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted ? primaryColor : Colors.grey[300],
                    );
                  } else {
                    // Step indicator
                    final stepIndex = index ~/ 2;
                    return _buildStep(
                      _steps[stepIndex],
                      stepIndex,
                      currentProgress,
                      primaryColor,
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    _ProgressStep step,
    int index,
    int currentProgress,
    Color primaryColor,
  ) {
    final isCompleted = step.status.progressValue <= currentProgress;
    final isCurrent = step.status.progressValue == currentProgress;

    return ScaleTransition(
      scale: _scaleAnimations[index],
      child: FadeTransition(
        opacity: _opacityAnimations[index],
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? primaryColor : Colors.grey[300],
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                step.icon,
                color: isCompleted ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                step.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? primaryColor : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStep {
  final IconData icon;
  final String label;
  final OrderStatus status;

  const _ProgressStep({
    required this.icon,
    required this.label,
    required this.status,
  });
}
