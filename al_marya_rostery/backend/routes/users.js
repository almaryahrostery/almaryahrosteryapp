const express = require('express');
const { body } = require('express-validator');
const multer = require('multer');
const {
  getUsers,
  getUser,
  updateUser,
  deleteUser,
  getUserStats,
  updateMyProfile,
  getMyAddresses,
  addAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress
} = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const Order = require('../models/Order');

const router = express.Router();

// Configure multer for profile picture uploads
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinary').cloudinary || require('cloudinary').v2;

const profileStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'al-marya/profiles',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [
      { width: 400, height: 400, crop: 'fill', gravity: 'face', quality: 'auto:good' }
    ],
    public_id: (req, file) => {
      // ✅ CRITICAL: Ensure userId exists before generating ID
      if (!req.user || !req.user.id) {
        console.error('❌ CRITICAL: User ID not available for profile upload');
        throw new Error('User ID not available. Please ensure you are authenticated.');
      }
      
      const userId = req.user.id.toString();
      const timestamp = Date.now();
      const random = Math.floor(Math.random() * 1000000);
      
      console.log(`📸 Generating Cloudinary public_id for user ${userId}`);
      return `profile-${userId}-${timestamp}-${random}`;
    },
  },
});

const upload = multer({
  storage: profileStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// ✅ Error handler for multer upload errors
const handleUploadError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    console.error('❌ Multer error:', err);
    if (err.code === 'FILE_TOO_LARGE') {
      return res.status(413).json({
        success: false,
        message: 'File too large. Maximum size is 5MB',
        error: 'FILE_TOO_LARGE'
      });
    }
    return res.status(400).json({
      success: false,
      message: `Upload error: ${err.message}`,
      error: err.code
    });
  } else if (err) {
    console.error('❌ Upload processing error:', err);
    return res.status(400).json({
      success: false,
      message: `Upload failed: ${err.message}`,
      error: 'UPLOAD_ERROR'
    });
  }
  next();
};

// Validation rules
const userUpdateValidation = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('email')
    .optional()
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('phone')
    .optional()
    .matches(/^[\+]?[1-9][\d]{0,15}$/)
    .withMessage('Please provide a valid phone number'),
  body('role')
    .optional()
    .isIn(['customer', 'admin'])
    .withMessage('Role must be either customer or admin'),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean value')
];

// User-specific routes (with Firebase auth)
// @route   PUT /api/users/me/profile
// @desc    Update current user's profile
// @access  Private (Firebase authenticated users)
router.put(
  '/me/profile', 
  verifyFirebaseToken,
  userUpdateValidation,  // ✅ VALIDATE FORM DATA FIRST
  upload.single('avatar'), 
  updateMyProfile
);

// Address management routes
// @route   GET /api/users/me/addresses
// @desc    Get all addresses for current user
// @access  Private
router.get('/me/addresses', verifyFirebaseToken, getMyAddresses);

// @route   POST /api/users/me/addresses
// @desc    Add new address
// @access  Private
router.post('/me/addresses', verifyFirebaseToken, addAddress);

// @route   PUT /api/users/me/addresses/:addressId
// @desc    Update address
// @access  Private
router.put('/me/addresses/:addressId', verifyFirebaseToken, updateAddress);

// @route   DELETE /api/users/me/addresses/:addressId
// @desc    Delete address
// @access  Private
router.delete('/me/addresses/:addressId', verifyFirebaseToken, deleteAddress);

// @route   PUT /api/users/me/addresses/:addressId/default
// @desc    Set default address
// @access  Private
router.put('/me/addresses/:addressId/default', verifyFirebaseToken, setDefaultAddress);

// @route   POST /api/users/me/fcm-token
// @desc    Save or update user's FCM token for push notifications
// @access  Private (Firebase authenticated users)
router.post('/me/fcm-token', verifyFirebaseToken, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const User = require('../models/User');

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    // Update user's FCM token
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { 
        fcmToken: fcmToken,
        fcmTokenUpdatedAt: new Date()
      },
      { new: true, select: '+fcmToken' }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log(`📱 FCM token saved for user: ${req.user.email}`);

    res.json({
      success: true,
      message: 'FCM token saved successfully'
    });
  } catch (error) {
    console.error('❌ Error saving FCM token:', error);
    res.status(500).json({
      success: false,
      message: 'Error saving FCM token',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// @route   GET /api/users/me/orders
// @desc    Get current user's orders
// @access  Private (Firebase authenticated users)
router.get('/me/orders', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    console.log(`📦 Fetching orders for user: ${req.user.email} (ID: ${userId})`);

    // Find orders for this user
    const orders = await Order.find({ userId })
      .sort({ createdAt: -1 }) // Newest first
      .lean();

    console.log(`✅ Found ${orders.length} orders for user ${req.user.email}`);

    // Return orders with proper structure
    const response = {
      success: true,
      count: orders.length,
      orders: orders.map(order => ({
        _id: order._id.toString(),
        userId: order.userId,
        items: order.items || {},
        total: order.total || 0,
        status: order.status || 'pending',
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        notes: order.notes,
        deliveryAddress: order.deliveryAddress
      }))
    };
    
    console.log('📤 Sending response:', JSON.stringify(response));
    res.json(response);
  } catch (error) {
    console.error('❌ Error fetching user orders:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching orders',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Admin routes
router.get('/stats', getUserStats);
router.get('/', getUsers);
router.get('/:id', getUser);
router.put('/:id', userUpdateValidation, updateUser);
router.delete('/:id', deleteUser);

module.exports = router;
