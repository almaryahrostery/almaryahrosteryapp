const Address = require('../models/Address');
const { protect } = require('../middleware/auth');

// Get all addresses for authenticated user
exports.getUserAddresses = async (req, res) => {
  try {
    const { latitude, longitude } = req.query;

    const addresses = await Address.find({ userId: req.user._id }).sort({
      isDefault: -1,
      createdAt: -1,
    });

    // If user location provided, calculate distances
    if (latitude && longitude) {
      const lat = parseFloat(latitude);
      const lon = parseFloat(longitude);

      const addressesWithDistance = addresses.map((addr) => {
        const addressObj = addr.toJSON();
        addressObj.distanceFromUser = addr.calculateDistance(lat, lon);
        return addressObj;
      });

      return res.json({
        success: true,
        count: addressesWithDistance.length,
        addresses: addressesWithDistance,
      });
    }

    res.json({
      success: true,
      count: addresses.length,
      addresses,
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error fetching addresses', { userId: req.user?._id, error: error.message });
    
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to fetch addresses',
    });
  }
};

// Get single address by ID
exports.getAddressById = async (req, res) => {
  try {
    const address = await Address.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!address) {
      return res.status(404).json({
        success: false,
        message: 'Address not found',
      });
    }

    res.json({
      success: true,
      address,
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error fetching address', { userId: req.user?._id, addressId: req.params.id, error: error.message });
    
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to fetch address',
    });
  }
};

// Create new address
exports.createAddress = async (req, res) => {
  try {
    const {
      title,
      fullAddress,
      buildingName,
      streetName,
      area,
      city,
      flatNumber,
      floorNumber,
      landmark,
      latitude,
      longitude,
      contactName,
      contactNumber,
      isDefault,
      addressType,
      deliveryInstructions,
    } = req.body;

    // Validation
    if (!title || !streetName || !area || !contactName || !contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields',
        required: ['title', 'streetName', 'area', 'contactName', 'contactNumber'],
      });
    }

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        code: 'VALIDATION_ERROR',
        message: 'Location coordinates are required',
      });
    }

    // Create address
    const address = new Address({
      userId: req.user._id,
      title,
      fullAddress: fullAddress || `${streetName}, ${area}, ${city || 'Dubai'}`,
      buildingName: buildingName || '',
      streetName,
      area,
      city: city || 'Dubai',
      flatNumber: flatNumber || '',
      floorNumber: floorNumber || '',
      landmark: landmark || '',
      location: {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      },
      contactName,
      contactNumber,
      isDefault: isDefault || false,
      addressType: addressType || 'apartment',
      deliveryInstructions: deliveryInstructions || '',
    });

    await address.save();

    res.status(201).json({
      success: true,
      message: 'Address created successfully',
      address,
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error creating address', { userId: req.user?._id, error: error.message });
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        code: 'VALIDATION_ERROR',
        message: 'Invalid address data',
      });
    }
    
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to create address',
    });
  }
};

// Update address
exports.updateAddress = async (req, res) => {
  try {
    const address = await Address.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!address) {
      return res.status(404).json({
        success: false,
        message: 'Address not found',
      });
    }

    const {
      title,
      fullAddress,
      buildingName,
      streetName,
      area,
      city,
      flatNumber,
      floorNumber,
      landmark,
      latitude,
      longitude,
      contactName,
      contactNumber,
      isDefault,
      addressType,
      deliveryInstructions,
    } = req.body;

    // Update fields
    if (title) address.title = title;
    if (fullAddress) address.fullAddress = fullAddress;
    if (buildingName !== undefined) address.buildingName = buildingName;
    if (streetName) address.streetName = streetName;
    if (area) address.area = area;
    if (city) address.city = city;
    if (flatNumber !== undefined) address.flatNumber = flatNumber;
    if (floorNumber !== undefined) address.floorNumber = floorNumber;
    if (landmark !== undefined) address.landmark = landmark;
    if (contactName) address.contactName = contactName;
    if (contactNumber) address.contactNumber = contactNumber;
    if (isDefault !== undefined) address.isDefault = isDefault;
    if (addressType) address.addressType = addressType;
    if (deliveryInstructions !== undefined)
      address.deliveryInstructions = deliveryInstructions;

    // Update location if provided
    if (latitude && longitude) {
      address.location = {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      };
    }

    await address.save();

    res.json({
      success: true,
      message: 'Address updated successfully',
      address,
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error updating address', { userId: req.user?._id, addressId: req.params.id, error: error.message });
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        code: 'VALIDATION_ERROR',
        message: 'Invalid address data',
      });
    }
    
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to update address',
    });
  }
};

// Delete address
exports.deleteAddress = async (req, res) => {
  try {
    const address = await Address.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!address) {
      return res.status(404).json({
        success: false,
        message: 'Address not found',
      });
    }

    // If deleted address was default, set another address as default
    if (address.isDefault) {
      const nextAddress = await Address.findOne({
        userId: req.user._id,
      }).sort({ createdAt: -1 });

      if (nextAddress) {
        nextAddress.isDefault = true;
        await nextAddress.save();
      }
    }

    res.json({
      success: true,
      message: 'Address deleted successfully',
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error deleting address', { userId: req.user?._id, addressId: req.params.id, error: error.message });
    
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to delete address',
    });
  }
};

// Set address as default
exports.setDefaultAddress = async (req, res) => {
  try {
    const address = await Address.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!address) {
      return res.status(404).json({
        success: false,
        message: 'Address not found',
      });
    }

    address.isDefault = true;
    await address.save();

    res.json({
      success: true,
      message: 'Default address updated successfully',
      address,
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error setting default address', { userId: req.user?._id, addressId: req.params.id, error: error.message });
    
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to update default address',
    });
  }
};

// Verify address
exports.verifyAddress = async (req, res) => {
  try {
    const address = await Address.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!address) {
      return res.status(404).json({
        success: false,
        message: 'Address not found',
      });
    }

    address.isVerified = true;
    await address.save();

    res.json({
      success: true,
      message: 'Address verified successfully',
      address,
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error verifying address', { addressId: req.params.id, error: error.message });
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to verify address',
    });
  }
};

// Find addresses near a location
exports.findNearbyAddresses = async (req, res) => {
  try {
    const { latitude, longitude, maxDistance = 5000 } = req.query; // maxDistance in meters

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required',
      });
    }

    const addresses = await Address.find({
      userId: req.user._id,
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)],
          },
          $maxDistance: parseInt(maxDistance),
        },
      },
    });

    res.json({
      success: true,
      count: addresses.length,
      addresses,
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error finding nearby addresses', { lat: req.body.lat, lng: req.body.lng, error: error.message });
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to find nearby addresses',
    });
  }
};
