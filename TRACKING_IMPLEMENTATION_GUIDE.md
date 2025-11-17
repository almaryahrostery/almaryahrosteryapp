# Live Order Tracking System - Complete Implementation Guide

## 🎯 Overview

This is a complete, production-ready real-time order tracking system for the Al Marya Rostery Flutter app. The system uses Socket.IO for real-time updates and features live map tracking, ETA calculations, and status progress indicators.

## 📋 Table of Contents

1. [System Architecture](#system-architecture)
2. [Setup & Installation](#setup--installation)
3. [Frontend Implementation](#frontend-implementation)
4. [Backend Implementation](#backend-implementation)
5. [Socket.IO Events](#socketio-events)
6. [API Endpoints](#api-endpoints)
7. [Example Payloads](#example-payloads)
8. [Testing & Debugging](#testing--debugging)
9. [Deployment](#deployment)

---

## 🏗 System Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  User App   │         │ Driver App  │         │  Staff App  │
│  (Flutter)  │         │  (Flutter)  │         │  (Flutter)  │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                        │
       │ WebSocket             │ WebSocket              │ WebSocket
       │ HTTP REST             │ HTTP REST              │ HTTP REST
       │                       │                        │
       └───────────────────────┼────────────────────────┘
                               │
                        ┌──────▼──────┐
                        │   Backend   │
                        │ (Node.js +  │
                        │  Socket.IO) │
                        └──────┬──────┘
                               │
                        ┌──────▼──────┐
                        │   MongoDB   │
                        │   Database  │
                        └─────────────┘
```

### Data Flow

```
Staff accepts order → Status update via API → Backend broadcasts to Socket room
                                            → All clients in room receive update
                                            
Driver moves → Location POST every 5s → Backend saves & broadcasts
                                      → User sees live marker movement
                                      → ETA recalculated (throttled)
```

---

## 🛠 Setup & Installation

### Prerequisites

- **Flutter**: >= 3.0.0
- **Node.js**: >= 20.0.0
- **MongoDB**: >= 6.0
- **Google Maps API Key**

### Backend Setup

1. **Install Socket.IO**:
```bash
cd backend
npm install socket.io@4.7.2
```

2. **Environment Variables** (`.env`):
```env
# Existing variables
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your_secret_key
PORT=5001

# NEW: Socket.IO Configuration
CLIENT_URL=*
ALLOW_GUEST_TRACKING=false

# Google Maps API (for production ETA)
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

3. **Start Server**:
```bash
npm start
```

The server will automatically:
- Initialize Socket.IO on the same port
- Set up tracking routes at `/api/tracking`
- Create order tracking rooms

### Flutter Setup

1. **Add Dependencies** (`pubspec.yaml`):
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  socket_io_client: ^2.0.3
  provider: ^6.1.1
  http: ^1.1.0
  intl: ^0.18.1
  url_launcher: ^6.2.2
```

2. **Install**:
```bash
flutter pub get
```

3. **Google Maps Setup**:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps

GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

4. **Add Route** to `app_router.dart`:
```dart
case '/tracking':
  final orderId = settings.arguments as String;
  return _buildRoute(TrackingPage(orderId: orderId));
```

---

## 📱 Frontend Implementation

### File Structure

```
lib/features/tracking/
├── models/
│   └── tracking_model.dart          # All data models
├── services/
│   ├── socket_service.dart          # Socket.IO singleton
│   └── tracking_service.dart        # API & business logic
├── widgets/
│   ├── tracking_map.dart            # Google Maps widget
│   ├── arrival_estimate_card.dart   # ETA display
│   ├── order_status_progress.dart   # Progress timeline
│   ├── order_details_card.dart      # Order info
│   └── receiver_details.dart        # Address info
└── screens/
    └── tracking_page.dart           # Main page
```

### Usage Example

```dart
// Navigate to tracking page
Navigator.pushNamed(
  context,
  '/tracking',
  arguments: orderId,
);
```

### Key Features

✅ **Real-time driver location** with smooth animations
✅ **Auto-updating ETA** with status labels (On Time / Delayed)
✅ **Progress timeline** with 7 status stages
✅ **Google Maps** with polyline routing
✅ **Offline handling** with connection indicators
✅ **Debug controls** for testing (dev mode only)

---

## 🖥 Backend Implementation

### File Structure

```
backend/
├── models/
│   └── OrderTracking.js         # MongoDB schema
├── controllers/
│   └── trackingController.js    # Business logic
├── routes/
│   └── tracking.js              # API routes
└── services/
    └── socketService.js         # Socket.IO setup
```

### Database Schema

```javascript
OrderTracking {
  orderId: ObjectId (ref Order)
  status: String (enum)
  staffLocation: { lat, lng, updatedAt }
  driverLocation: { lat, lng, speed, heading }
  userLocation: { lat, lng }
  eta: { start, end, distanceMeters, durationSeconds }
  timeline: [{ stage, time, message }]
  isDriverStationary: Boolean
  lastUpdate: Date
}
```

---

## 🔌 Socket.IO Events

### Client → Server

#### 1. Join Order Room
```javascript
socket.emit('join_order_room', {
  orderId: '507f1f77bcf86cd799439011',
  roomName: 'order_room_507f...' // optional
});
```

#### 2. Leave Order Room
```javascript
socket.emit('leave_order_room', {
  orderId: '507f1f77bcf86cd799439011'
});
```

### Server → Client

#### 1. driver_location
```javascript
{
  orderId: '507f1f77bcf86cd799439011',
  lat: 25.276987,
  lng: 55.296249,
  speed: 45.5,        // km/h
  heading: 90.0,       // degrees
  timestamp: '2025-11-17T10:30:00.000Z'
}
```

#### 2. order_status
```javascript
{
  orderId: '507f1f77bcf86cd799439011',
  status: 'on_the_way',
  timestamp: '2025-11-17T10:30:00.000Z',
  message: 'Driver is on the way'
}
```

#### 3. eta_update
```javascript
{
  orderId: '507f1f77bcf86cd799439011',
  etaStart: '2025-11-17T10:45:00.000Z',
  etaEnd: '2025-11-17T10:55:00.000Z',
  distanceMeters: 3500,
  durationSeconds: 600
}
```

---

## 🌐 API Endpoints

### 1. GET /api/tracking/:orderId

**Description**: Get full tracking data for an order

**Authentication**: Required (JWT)

**Response**:
```json
{
  "orderId": "507f1f77bcf86cd799439011",
  "status": "on_the_way",
  "eta": {
    "start": "2025-11-17T10:45:00.000Z",
    "end": "2025-11-17T10:55:00.000Z",
    "distanceMeters": 3500,
    "durationSeconds": 600
  },
  "driverLocation": {
    "lat": 25.276987,
    "lng": 55.296249,
    "updatedAt": "2025-11-17T10:30:00.000Z",
    "speed": 45.5,
    "heading": 90.0
  },
  "userLocation": {
    "lat": 25.286987,
    "lng": 55.306249
  },
  "driver": {
    "id": "507f...",
    "name": "Ahmed Ali",
    "phone": "+971501234567",
    "vehicleModel": "Toyota Camry",
    "vehiclePlate": "DXB-12345"
  },
  "timeline": [
    {
      "stage": "accepted_by_staff",
      "time": "2025-11-17T10:00:00.000Z",
      "message": "Order accepted"
    }
  ]
}
```

### 2. POST /api/tracking/:orderId/update-status

**Description**: Update order status (Staff/Driver)

**Authentication**: Required (JWT)

**Request**:
```json
{
  "status": "picked_by_driver",
  "message": "Order picked up by driver"
}
```

**Valid Statuses**:
- `accepted_by_staff`
- `preparing`
- `ready_for_handover`
- `picked_by_driver`
- `on_the_way`
- `arriving`
- `delivered`
- `cancelled`

**Response**:
```json
{
  "success": true,
  "message": "Order status updated"
}
```

### 3. POST /api/tracking/driver/update-location

**Description**: Update driver's current location (Driver App)

**Authentication**: Required (JWT)

**Request**:
```json
{
  "orderId": "507f1f77bcf86cd799439011",
  "lat": 25.276987,
  "lng": 55.296249,
  "speed": 45.5,
  "heading": 90.0
}
```

**Response**:
```json
{
  "success": true,
  "message": "Driver location updated"
}
```

**Rate Limit**: 1 request per 3 seconds per driver

### 4. POST /api/tracking/calculate-eta

**Description**: Calculate ETA based on current positions

**Authentication**: Required (JWT)

**Request**:
```json
{
  "orderId": "507f1f77bcf86cd799439011",
  "driverLocation": {
    "lat": 25.276987,
    "lng": 55.296249
  },
  "userLocation": {
    "lat": 25.286987,
    "lng": 55.306249
  },
  "isPickedUp": true
}
```

**Response**:
```json
{
  "eta": {
    "start": "2025-11-17T10:45:00.000Z",
    "end": "2025-11-17T10:55:00.000Z",
    "distanceMeters": 3500,
    "durationSeconds": 600
  }
}
```

---

## 📝 Example Payloads

### Driver App - Send Location Update

```dart
// Every 5 seconds while on delivery
Timer.periodic(Duration(seconds: 5), (timer) async {
  final position = await Geolocator.getCurrentPosition();
  
  await http.post(
    Uri.parse('$baseUrl/api/tracking/driver/update-location'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'orderId': currentOrderId,
      'lat': position.latitude,
      'lng': position.longitude,
      'speed': position.speed,
      'heading': position.heading,
    }),
  );
});
```

### Staff App - Update Status

```dart
// When staff marks order as ready
await http.post(
  Uri.parse('$baseUrl/api/tracking/$orderId/update-status'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'status': 'ready_for_handover',
    'message': 'Order is ready for pickup',
  }),
);
```

### cURL Examples

**Get Tracking Data**:
```bash
curl -X GET \
  http://localhost:5001/api/tracking/507f1f77bcf86cd799439011 \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

**Update Driver Location**:
```bash
curl -X POST \
  http://localhost:5001/api/tracking/driver/update-location \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "orderId": "507f1f77bcf86cd799439011",
    "lat": 25.276987,
    "lng": 55.296249,
    "speed": 45.5,
    "heading": 90.0
  }'
```

**Update Status**:
```bash
curl -X POST \
  http://localhost:5001/api/tracking/507f1f77bcf86cd799439011/update-status \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "status": "on_the_way",
    "message": "Driver is on the way to delivery"
  }'
```

---

## 🧪 Testing & Debugging

### Debug Mode Controls

When running in debug mode, the tracking page shows debug controls to simulate:

1. **Driver Movement**: Gradually moves driver toward user
2. **Status Changes**: Jump to any status
3. **Connection Status**: Green dot = connected, Red = disconnected

### Testing Checklist

- [ ] Socket connects on page load
- [ ] Driver marker appears and updates smoothly
- [ ] ETA updates when driver moves
- [ ] Status progress animates correctly
- [ ] Pull-to-refresh works
- [ ] Offline handling shows connection indicator
- [ ] Deep link to tracking page works
- [ ] Multiple users can track same order

### Monitoring

**Backend Logs**:
```bash
# Watch Socket.IO connections
tail -f logs/socket.log

# Watch API requests
tail -f logs/api.log
```

**Frontend Logs**:
```dart
// Enable verbose logging
AppLogger.debug('Socket connected: ${service.isConnected}');
```

---

## 🚀 Deployment

### Backend Deployment (Render.com)

1. **Add Socket.IO to package.json** (done)

2. **Environment Variables**:
```
MONGODB_URI=mongodb+srv://...
JWT_SECRET=...
CLIENT_URL=*
```

3. **Deploy**:
```bash
git push origin main
```

Render will automatically:
- Install dependencies (including socket.io)
- Start server with Socket.IO

### Flutter Deployment

1. **Android** (`build.gradle`):
```gradle
minSdkVersion 21
```

2. **iOS** (`Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show delivery tracking</string>
```

3. **Build**:
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 🎨 Theme Integration

All UI components use **Theme.of(context).primaryColor** for:
- Map markers (driver highlighted)
- Progress indicators
- Buttons and accents
- Status badges

No hardcoded colors - fully theme-aware!

---

## 📊 Performance

- **Socket.IO**: Automatic reconnection with exponential backoff
- **Location Updates**: Throttled to 1 per 3-5 seconds
- **ETA Calculation**: Throttled to 1 per 3 seconds
- **Marker Animation**: Smooth interpolation over 800ms
- **Map Updates**: Efficient bounds calculation

---

## 🔒 Security

- ✅ JWT authentication for all endpoints
- ✅ Socket connections validated
- ✅ Rate limiting on location updates
- ✅ User authorization (only track own orders)
- ✅ Input validation and sanitization

---

## 📞 Support

For issues or questions:
- Check logs in `backend/logs/`
- Review Socket.IO connection status
- Verify JWT tokens are valid
- Check Google Maps API quota

---

## ✅ Summary

**Frontend**: 11 files created (User App)  
**Backend**: 4 files created  
**Staff App**: 2 files created  
**Driver App**: 1 file created  
**Features**: All implemented  
**Status**: Production-ready! 🎉

**User App Navigation:** `Navigator.pushNamed(context, '/order-tracking', arguments: orderId)`  
**Staff & Driver Guide:** See `STAFF_DRIVER_TRACKING_GUIDE.md` for complete integration

---

## 📱 Staff & Driver App Integration

### Staff App Features
✅ **Accept Orders** - Staff can accept incoming orders  
✅ **Status Updates:**
  - Accepted by Staff
  - Preparing  
  - Ready for Handover

**Files Created:**
- `lib/features/orders/services/order_tracking_service.dart`
- `lib/features/orders/widgets/order_status_actions.dart`

### Driver App Features
✅ **Pickup Confirmation** - Confirm order collected  
✅ **Live Location Sharing** - GPS updates every 5 seconds  
✅ **Status Updates:**
  - Picked by Driver
  - On the Way
  - Arriving
  - Delivered
✅ **Multi-drop Support** - Handle multiple orders

**File Created:**
- `lib/features/tracking/services/driver_tracking_service.dart`

**📖 Complete Integration Guide:** `STAFF_DRIVER_TRACKING_GUIDE.md`
