const User = require('../models/User');
const { logAdminAction } = require('../utils/auditLogger');
const mongoose = require('mongoose');

// @desc    Get all users
// @route   GET /api/users
// @access  Private/Admin
const getUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // Build filter object
    const filter = {};
    
    // Role filtering (supports multiple roles)
    if (req.query.role) {
      if (Array.isArray(req.query.role)) {
        filter.roles = { $in: req.query.role };
      } else {
        filter.roles = { $in: [req.query.role] };
      }
    }
    
    if (req.query.isActive !== undefined) filter.isActive = req.query.isActive === 'true';
    if (req.query.isEmailVerified !== undefined) filter.isEmailVerified = req.query.isEmailVerified === 'true';
    
    // Date range filtering
    if (req.query.dateFrom || req.query.dateTo) {
      filter.createdAt = {};
      if (req.query.dateFrom) filter.createdAt.$gte = new Date(req.query.dateFrom);
      if (req.query.dateTo) filter.createdAt.$lte = new Date(req.query.dateTo);
    }

    // Search functionality
    if (req.query.search) {
      filter.$or = [
        { name: { $regex: req.query.search, $options: 'i' } },
        { email: { $regex: req.query.search, $options: 'i' } },
        { phone: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    // Sorting options
    let sortOption = { createdAt: -1 }; // default sort
    if (req.query.sortBy) {
      const sortBy = req.query.sortBy;
      const sortOrder = req.query.sortOrder === 'asc' ? 1 : -1;
      sortOption = { [sortBy]: sortOrder };
    }

    // ⚡ OPTIMIZED: Added .lean() for faster queries (returns plain JS objects)
    const users = await User.find(filter)
      .select('-password -__v') // Exclude password and version key
      .sort(sortOption)
      .skip(skip)
      .limit(limit)
      .lean(); // ⚡ 10-20% faster

    const total = await User.countDocuments(filter);
    const pages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: users,
      pagination: {
        page,
        limit,
        total,
        pages
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users',
      error: error.message
    });
  }
};

// @desc    Get single user
// @route   GET /api/users/:id
// @access  Private/Admin
const getUser = async (req, res) => {
  try {
    // ⚡ OPTIMIZED: Added .lean() and .select() for specific fields only
    const user = await User.findById(req.params.id)
      .select('-password -__v')
      .lean();

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user',
      error: error.message
    });
  }
};

// @desc    Update user
// @route   PUT /api/users/:id
// @access  Private/Admin
const updateUser = async (req, res) => {
  try {
    const { name, email, phone, role, isActive } = req.body;

    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if email is being changed and if it's already taken
    if (email && email !== user.email) {
      const existingUser = await User.findByEmail(email);
      if (existingUser && existingUser._id.toString() !== user._id.toString()) {
        return res.status(400).json({
          success: false,
          message: 'Email already taken by another user'
        });
      }
    }

    // Update user
    user.name = name || user.name;
    user.email = email || user.email;
    user.phone = phone || user.phone;
    user.role = role || user.role;
    user.isActive = isActive !== undefined ? isActive : user.isActive;

    await user.save();

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_UPDATED',
      { targetUser: user._id, changes: req.body },
      req,
      user._id
    );

    res.json({
      success: true,
      message: 'User updated successfully',
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update user',
      error: error.message
    });
  }
};

// @desc    Delete user
// @route   DELETE /api/users/:id
// @access  Private/Admin
const deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    await User.findByIdAndDelete(req.params.id);

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_DELETED',
      { deletedUser: { id: user._id, name: user.name, email: user.email } },
      req,
      user._id
    );

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete user',
      error: error.message
    });
  }
};

// @desc    Get user statistics
// @route   GET /api/users/stats
// @access  Private/Admin
const getUserStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const activeUsers = await User.countDocuments({ isActive: true });
    const adminUsers = await User.countDocuments({ roles: 'admin' });
    const customerUsers = await User.countDocuments({ roles: 'customer' });

    // Get users registered in the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const newUsers = await User.countDocuments({ createdAt: { $gte: thirtyDaysAgo } });

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers,
          activeUsers,
          inactiveUsers: totalUsers - activeUsers,
          adminUsers,
          customerUsers,
          newUsers
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user statistics',
      error: error.message
    });
  }
};

// @desc    Create new user (Admin only)
// @route   POST /api/admin/users
// @access  Private/Admin
const createUser = async (req, res) => {
  try {
    const { name, email, password, phone, roles, isActive, isEmailVerified } = req.body;

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Create user
    const user = await User.create({
      name,
      email,
      password,
      phone,
      roles: roles || ['customer'],
      isActive: isActive !== undefined ? isActive : true,
      isEmailVerified: isEmailVerified !== undefined ? isEmailVerified : false
    });

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_CREATED',
      { createdUser: { id: user._id, name: user.name, email: user.email, roles: user.roles } },
      req,
      user._id
    );

    res.status(201).json({
      success: true,
      message: 'User created successfully',
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create user',
      error: error.message
    });
  }
};

// @desc    Bulk update users
// @route   PUT /api/admin/users/bulk
// @access  Private/Admin
const bulkUpdateUsers = async (req, res) => {
  try {
    const { userIds, updates } = req.body;

    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'User IDs array is required'
      });
    }

    // Validate user IDs
    const validUserIds = userIds.filter(id => mongoose.Types.ObjectId.isValid(id));
    if (validUserIds.length !== userIds.length) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user IDs provided'
      });
    }

    // Perform bulk update
    const result = await User.updateMany(
      { _id: { $in: validUserIds } },
      { $set: updates },
      { runValidators: true }
    );

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_UPDATED',
      { 
        bulkUpdate: true, 
        affectedUsers: validUserIds.length, 
        updates 
      },
      req
    );

    res.json({
      success: true,
      message: `Updated ${result.modifiedCount} users successfully`,
      data: {
        matchedCount: result.matchedCount,
        modifiedCount: result.modifiedCount
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to bulk update users',
      error: error.message
    });
  }
};

// @desc    Toggle user status (activate/deactivate)
// @route   PATCH /api/admin/users/:id/toggle-status
// @access  Private/Admin
const toggleUserStatus = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const previousStatus = user.isActive;
    user.isActive = !user.isActive;
    await user.save();

    // Log admin action
    await logAdminAction(
      req.user.id,
      user.isActive ? 'USER_ACTIVATED' : 'USER_DEACTIVATED',
      { 
        targetUser: user._id, 
        previousStatus, 
        newStatus: user.isActive 
      },
      req,
      user._id
    );

    res.json({
      success: true,
      message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to toggle user status',
      error: error.message
    });
  }
};

// @desc    Update user roles
// @route   PATCH /api/admin/users/:id/roles
// @access  Private/Admin
const updateUserRoles = async (req, res) => {
  try {
    const { roles } = req.body;

    if (!Array.isArray(roles) || roles.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Roles array is required'
      });
    }

    // Validate roles
    const validRoles = ['customer', 'admin'];
    const invalidRoles = roles.filter(role => !validRoles.includes(role));
    if (invalidRoles.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid roles: ${invalidRoles.join(', ')}`
      });
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const previousRoles = [...user.roles];
    user.roles = roles;
    await user.save();

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_ROLE_CHANGED',
      { 
        targetUser: user._id, 
        previousRoles, 
        newRoles: roles 
      },
      req,
      user._id
    );

    res.json({
      success: true,
      message: 'User roles updated successfully',
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update user roles',
      error: error.message
    });
  }
};

// @desc    Get user activity/login history
// @route   GET /api/admin/users/:id/activity
// @access  Private/Admin
const getUserActivity = async (req, res) => {
  try {
    const AuditLog = require('../models/AuditLog');
    
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Get user activity logs
    const activities = await AuditLog.find({
      $or: [
        { userId: req.params.id },
        { targetUserId: req.params.id }
      ]
    })
    .populate('userId', 'name email')
    .sort({ timestamp: -1 })
    .skip(skip)
    .limit(limit);

    const total = await AuditLog.countDocuments({
      $or: [
        { userId: req.params.id },
        { targetUserId: req.params.id }
      ]
    });

    const pages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: activities,
      pagination: {
        page,
        limit,
        total,
        pages
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user activity',
      error: error.message
    });
  }
};

// @desc    Export users data
// @route   GET /api/admin/users/export
// @access  Private/Admin
const exportUsers = async (req, res) => {
  try {
    const { format = 'json' } = req.query;
    
    // Build filter (same as getUsers)
    const filter = {};
    if (req.query.role) {
      if (Array.isArray(req.query.role)) {
        filter.roles = { $in: req.query.role };
      } else {
        filter.roles = { $in: [req.query.role] };
      }
    }
    if (req.query.isActive !== undefined) filter.isActive = req.query.isActive === 'true';
    if (req.query.search) {
      filter.$or = [
        { name: { $regex: req.query.search, $options: 'i' } },
        { email: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    const users = await User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 })
      .lean(); // Convert to plain JavaScript objects

    // Log export action
    await logAdminAction(
      req.user.id,
      'USER_EXPORT',
      { format, totalExported: users.length },
      req
    );

    if (format === 'csv') {
      // Convert to CSV format
      const csv = users.map(user => ({
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        roles: user.roles.join(', '),
        isActive: user.isActive,
        isEmailVerified: user.isEmailVerified,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin || ''
      }));

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename=users.csv');
      
      // Simple CSV conversion (you might want to use a proper CSV library)
      const headers = Object.keys(csv[0] || {}).join(',');
      const rows = csv.map(row => Object.values(row).join(','));
      const csvContent = [headers, ...rows].join('\n');
      
      res.send(csvContent);
    } else {
      res.json({
        success: true,
        data: users,
        meta: {
          totalExported: users.length,
          exportedAt: new Date()
        }
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to export users',
      error: error.message
    });
  }
};

// @desc    Update current user's profile
// @route   PUT /api/users/me/profile
// @access  Private (Firebase authenticated users)
const updateMyProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, phone } = req.body;

    console.log(`👤 Updating profile for user ID: ${userId}`);
    console.log(`📝 Update data:`, { name, phone, hasAvatar: !!req.file });

    // Find user in MongoDB
    const user = await User.findById(userId);

    if (!user) {
      console.error(`❌ User not found: ${userId}`);
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Sync Firebase UID from middleware if not already set
    if (req.user.firebaseUid && (!user.firebaseUid || user.firebaseUid !== req.user.firebaseUid)) {
      console.log(`📝 Syncing Firebase UID: ${user.firebaseUid} → ${req.user.firebaseUid}`);
      user.firebaseUid = req.user.firebaseUid;
    }

    // Update fields
    if (name && name.trim()) {
      user.name = name.trim();
    }

    if (phone !== undefined) {
      user.phone = phone && phone.trim() ? phone.trim() : null;
    }

    // Update avatar if uploaded
    if (req.file) {
      // ✅ VALIDATION: Ensure file path exists from Cloudinary
      if (!req.file.path) {
        console.error('❌ Avatar upload failed: No file path returned from Cloudinary');
        return res.status(400).json({
          success: false,
          message: 'Avatar upload failed. Please try again.'
        });
      }

      // ✅ VALIDATION: Verify URL is valid Cloudinary URL
      if (!req.file.path.includes('cloudinary.com')) {
        console.error('❌ Invalid avatar URL format:', req.file.path);
        return res.status(400).json({
          success: false,
          message: 'Avatar upload returned invalid URL'
        });
      }

      const avatarUrl = req.file.path;
      console.log(`📸 Avatar successfully uploaded to: ${avatarUrl}`);
      
      // Delete old avatar from Cloudinary if exists
      if (user.avatar && user.avatar.includes('cloudinary')) {
        try {
          const { deleteImage } = require('../config/cloudinary');
          await deleteImage(user.avatar);
          console.log(`🗑️ Deleted old avatar from Cloudinary`);
        } catch (deleteError) {
          console.error('⚠️ Warning: Failed to delete old avatar:', deleteError);
          // Continue anyway, don't fail the request
        }
      }
      
      user.avatar = avatarUrl;
    }

    // CRITICAL FIX: Add comprehensive error handling for user.save()
    try {
      await user.save();
      console.log(`✅ Profile updated successfully for ${user.email}`);
    } catch (saveError) {
      console.error(`❌ CRITICAL: Failed to save user profile to database:`, {
        error: saveError.message,
        errorCode: saveError.code,
        errorName: saveError.name,
        userEmail: user.email,
        userId: userId
      });

      // Return detailed error response
      return res.status(500).json({
        success: false,
        message: 'Failed to save profile updates to database',
        error: process.env.NODE_ENV === 'development' ? {
          message: saveError.message,
          code: saveError.code,
          name: saveError.name
        } : undefined
      });
    }

    console.log(`✅ Profile update completed for ${user.email}`);

    // Return updated user data
    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: user.avatar,
        isEmailVerified: user.isEmailVerified,
        roles: user.roles,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
  } catch (error) {
    console.error('❌ Error updating profile:', error);
    
    // ✅ Detailed error logging for debugging
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      name: error.name,
      userId: userId,
      userEmail: error.userEmail || 'unknown'
    });

    // Determine appropriate status code and message
    let statusCode = 500;
    let errorMessage = 'Failed to update profile';

    if (error.message && error.message.includes('validation')) {
      statusCode = 400;
      errorMessage = error.message;
    } else if (error.code === 11000) {
      // Duplicate key error
      statusCode = 400;
      errorMessage = 'Email already in use by another user';
    } else if (error.name === 'ValidationError') {
      statusCode = 400;
      errorMessage = 'Invalid data provided';
    }

    res.status(statusCode).json({
      success: false,
      message: errorMessage,
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getUsers,
  getUser,
  updateUser,
  deleteUser,
  getUserStats,
  createUser,
  bulkUpdateUsers,
  toggleUserStatus,
  updateUserRoles,
  getUserActivity,
  exportUsers,
  updateMyProfile,
  // Address management
  getMyAddresses,
  addAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress
};

// @desc    Get my addresses
// @route   GET /api/users/me/addresses
// @access  Private
const getMyAddresses = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId).select('addresses');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      addresses: user.addresses || []
    });
  } catch (error) {
    console.error('Error fetching addresses:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch addresses',
      error: error.message
    });
  }
};

// @desc    Add new address
// @route   POST /api/users/me/addresses
// @access  Private
const addAddress = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, fullAddress, latitude, longitude, type, buildingDetails, landmark, isDefault } = req.body;

    // Validation
    if (!name || !fullAddress || latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: name, fullAddress, latitude, longitude'
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // If this is the first address or marked as default, unset other defaults
    if (isDefault || !user.addresses || user.addresses.length === 0) {
      user.addresses.forEach(addr => {
        addr.isDefault = false;
      });
    }

    // Add new address
    const newAddress = {
      name: name.trim(),
      fullAddress: fullAddress.trim(),
      latitude,
      longitude,
      type: type || 'other',
      buildingDetails: buildingDetails?.trim(),
      landmark: landmark?.trim(),
      isDefault: isDefault || (!user.addresses || user.addresses.length === 0),
      createdAt: new Date()
    };

    user.addresses.push(newAddress);
    await user.save();

    const addedAddress = user.addresses[user.addresses.length - 1];

    console.log(`✅ Address added for user ${user.email}: ${name}`);

    res.status(201).json({
      success: true,
      message: 'Address added successfully',
      address: addedAddress
    });
  } catch (error) {
    console.error('Error adding address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add address',
      error: error.message
    });
  }
};

// @desc    Update address
// @route   PUT /api/users/me/addresses/:addressId
// @access  Private
const updateAddress = async (req, res) => {
  try {
    const userId = req.user.id;
    const { addressId } = req.params;
    const { name, fullAddress, latitude, longitude, type, buildingDetails, landmark, isDefault } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const address = user.addresses.id(addressId);
    if (!address) {
      return res.status(404).json({
        success: false,
        message: 'Address not found'
      });
    }

    // If setting as default, unset other defaults
    if (isDefault) {
      user.addresses.forEach(addr => {
        if (addr._id.toString() !== addressId) {
          addr.isDefault = false;
        }
      });
    }

    // Update fields
    if (name !== undefined) address.name = name.trim();
    if (fullAddress !== undefined) address.fullAddress = fullAddress.trim();
    if (latitude !== undefined) address.latitude = latitude;
    if (longitude !== undefined) address.longitude = longitude;
    if (type !== undefined) address.type = type;
    if (buildingDetails !== undefined) address.buildingDetails = buildingDetails?.trim();
    if (landmark !== undefined) address.landmark = landmark?.trim();
    if (isDefault !== undefined) address.isDefault = isDefault;

    await user.save();

    console.log(`✅ Address updated for user ${user.email}: ${addressId}`);

    res.json({
      success: true,
      message: 'Address updated successfully',
      address
    });
  } catch (error) {
    console.error('Error updating address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update address',
      error: error.message
    });
  }
};

// @desc    Delete address
// @route   DELETE /api/users/me/addresses/:addressId
// @access  Private
const deleteAddress = async (req, res) => {
  try {
    const userId = req.user.id;
    const { addressId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const address = user.addresses.id(addressId);
    if (!address) {
      return res.status(404).json({
        success: false,
        message: 'Address not found'
      });
    }

    // If deleting default address, set first remaining address as default
    const wasDefault = address.isDefault;
    address.deleteOne();

    if (wasDefault && user.addresses.length > 0) {
      user.addresses[0].isDefault = true;
    }

    await user.save();

    console.log(`✅ Address deleted for user ${user.email}: ${addressId}`);

    res.json({
      success: true,
      message: 'Address deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete address',
      error: error.message
    });
  }
};

// @desc    Set default address
// @route   PUT /api/users/me/addresses/:addressId/default
// @access  Private
const setDefaultAddress = async (req, res) => {
  try {
    const userId = req.user.id;
    const { addressId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const address = user.addresses.id(addressId);
    if (!address) {
      return res.status(404).json({
        success: false,
        message: 'Address not found'
      });
    }

    // Unset all other defaults
    user.addresses.forEach(addr => {
      addr.isDefault = addr._id.toString() === addressId;
    });

    await user.save();

    console.log(`✅ Default address set for user ${user.email}: ${addressId}`);

    res.json({
      success: true,
      message: 'Default address updated successfully',
      address
    });
  } catch (error) {
    console.error('Error setting default address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to set default address',
      error: error.message
    });
  }
};
