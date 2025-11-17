const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const addressController = require('../controllers/addressController');

// All routes are protected - require authentication
router.use(protect);

// GET /api/addresses - Get all addresses for user
router.get('/', addressController.getUserAddresses);

// GET /api/addresses/nearby - Find addresses near a location
router.get('/nearby', addressController.findNearbyAddresses);

// GET /api/addresses/:id - Get single address
router.get('/:id', addressController.getAddressById);

// POST /api/addresses - Create new address
router.post('/', addressController.createAddress);

// PUT /api/addresses/:id - Update address
router.put('/:id', addressController.updateAddress);

// DELETE /api/addresses/:id - Delete address
router.delete('/:id', addressController.deleteAddress);

// PUT /api/addresses/:id/default - Set as default address
router.put('/:id/default', addressController.setDefaultAddress);

// PUT /api/addresses/:id/verify - Verify address
router.put('/:id/verify', addressController.verifyAddress);

module.exports = router;
