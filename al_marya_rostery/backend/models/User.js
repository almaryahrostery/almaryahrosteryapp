const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: [50, 'Name cannot be more than 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    validate: {
      validator: function(email) {
        // Comprehensive email validation regex
        const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
        return emailRegex.test(email);
      },
      message: 'Please provide a valid email address'
    },
    maxlength: [254, 'Email address too long'] // RFC 5321 limit
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters'],
    maxlength: [128, 'Password too long'],
    select: false, // Don't include password in queries by default
    validate: {
      validator: function(password) {
        // Strong password policy: at least 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char
        const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/;
        return strongPasswordRegex.test(password);
      },
      message: 'Password must contain at least 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character (@$!%*?&)'
    }
  },
  phone: {
    type: String,
    trim: true
  },
  avatar: {
    type: String,
    default: null
  },
  roles: {
    type: [String],
    enum: ['customer', 'admin'],
    default: ['customer']
  },
  // Firebase Integration Fields
  firebaseUid: {
    type: String,
    unique: true,
    sparse: true // Allows null values but ensures uniqueness when present
    // Removed index: true since unique: true creates an index automatically
  },
  firebaseSyncStatus: {
    type: String,
    enum: ['synced', 'pending', 'error', 'manual'],
    default: 'manual'
  },
  lastFirebaseSync: {
    type: Date,
    default: null
  },
  firebaseSyncError: {
    type: String,
    default: null
  },
  // OAuth Integration Fields
  authProvider: {
    type: String,
    enum: ['email', 'google', 'facebook', 'apple'],
    default: 'email'
  },
  providerId: {
    type: String,  // Google/Facebook/Apple user ID
    sparse: true
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  emailVerificationToken: {
    type: String,
    default: null
  },
  emailVerificationExpires: {
    type: Date,
    default: null
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date,
    default: null
  },
  // FCM Token for Push Notifications
  fcmToken: {
    type: String,
    default: null,
    select: false // Don't include in queries by default for security
  },
  fcmTokenUpdatedAt: {
    type: Date,
    default: null
  },
  // Password reset fields
  resetPasswordToken: {
    type: String,
    default: null
  },
  resetPasswordExpires: {
    type: Date,
    default: null
  },
  // Enhanced user profile fields
  dateOfBirth: {
    type: Date,
    default: null
  },
  // Delivery addresses
  addresses: [{
    name: {
      type: String,
      required: true,
      trim: true
    },
    fullAddress: {
      type: String,
      required: true,
      trim: true
    },
    latitude: {
      type: Number,
      required: true
    },
    longitude: {
      type: Number,
      required: true
    },
    type: {
      type: String,
      enum: ['home', 'work', 'other'],
      default: 'other'
    },
    buildingDetails: {
      type: String,
      trim: true
    },
    landmark: {
      type: String,
      trim: true
    },
    isDefault: {
      type: Boolean,
      default: false
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  gender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer_not_to_say'],
    default: null
  },
  addresses: [{
    type: {
      type: String,
      enum: ['home', 'work', 'other'],
      default: 'home'
    },
    street: {
      type: String,
      required: true,
      trim: true
    },
    city: {
      type: String,
      required: true,
      trim: true
    },
    state: {
      type: String,
      trim: true
    },
    zipCode: {
      type: String,
      trim: true
    },
    country: {
      type: String,
      default: 'UAE',
      trim: true
    },
    isDefault: {
      type: Boolean,
      default: false
    },
    deliveryInstructions: {
      type: String,
      maxlength: [200, 'Delivery instructions cannot exceed 200 characters']
    }
  }],
  preferences: {
    favoriteCategories: [String],
    notifications: {
      email: { type: Boolean, default: true },
      push: { type: Boolean, default: true },
      sms: { type: Boolean, default: false },
      orderUpdates: { type: Boolean, default: true },
      promotions: { type: Boolean, default: true },
      newsletter: { type: Boolean, default: true }
    },
    language: {
      type: String,
      enum: ['en', 'ar'],
      default: 'en'
    },
    currency: {
      type: String,
      enum: ['AED', 'USD', 'EUR'],
      default: 'AED'
    },
    brewingMethods: [{
      type: String,
      enum: ['Drip', 'Pour Over', 'French Press', 'Espresso', 'Cold Brew', 'Turkish']
    }],
    flavorPreferences: {
      acidity: {
        type: String,
        enum: ['low', 'medium', 'high']
      },
      body: {
        type: String,
        enum: ['light', 'medium', 'full']
      },
      roastLevel: {
        type: String,
        enum: ['Light', 'Medium-Light', 'Medium', 'Medium-Dark', 'Dark']
      }
    }
  },
  loyaltyProgram: {
    points: {
      type: Number,
      default: 0,
      min: [0, 'Loyalty points cannot be negative']
    },
    tier: {
      type: String,
      enum: ['Bronze', 'Silver', 'Gold', 'Platinum'],
      default: 'Bronze'
    },
    totalSpent: {
      type: Number,
      default: 0,
      min: [0, 'Total spent cannot be negative']
    },
    lastEarnedDate: {
      type: Date,
      default: null
    }
  },
  socialProfiles: {
    facebook: String,
    instagram: String,
    twitter: String
  },
  statistics: {
    totalOrders: {
      type: Number,
      default: 0
    },
    totalSpent: {
      type: Number,
      default: 0
    },
    averageOrderValue: {
      type: Number,
      default: 0
    },
    favoriteProducts: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Coffee'
    }],
    lastOrderDate: {
      type: Date,
      default: null
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Optimized indexes for query performance
// Note: email and firebaseUid indexes are automatically created by unique: true
userSchema.index({ 'roles': 1 }); // For role-based queries
userSchema.index({ isActive: 1 }); // For filtering active users
userSchema.index({ createdAt: -1 }); // For recent users queries
userSchema.index({ lastLogin: -1 }); // For user activity tracking
userSchema.index({ firebaseSyncStatus: 1 }); // For sync status queries

// Compound indexes for common query patterns
userSchema.index({ email: 1, isActive: 1 }); // Login queries
userSchema.index({ roles: 1, isActive: 1 }); // Admin user queries
userSchema.index({ firebaseUid: 1, isActive: 1 }); // Firebase auth queries

// Virtual for full name (if needed)
userSchema.virtual('fullName').get(function() {
  return this.name;
});

// Instance method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Instance method to get user without password
userSchema.methods.toJSON = function() {
  const userObject = this.toObject();
  delete userObject.password;
  return userObject;
};

// Pre-save middleware to hash password
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();

  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Static method to find user by email
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

// Static method to find user by Firebase UID
userSchema.statics.findByFirebaseUid = function(firebaseUid) {
  return this.findOne({ firebaseUid });
};

// Instance method to update Firebase sync status
userSchema.methods.updateFirebaseSync = function(status, error = null) {
  this.firebaseSyncStatus = status;
  this.lastFirebaseSync = new Date();
  this.firebaseSyncError = error;
  return this.save();
};

// Instance method to link with Firebase user
userSchema.methods.linkFirebaseUser = function(firebaseUid) {
  this.firebaseUid = firebaseUid;
  this.firebaseSyncStatus = 'synced';
  this.lastFirebaseSync = new Date();
  this.firebaseSyncError = null;
  return this.save();
};

// Static method to get users needing Firebase sync
userSchema.statics.getNeedingFirebaseSync = function() {
  return this.find({
    $or: [
      { firebaseSyncStatus: 'pending' },
      { firebaseSyncStatus: 'error' },
      { firebaseUid: { $exists: false } }
    ]
  });
};

// Instance method to get Firebase user data format
userSchema.methods.toFirebaseUser = function() {
  return {
    uid: this.firebaseUid,
    email: this.email,
    displayName: this.name,
    phoneNumber: this.phone || null,
    emailVerified: this.isEmailVerified,
    disabled: !this.isActive,
    customClaims: {
      roles: this.roles,
      userId: this._id.toString(),
      lastLogin: this.lastLogin
    }
  };
};

module.exports = mongoose.model('User', userSchema);
