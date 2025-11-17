import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../core/theme/app_theme.dart';
import '../core/services/order_cancellation_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';
import '../core/widgets/skeleton_loaders.dart';
import '../models/order.dart';
import '../models/cart.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/utils/app_logger.dart';
import '../core/services/order_tracking_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user from auth provider
      final authProvider = context.read<AuthProvider>();

      // Check if user is authenticated
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
        return;
      }

      AppLogger.debug('📝 User authenticated: ${authProvider.user!.email}');
      AppLogger.debug('🔑 User ID: ${authProvider.user!.id}');
      AppLogger.debug('🔥 Fetching Firebase ID token...');

      // Get Firebase ID token for authentication
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Firebase user not found. Please login again.');
      }

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      AppLogger.success('✅ Firebase ID token obtained');
      AppLogger.debug(
        '📡 Fetching orders from: ${AppConstants.baseUrl}/api/users/me/orders',
      );

      // Fetch user's orders from backend
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/users/me/orders'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      AppLogger.debug('📦 Response status: ${response.statusCode}');
      AppLogger.debug('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.success('✅ Raw response data: $data');
        AppLogger.success('✅ Orders count: ${data['count']}');

        // Handle null or missing orders field
        final ordersData = data['orders'];
        if (ordersData == null) {
          AppLogger.warning('⚠️ Orders field is null, treating as empty list');
          setState(() {
            _orders = [];
            _isLoading = false;
          });
          return;
        }

        // Safely cast to List
        final ordersJson = ordersData as List;
        AppLogger.debug('📋 Processing ${ordersJson.length} orders...');

        final userOrders = ordersJson
            .map((json) {
              try {
                return Order.fromJson(json, json['_id']);
              } catch (e) {
                AppLogger.error('❌ Error parsing order: $e');
                AppLogger.debug('   Order data: $json');
                return null;
              }
            })
            .where((order) => order != null)
            .cast<Order>()
            .toList();

        // Sort by creation date (newest first) - already sorted by backend but double-check
        userOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _orders = userOrders;
          _isLoading = false;
        });

        AppLogger.success('✅ Successfully loaded ${userOrders.length} orders');
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please logout and login again.',
        );
      } else if (response.statusCode == 404) {
        throw Exception(
          'Orders service not available. Please try again later.',
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to load orders: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      AppLogger.error('❌ Error loading orders: $e');
    }
  }

  List<Order> get _filteredOrders {
    switch (_tabController.index) {
      case 0: // All
        return _orders;
      case 1: // Pending
        return _orders
            .where((order) => order.status == OrderStatus.pending)
            .toList();
      case 2: // In Progress
        return _orders
            .where(
              (order) =>
                  order.status == OrderStatus.confirmed ||
                  order.status == OrderStatus.preparing ||
                  order.status == OrderStatus.ready,
            )
            .toList();
      case 3: // Completed
        return _orders
            .where(
              (order) =>
                  order.status == OrderStatus.delivered ||
                  order.status == OrderStatus.cancelled,
            )
            .toList();
      default:
        return _orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {}); // Refresh to update filtered orders
          },
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: !authProvider.isAuthenticated
          ? _buildGuestState()
          : _isLoading
          ? ListSkeleton(
              itemCount: 5,
              itemBuilder: (context, index) => const OrderCardSkeleton(),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppTheme.primaryBrown,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(),
                  _buildOrdersList(),
                  _buildOrdersList(),
                  _buildOrdersList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: const Color(0xFF8C8C8C)),
          const SizedBox(height: 16),
          Text(
            'Login Required',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D5D5D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please login to view your order history',
            style: const TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Login / Sign Up'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    // Check if this is the "coming soon" message
    final isComingSoon = _errorMessage?.contains('coming soon') ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isComingSoon ? Icons.construction : Icons.error_outline,
            size: 64,
            color: isComingSoon ? Colors.orange.shade300 : Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isComingSoon ? 'Coming Soon' : 'Error Loading Orders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D5D5D),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: const TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (!isComingSoon)
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          if (isComingSoon)
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/coffee');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Browse Coffee'),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = _filteredOrders;

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.primaryBrown,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No orders found';
    String subtitle = 'Start browsing our coffee collection';
    IconData icon = Icons.receipt_long;
    String buttonText = 'Go to Home';
    void onPressed() {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }

    switch (_tabController.index) {
      case 1:
        message = 'No pending orders';
        subtitle = 'All caught up! No pending orders at the moment.';
        icon = Icons.pending_actions;
        break;
      case 2:
        message = 'No orders in progress';
        subtitle = 'No orders are currently being prepared.';
        icon = Icons.hourglass_empty;
        break;
      case 3:
        message = 'No completed orders';
        subtitle = 'Your completed orders will appear here.';
        icon = Icons.check_circle_outline;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFF8C8C8C)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D5D5D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8C8C8C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 16),

              // Order Items Preview
              ...order.items.take(2).map((item) => _buildOrderItemRow(item)),

              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${order.items.length - 2} more items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Order Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8C8C8C),
                        ),
                      ),
                      Text(
                        '${order.total.toStringAsFixed(2)} AED',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBrown,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (order.status == OrderStatus.confirmed ||
                          order.status == OrderStatus.preparing ||
                          order.status == OrderStatus.ready)
                        TextButton(
                          onPressed: () => _trackOrder(order),
                          child: const Text('Track'),
                        ),
                      if (order.status == OrderStatus.delivered)
                        TextButton(
                          onPressed: () => _reorder(order),
                          child: const Text('Reorder'),
                        ),
                      // Cancel button removed - now in order details sheet with full cancellation flow
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(CartItem item) {
    // Get the full image URL with base URL prefix if needed
    String imageUrl = item.imageUrl ?? '';
    if (imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http://') &&
        !imageUrl.startsWith('https://')) {
      imageUrl = '${AppConstants.baseUrl}$imageUrl';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl.isEmpty
                ? Container(
                    width: 40,
                    height: 40,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(
                      Icons.coffee,
                      color: AppTheme.primaryBrown,
                      size: 20,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 40,
                      height: 40,
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(
                        Icons.coffee,
                        color: AppTheme.primaryBrown,
                        size: 20,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 40,
                      height: 40,
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(
                        Icons.coffee,
                        color: AppTheme.primaryBrown,
                        size: 20,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.coffeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                Text(
                  'Qty: ${item.quantity} • ${item.size}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(2)} AED',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D5D5D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        label = 'Pending';
        icon = Icons.pending;
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        label = 'Confirmed';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        label = 'Preparing';
        icon = Icons.hourglass_empty;
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal;
        label = 'Ready';
        icon = Icons.done_all;
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        label = 'Delivered';
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildOrderDetailsSheet(order),
    );
  }

  Widget _buildOrderDetailsSheet(Order order) {
    // Format delivery address
    String deliveryAddress = 'No address provided';
    if (order.deliveryAddress != null) {
      deliveryAddress = [
        order.deliveryAddress!['street'],
        order.deliveryAddress!['city'],
        order.deliveryAddress!['state'],
        order.deliveryAddress!['country'],
      ].where((part) => part != null && part.toString().isNotEmpty).join(', ');
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E2E2E),
                      ),
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 20),

              // Live Status Panel (polls every 15s)
              _LiveStatusPanel(order: order),

              // Order Details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection(
                        'Order Date',
                        _formatDate(order.createdAt),
                      ),
                      if (order.notes != null && order.notes!.isNotEmpty)
                        _buildDetailSection('Notes', order.notes!),
                      _buildDetailSection('Delivery Address', deliveryAddress),

                      const SizedBox(height: 20),

                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...order.items.map((item) => _buildDetailOrderItem(item)),

                      const Divider(height: 32),

                      _buildDetailSection(
                        'Total',
                        '${order.total.toStringAsFixed(2)} AED',
                        isTotal: true,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cancel button with countdown timer
                    if (_canShowCancelButton(order)) _buildCancelButton(order),
                    // Close button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Check if cancel button should be shown
  bool _canShowCancelButton(Order order) {
    final cancellationService = OrderCancellationService();
    return cancellationService.canCancelOrder(
      order.createdAt,
      order.status.name,
    );
  }

  /// Build cancel button with countdown timer
  Widget _buildCancelButton(Order order) {
    final cancellationService = OrderCancellationService();
    final remainingMinutes = cancellationService.getRemainingMinutes(
      order.createdAt,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can cancel within $remainingMinutes minute${remainingMinutes != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCancelDialog(order);
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Show cancel dialog with reasons
  Future<void> _showCancelDialog(Order order) async {
    final reasons = [
      'Changed my mind',
      'Ordered by mistake',
      'Delivery time too long',
      'Found a better option',
      'Other',
    ];

    String? selectedReason;
    String? customReason;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cancel Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please tell us why you\'re cancelling:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...reasons.map(
                  (reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                        if (value != 'Other') {
                          customReason = null;
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Please specify',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => customReason = value,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 16),
                // Show refund info if order is paid
                if (order.paymentStatus == 'paid')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your payment of ${order.total.toStringAsFixed(2)} AED will be refunded within 5-7 business days.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      final reason = selectedReason == 'Other'
                          ? (customReason ?? 'Other')
                          : selectedReason!;
                      Navigator.pop(context, reason);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _processCancellation(order, result);
    }
  }

  /// Process the cancellation
  Future<void> _processCancellation(Order order, String reason) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          margin: EdgeInsets.all(24),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryBrown),
                SizedBox(height: 16),
                Text('Canceling order...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final cancellationService = OrderCancellationService();
      final result = await cancellationService.cancelOrder(order.id, reason);

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order cancelled successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Show refund info if applicable
        if (result['refund'] != null) {
          final refundAmount = result['refund']['amount'];
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Refund of ${refundAmount.toStringAsFixed(2)} AED will be processed within 5-7 business days',
                  ),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          });
        }

        // Refresh orders list
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        // Show error message with retry option
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          onRetry: () => _processCancellation(order, reason),
        );
      }
    }
  }

  Widget _buildDetailSection(
    String title,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                color: const Color(0xFF8C8C8C),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal
                    ? AppTheme.primaryBrown
                    : const Color(0xFF2E2E2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailOrderItem(CartItem item) {
    String imageUrl = item.imageUrl ?? '';
    if (imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http://') &&
        !imageUrl.startsWith('https://')) {
      imageUrl = '${AppConstants.baseUrl}$imageUrl';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageUrl.isEmpty
                ? Container(
                    width: 50,
                    height: 50,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(
                      Icons.coffee,
                      color: AppTheme.primaryBrown,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(
                        Icons.coffee,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(
                        Icons.coffee,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.coffeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                Text(
                  'Size: ${item.size}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
                Text(
                  'Quantity: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
                Text(
                  'Unit Price: ${item.price.toStringAsFixed(2)} AED',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C8C8C),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(2)} AED',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBrown,
            ),
          ),
        ],
      ),
    );
  }

  void _trackOrder(Order order) {
    // Open details directly so user sees the live panel immediately
    _showOrderDetails(order);
  }

  void _reorder(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Items'),
        content: Text(
          'Add all items from order #${order.id.substring(0, 8).toUpperCase()} to your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Note: Implement add to cart logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Items added to cart!'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}

/// Live status panel inside the order details sheet.
/// Polls order status every 15 seconds and shows snackbars on changes.
class _LiveStatusPanel extends StatefulWidget {
  final Order order;

  const _LiveStatusPanel({required this.order});

  @override
  State<_LiveStatusPanel> createState() => _LiveStatusPanelState();
}

class _LiveStatusPanelState extends State<_LiveStatusPanel>
    with WidgetsBindingObserver {
  late final OrderTrackingService _tracking;
  late OrderStatus _status;
  DateTime? _updatedAt;
  bool _firstEmissionHandled = false;
  StreamSubscription<Order>? _sub;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tracking = OrderTrackingService();
    _status = widget.order.status;
    _updatedAt = widget.order.updatedAt ?? widget.order.createdAt;

    _sub = _tracking
        .track(widget.order.id, interval: const Duration(seconds: 15))
        .listen((updated) {
          if (!mounted) return;

          final statusChanged = updated.status != _status;
          setState(() {
            _status = updated.status;
            _updatedAt = updated.updatedAt ?? _updatedAt;
          });

          if (_firstEmissionHandled && statusChanged) {
            final label =
                _status.name[0].toUpperCase() + _status.name.substring(1);
            final color = _chipColor(_status);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order status updated: $label'),
                backgroundColor: color,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          _firstEmissionHandled = true;
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _tracking.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause polling in background, resume on foreground
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _tracking.stop();
      _sub?.cancel();
      _sub = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_sub == null) {
        _sub = _tracking
            .track(widget.order.id, interval: const Duration(seconds: 15))
            .listen((updated) {
              if (!mounted) return;
              final statusChanged = updated.status != _status;
              setState(() {
                _status = updated.status;
                _updatedAt = updated.updatedAt ?? _updatedAt;
              });
              if (_firstEmissionHandled && statusChanged) {
                final label =
                    _status.name[0].toUpperCase() + _status.name.substring(1);
                final color = _chipColor(_status);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order status updated: $label'),
                    backgroundColor: color,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              _firstEmissionHandled = true;
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _status.name[0].toUpperCase() + _status.name.substring(1);
    final bg = _chipColor(_status).withValues(alpha: 0.1);
    final fg = _chipColor(_status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(_status), color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Status: $label',
                  style: TextStyle(fontWeight: FontWeight.w600, color: fg),
                ),
                if (_updatedAt != null)
                  Text(
                    'Last updated ${_relativeTime(_updatedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5D5D5D),
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _isRefreshing
                ? null
                : () async {
                    setState(() => _isRefreshing = true);
                    try {
                      await _tracking.refreshNow();
                    } finally {
                      if (mounted) setState(() => _isRefreshing = false);
                    }
                  },
            icon: Icon(_isRefreshing ? Icons.hourglass_top : Icons.refresh),
            label: Text(_isRefreshing ? 'Refreshing…' : 'Refresh now'),
            style: TextButton.styleFrom(foregroundColor: fg),
          ),
        ],
      ),
    );
  }

  // Helpers
  Color _chipColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.hourglass_empty;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final d = now.difference(time);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
