const OrderTracking = require('../models/OrderTracking');
const Order = require('../models/Order');

// Get tracking information for an order
exports.getOrderTracking = async (req, res) => {
  try {
    const { orderId } = req.params;

    // Find order
    const order = await Order.findById(orderId)
      .populate('user', 'name email phone')
      .populate('driver', 'name phone vehicleModel vehiclePlate photoUrl rating')
      .populate('staff', 'name phone photoUrl');

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Verify user has access to this order
    if (req.user && req.user.id !== order.user._id.toString() && 
        !req.user.roles.includes('admin') && 
        !req.user.roles.includes('staff')) {
      return res.status(403).json({ message: 'Access denied' });
    }

    // Find or create tracking
    let tracking = await OrderTracking.findOne({ orderId });

    if (!tracking) {
      tracking = new OrderTracking({
        orderId,
        status: order.status || 'preparing',
        userLocation: order.deliveryAddress?.location || { lat: 0, lng: 0 },
        timeline: [{
          stage: order.status || 'preparing',
          time: order.createdAt,
          message: 'Order placed'
        }]
      });
      await tracking.save();
    }

    // Build response
    const response = {
      orderId: order._id,
      status: tracking.status,
      eta: tracking.eta,
      staffLocation: tracking.staffLocation,
      driverLocation: tracking.driverLocation,
      userLocation: tracking.userLocation || order.deliveryAddress?.location,
      driver: order.driver ? {
        id: order.driver._id,
        name: order.driver.name,
        phone: order.driver.phone,
        vehicleModel: order.driver.vehicleModel,
        vehiclePlate: order.driver.vehiclePlate,
        photoUrl: order.driver.photoUrl,
        rating: order.driver.rating
      } : null,
      staff: order.staff ? {
        id: order.staff._id,
        name: order.staff.name,
        phone: order.staff.phone,
        photoUrl: order.staff.photoUrl
      } : null,
      deliveryAddress: {
        id: order.deliveryAddress?.id || order._id,
        label: order.deliveryAddress?.label || 'Home',
        fullAddress: order.deliveryAddress?.fullAddress || order.deliveryAddress?.address,
        building: order.deliveryAddress?.building || order.deliveryAddress?.buildingName,
        street: order.deliveryAddress?.street || order.deliveryAddress?.streetName,
        area: order.deliveryAddress?.area,
        city: order.deliveryAddress?.city,
        deliveryInstructions: order.deliveryAddress?.deliveryInstructions,
        location: order.deliveryAddress?.location || order.deliveryAddress?.gps
      },
      timeline: tracking.timeline,
      isDriverStationary: tracking.isDriverStationary,
      lastUpdate: tracking.lastUpdate
    };

    res.json(response);
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error getting order tracking', { orderId: req.params.orderId, error: error.message });
    
    res.status(500).json({ 
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Server error' 
    });
  }
};

// Update order status
exports.updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status, message } = req.body;

    // Validate status
    const validStatuses = [
      'accepted_by_staff',
      'preparing',
      'ready_for_handover',
      'picked_by_driver',
      'on_the_way',
      'arriving',
      'delivered',
      'cancelled'
    ];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    // Find tracking
    let tracking = await OrderTracking.findOne({ orderId });

    if (!tracking) {
      tracking = new OrderTracking({
        orderId,
        status,
        timeline: []
      });
    }

    // Update status
    tracking.updateStatus(status, message);
    await tracking.save();

    // Update order status
    await Order.findByIdAndUpdate(orderId, { status });

    // Emit socket event
    const io = req.app.get('io');
    if (io) {
      io.to(`order_room_${orderId}`).emit('order_status', {
        orderId,
        status,
        timestamp: new Date().toISOString(),
        message
      });
    }

    res.json({
      success: true,
      tracking,
      message: 'Driver location updated'
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error updating driver location', { orderId: req.body.orderId, error: error.message });
    
    res.status(500).json({ 
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Server error' 
    });
  }
};

// Update driver location
exports.updateDriverLocation = async (req, res) => {
  try {
    const { orderId, lat, lng, speed, heading } = req.body;

    if (!orderId || lat === undefined || lng === undefined) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Find tracking
    let tracking = await OrderTracking.findOne({ orderId });

    if (!tracking) {
      return res.status(404).json({ message: 'Tracking not found for this order' });
    }

    // Update driver location
    tracking.driverLocation = {
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      updatedAt: new Date(),
      speed: speed ? parseFloat(speed) : undefined,
      heading: heading ? parseFloat(heading) : undefined
    };

    await tracking.save();

    // Emit socket event
    const io = req.app.get('io');
    if (io) {
      io.to(`order_room_${orderId}`).emit('driver_location', {
        orderId,
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        speed: speed ? parseFloat(speed) : undefined,
        heading: heading ? parseFloat(heading) : undefined,
        timestamp: new Date().toISOString()
      });
    }

    res.json({
      success: true,
      message: 'Driver location updated'
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error updating driver location', { orderId: req.body.orderId, error: error.message });
    
    res.status(500).json({ 
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Server error'
    });
  }
};

// Calculate and update ETA
exports.calculateETA = async (req, res) => {
  try {
    const { orderId, driverLocation, userLocation, isPickedUp } = req.body;

    if (!driverLocation || !userLocation) {
      return res.status(400).json({ message: 'Missing location data' });
    }

    // Simple ETA calculation (in production, use Google Distance Matrix API)
    // Calculate distance using Haversine formula
    const distance = calculateDistance(
      driverLocation.lat,
      driverLocation.lng,
      userLocation.lat,
      userLocation.lng
    );

    // Estimate duration (assuming average speed of 40 km/h)
    const durationMinutes = Math.ceil((distance / 40) * 60);

    const now = new Date();
    const etaStart = new Date(now.getTime() + durationMinutes * 60000);
    const etaEnd = new Date(etaStart.getTime() + 10 * 60000); // 10 min window

    const eta = {
      start: etaStart,
      end: etaEnd,
      distanceMeters: Math.round(distance * 1000),
      durationSeconds: durationMinutes * 60
    };

    // Update tracking
    const tracking = await OrderTracking.findOne({ orderId });
    if (tracking) {
      tracking.eta = eta;
      await tracking.save();

      // Emit socket event
      const io = req.app.get('io');
      if (io) {
        io.to(`order_room_${orderId}`).emit('eta_update', {
          orderId,
          etaStart: eta.start.toISOString(),
          etaEnd: eta.end.toISOString(),
          distanceMeters: eta.distanceMeters,
          durationSeconds: eta.durationSeconds
        });
      }
    }

    res.json({ eta });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error calculating ETA', { orderId: req.params.orderId, error: error.message });
    res.status(500).json({ 
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to calculate ETA' 
    });
  }
};

// Haversine formula to calculate distance between two lat/lng points
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  
  return distance; // in km
}

function toRad(degrees) {
  return degrees * (Math.PI / 180);
}
