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
    console.error('Error fetching addresses:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch addresses',
      error: error.message,
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
    console.error('Error fetching address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch address',
      error: error.message,
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
    console.error('Error creating address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create address',
      error: error.message,
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
    console.error('Error updating address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update address',
      error: error.message,
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
    console.error('Error deleting address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete address',
      error: error.message,
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
      message: 'Default address updated',
      address,
    });
  } catch (error) {
    console.error('Error setting default address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to set default address',
      error: error.message,
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
    console.error('Error verifying address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify address',
      error: error.message,
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
    console.error('Error finding nearby addresses:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to find nearby addresses',
      error: error.message,
    });
  }
};
