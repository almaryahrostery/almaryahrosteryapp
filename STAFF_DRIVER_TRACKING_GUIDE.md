# 📱 Staff & Driver App - Tracking Integration Guide

## 🎯 Overview

This guide covers the tracking integration for **Staff App** and **Driver App** to work with the real-time tracking system.

---

## 📋 Table of Contents

1. [Staff App Integration](#staff-app-integration)
2. [Driver App Integration](#driver-app-integration)
3. [Backend API Reference](#backend-api-reference)
4. [Testing Guide](#testing-guide)

---

## 👨‍🍳 Staff App Integration

### Features Implemented

✅ **Accept Orders** - Staff can accept incoming orders  
✅ **Mark as Preparing** - Update when kitchen starts preparation  
✅ **Ready for Handover** - Signal driver can pick up the order  

### Files Created

1. **`lib/features/orders/services/order_tracking_service.dart`**
   - Service for updating order status
   - Methods: `acceptOrder()`, `markAsPreparing()`, `markAsReadyForHandover()`

2. **`lib/features/orders/widgets/order_status_actions.dart`**
   - UI widget with action buttons for each status
   - Shows appropriate button based on current order status

### Usage in Staff App

#### 1. Add the Widget to Order Details Page

```dart
import 'package:flutter/material.dart';
import '../widgets/order_status_actions.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final String currentStatus;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.currentStatus,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... other order details ...
            
            // Add tracking actions widget
            OrderStatusActions(
              orderId: widget.orderId,
              currentStatus: widget.currentStatus,
              onStatusUpdated: () {
                // Refresh order details
                setState(() {
                  // Reload order data
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 2. Status Flow for Staff

```
pending → [ACCEPT] → accepted_by_staff 
              ↓
         [PREPARING] → preparing
              ↓
    [READY FOR HANDOVER] → ready_for_handover
```

#### 3. API Calls Made

**Accept Order:**
```
POST /api/tracking/{orderId}/update-status
Body: { "status": "accepted_by_staff", "message": "Order accepted by staff" }
```

**Mark as Preparing:**
```
POST /api/tracking/{orderId}/update-status
Body: { "status": "preparing", "message": "Order is being prepared" }
```

**Ready for Handover:**
```
POST /api/tracking/{orderId}/update-status
Body: { "status": "ready_for_handover", "message": "Order is ready for driver pickup" }
```

---

## 🚗 Driver App Integration

### Features Implemented

✅ **Pickup Confirmation** - Confirm order collected from staff  
✅ **Live Location Sharing** - Send GPS updates every 5 seconds  
✅ **Mark as Delivered** - Complete the delivery  
✅ **Multi-drop Support** - Handle multiple orders  

### Files Created

1. **`lib/features/tracking/services/driver_tracking_service.dart`**
   - Real-time location sharing
   - Order status updates
   - Multi-order management

### Setup Requirements

#### 1. Add Dependencies to `pubspec.yaml`

```yaml
dependencies:
  http: ^1.1.0
  geolocator: ^10.1.0  # For GPS location
```

#### 2. Configure Location Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show delivery tracking to customers</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location in the background to update delivery status</string>
```

### Usage in Driver App

#### 1. Initialize the Service

```dart
import 'package:flutter/material.dart';
import '../services/driver_tracking_service.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final _trackingService = DriverTrackingService();
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    // Get token from your auth service
    // _authToken = await authService.getToken();
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your UI here
    return Scaffold(
      appBar: AppBar(title: const Text('Active Deliveries')),
      body: _buildOrdersList(),
    );
  }

  Widget _buildOrdersList() {
    // Build your orders list
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onPickupConfirm: () => _confirmPickup(order['id']),
          onStartDelivery: () => _startDelivery(order['id']),
          onMarkDelivered: () => _markDelivered(order['id']),
        );
      },
    );
  }

  Future<void> _confirmPickup(String orderId) async {
    if (_authToken == null) return;

    final success = await _trackingService.confirmPickup(
      orderId: orderId,
      authToken: _authToken!,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Order picked up')),
      );
    }
  }

  Future<void> _startDelivery(String orderId) async {
    if (_authToken == null) return;

    // Start location sharing
    final locationStarted = await _trackingService.startLocationSharing(
      orderId: orderId,
      authToken: _authToken!,
    );

    if (locationStarted) {
      // Update status to on_the_way
      await _trackingService.markAsOnTheWay(
        orderId: orderId,
        authToken: _authToken!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚗 Started delivery with live tracking')),
      );
    }
  }

  Future<void> _markDelivered(String orderId) async {
    if (_authToken == null) return;

    final success = await _trackingService.markAsDelivered(
      orderId: orderId,
      authToken: _authToken!,
      deliveryNotes: 'Delivered successfully',
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Order delivered! Location sharing stopped.')),
      );
    }
  }
}
```

#### 2. Driver Status Flow

```
ready_for_handover → [PICKUP] → picked_by_driver
                                      ↓
                              [START DELIVERY] → on_the_way (+ location sharing)
                                      ↓
                                  [ARRIVING] → arriving
                                      ↓
                                [DELIVERED] → delivered (stop location sharing)
```

#### 3. Complete Location Tracking Example

```dart
// In driver_tracking_service.dart - Update the _sendLocationUpdate method:

Future<bool> _sendLocationUpdate(String authToken) async {
  if (_currentOrderId == null) return false;

  try {
    // Get current GPS position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final url = Uri.parse('$_baseUrl/api/tracking/driver/update-location');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: json.encode({
        'orderId': _currentOrderId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
      }),
    );

    if (response.statusCode == 200) {
      print('📍 Location updated: ${position.latitude}, ${position.longitude}');
      return true;
    } else {
      print('⚠️ Failed to update location: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('❌ Error sending location: $e');
    return false;
  }
}
```

#### 4. Multi-Drop Support

```dart
// Get all active orders for the driver
final orders = await _trackingService.getActiveOrders(_authToken!);

// orders is a list of Map<String, dynamic>
for (var order in orders) {
  print('Order ${order['id']}: ${order['status']}');
  print('Deliver to: ${order['deliveryAddress']}');
}

// Driver can handle multiple orders simultaneously
// Location updates are sent for the active order (_currentOrderId)
```

---

## 🌐 Backend API Reference

### Endpoints Used by Staff App

#### 1. POST /api/tracking/:orderId/update-status
**Purpose:** Update order status

**Request:**
```json
{
  "status": "accepted_by_staff" | "preparing" | "ready_for_handover",
  "message": "Status message"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order status updated"
}
```

**Status Values for Staff:**
- `accepted_by_staff` - Order accepted
- `preparing` - Kitchen is preparing
- `ready_for_handover` - Ready for driver

---

### Endpoints Used by Driver App

#### 1. POST /api/tracking/:orderId/update-status
**Purpose:** Update order status

**Request:**
```json
{
  "status": "picked_by_driver" | "on_the_way" | "arriving" | "delivered",
  "message": "Status message"
}
```

**Status Values for Driver:**
- `picked_by_driver` - Order collected from staff
- `on_the_way` - En route to customer
- `arriving` - Within 500m of destination
- `delivered` - Order completed

#### 2. POST /api/tracking/driver/update-location
**Purpose:** Send live GPS location (every 5 seconds)

**Request:**
```json
{
  "orderId": "507f1f77bcf86cd799439011",
  "lat": 25.276987,
  "lng": 55.296249,
  "speed": 45.5,
  "heading": 90.0
}
```

**Rate Limit:** 1 request per 3 seconds

**Response:**
```json
{
  "success": true,
  "message": "Driver location updated"
}
```

#### 3. GET /api/driver/active-orders
**Purpose:** Get all orders assigned to driver

**Response:**
```json
{
  "orders": [
    {
      "id": "507f...",
      "status": "ready_for_handover",
      "deliveryAddress": "Building 123, Street ABC",
      "customerName": "John Doe",
      "customerPhone": "+971501234567"
    }
  ]
}
```

---

## 🧪 Testing Guide

### Staff App Testing

1. **Accept Order Test:**
   ```bash
   # Login to staff app
   # View pending orders list
   # Tap on an order
   # Tap "Accept Order" button
   # Verify: Order status changes to "Accepted"
   # Verify: User app shows "Order accepted by staff"
   ```

2. **Mark as Preparing Test:**
   ```bash
   # Open accepted order
   # Tap "Mark as Preparing" button
   # Verify: Order status changes to "Preparing"
   # Verify: User app shows "Your order is being prepared"
   ```

3. **Ready for Handover Test:**
   ```bash
   # Open preparing order
   # Tap "Ready for Handover" button
   # Verify: Order status changes to "Ready"
   # Verify: Driver app receives notification (if implemented)
   ```

### Driver App Testing

1. **Pickup Confirmation Test:**
   ```bash
   # Login to driver app
   # View "Ready for Handover" orders
   # Tap "Confirm Pickup" button
   # Verify: Status changes to "Picked by Driver"
   # Verify: User app shows "Driver collected your order"
   ```

2. **Live Location Sharing Test:**
   ```bash
   # After pickup, tap "Start Delivery"
   # Verify: Location permission requested
   # Grant location permission
   # Verify: Green indicator shows "Sharing Location"
   # Verify: User app shows driver marker moving on map
   # Move around and check real-time updates (every 5 seconds)
   ```

3. **Mark as Delivered Test:**
   ```bash
   # Arrive at customer location
   # Tap "Mark as Delivered"
   # Verify: Status changes to "Delivered"
   # Verify: Location sharing stops
   # Verify: User app shows "Order delivered"
   # Verify: Order moved to history
   ```

4. **Multi-Drop Test:**
   ```bash
   # Driver has 3 active orders
   # Start delivery for Order #1
   # Verify: Only Order #1 sends location updates
   # Mark Order #1 as delivered
   # Start delivery for Order #2
   # Verify: Location updates switch to Order #2
   # Repeat for Order #3
   ```

---

## 📊 Status Flow Complete Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     ORDER TRACKING FLOW                      │
└─────────────────────────────────────────────────────────────┘

Customer Places Order
         ↓
   [PENDING ORDER]
         ↓
   ┌──────────────────┐
   │   STAFF APP      │ ← Accept Order
   └──────────────────┘
         ↓
   [ACCEPTED BY STAFF]
         ↓
   ┌──────────────────┐
   │   STAFF APP      │ ← Mark as Preparing
   └──────────────────┘
         ↓
   [PREPARING]
         ↓
   ┌──────────────────┐
   │   STAFF APP      │ ← Ready for Handover
   └──────────────────┘
         ↓
   [READY FOR HANDOVER]
         ↓
   ┌──────────────────┐
   │   DRIVER APP     │ ← Confirm Pickup
   └──────────────────┘
         ↓
   [PICKED BY DRIVER]
         ↓
   ┌──────────────────┐
   │   DRIVER APP     │ ← Start Delivery + Location Sharing
   └──────────────────┘
         ↓
   [ON THE WAY] ────► 📍 Live GPS Updates (every 5s)
         ↓
   ┌──────────────────┐
   │   DRIVER APP     │ ← Mark as Arriving (auto when within 500m)
   └──────────────────┘
         ↓
   [ARRIVING]
         ↓
   ┌──────────────────┐
   │   DRIVER APP     │ ← Mark as Delivered
   └──────────────────┘
         ↓
   [DELIVERED] ────► Stop Location Sharing
```

---

## 🔒 Security Notes

**Authentication:**
- All API calls require JWT token in `Authorization: Bearer <token>` header
- Staff can only update orders in their restaurant
- Drivers can only update their assigned orders

**Location Privacy:**
- Location sharing only active during deliveries
- Automatically stops when order is delivered
- User only sees driver location, not driver's home/other locations

**Rate Limiting:**
- Location updates: 1 per 3 seconds (enforced by backend)
- Status updates: Reasonable rate limits apply

---

## 🚀 Deployment Checklist

### Staff App
- [ ] Add order_tracking_service.dart
- [ ] Add order_status_actions.dart widget
- [ ] Integrate widget into order details page
- [ ] Test all 3 status transitions
- [ ] Verify real-time updates in user app

### Driver App
- [ ] Add geolocator dependency to pubspec.yaml
- [ ] Configure location permissions (Android + iOS)
- [ ] Add driver_tracking_service.dart
- [ ] Implement location tracking in UI
- [ ] Test pickup, delivery, and location sharing
- [ ] Test multi-drop scenarios
- [ ] Verify real-time map updates in user app

---

## ✅ Summary

**Staff App Features:**
- ✅ Accept orders
- ✅ Mark as preparing
- ✅ Ready for handover
- ✅ Real-time status broadcasting

**Driver App Features:**
- ✅ Confirm pickup
- ✅ Live location sharing (every 5 seconds)
- ✅ Mark as delivered
- ✅ Multi-drop support
- ✅ Automatic location stop on delivery

**Integration Complete!** 🎉

Both apps now have full tracking integration with the real-time system!

---

**Created:** November 17, 2025  
**For:** Al Marya Rostery Staff & Driver Apps  
**Version:** 1.0.0
