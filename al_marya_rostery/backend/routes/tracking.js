const express = require('express');
const router = express.Router();
const trackingController = require('../controllers/trackingController');
const { protect } = require('../middleware/auth');

// All routes require authentication
router.use(protect);

// Get order tracking information
router.get('/:orderId', trackingController.getOrderTracking);

// Update order status (staff/driver only)
router.post('/:orderId/update-status', trackingController.updateOrderStatus);

// Update driver location (driver only)
router.post('/driver/update-location', trackingController.updateDriverLocation);

// Calculate ETA
router.post('/calculate-eta', trackingController.calculateETA);

module.exports = router;
