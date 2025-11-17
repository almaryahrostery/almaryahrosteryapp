const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const User = require('../models/User');
const { isBlacklisted } = require('../utils/tokenBlacklist');

// Security: Validate JWT_SECRET on module load
if (!process.env.JWT_SECRET) {
  console.error('FATAL: JWT_SECRET environment variable is not set. Authentication will fail.');
  process.exit(1);
}

// Security: Validate JWT_SECRET strength
if (process.env.JWT_SECRET.length < 32) {
  console.error('WARNING: JWT_SECRET is too short. Use at least 32 characters for security.');
}

// 🔄 HYBRID AUTH: Accepts both Firebase ID tokens and Backend JWT tokens
// This ensures backward compatibility and seamless migration
const protect = async (req, res, next) => {
  try {
    let token;

    // Check for token in header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to access this route'
      });
    }

    try {
      // 🔍 STEP 1: Try to verify as Backend JWT token first
      let decoded;
      let isFirebaseToken = false;
      
      try {
        decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Security: Check if token has been blacklisted (revoked)
        if (isBlacklisted(token)) {
          return res.status(401).json({
            success: false,
            message: 'Token has been revoked. Please login again.'
          });
        }
        
        console.log('✅ Backend JWT token verified');
      } catch (jwtError) {
        // 🔍 STEP 2: If JWT verification fails, try Firebase ID token
        console.log('⚠️ Not a backend JWT, trying Firebase ID token...');
        
        try {
          const firebaseDecoded = await admin.auth().verifyIdToken(token);
          console.log('✅ Firebase ID token verified:', firebaseDecoded.email);
          
          // Convert Firebase token data to our format
          decoded = {
            userId: firebaseDecoded.uid,
            email: firebaseDecoded.email,
            isFirebaseToken: true
          };
          isFirebaseToken = true;
        } catch (firebaseError) {
          console.error('❌ Token verification failed (both JWT and Firebase):', {
            jwtError: jwtError.message,
            firebaseError: firebaseError.message
          });
          
          return res.status(401).json({
            success: false,
            message: 'Invalid token format'
          });
        }
      }

      // 🔍 STEP 3: Handle admin tokens
      if (decoded.userId === 'admin' || decoded.role === 'admin') {
        req.user = {
          userId: 'admin',
          email: 'admin',
          roles: ['admin'],
          isActive: true
        };
        return next();
      }

      // 🔍 STEP 4: Find user in database
      let user;
      
      if (isFirebaseToken) {
        // For Firebase tokens, search by Firebase UID or email
        user = await User.findOne({
          $or: [
            { firebaseUid: decoded.userId },
            { providerId: decoded.userId },
            { email: decoded.email }
          ]
        });
        
        if (!user) {
          console.error('❌ User not found for Firebase UID:', decoded.userId);
          return res.status(401).json({
            success: false,
            message: 'User not found. Please login again.'
          });
        }
        
        console.log(`✅ User found via Firebase token: ${user.email} (ID: ${user._id})`);
      } else {
        // For backend JWT tokens, search by user ID
        if (!decoded.userId || decoded.userId === 'admin') {
          return res.status(401).json({
            success: false,
            message: 'Invalid token format'
          });
        }

        user = await User.findById(decoded.userId);

        if (!user) {
          return res.status(401).json({
            success: false,
            message: 'User not found'
          });
        }
        
        console.log(`✅ User found via JWT token: ${user.email} (ID: ${user._id})`);
      }

      // Check if user is active
      if (!user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'User account is deactivated'
        });
      }

      req.user = {
        userId: user._id,
        email: user.email,
        roles: user.roles,
        isActive: user.isActive
      };

      next();
    } catch (error) {
      // Security: Log verification errors for monitoring
      console.error('Auth middleware error:', {
        error: error.message,
        token: token?.substring(0, 20) + '...', // Log only first 20 chars for debugging
        timestamp: new Date().toISOString()
      });

      // Security: Return generic error message to prevent information leakage
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error in authentication'
    });
  }
};

// Check if user has required role
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to access this route'
      });
    }

    if (!roles.some(role => req.user.roles.includes(role))) {
      return res.status(403).json({
        success: false,
        message: `User role ${req.user.roles.join(', ')} is not authorized to access this route`
      });
    }

    next();
  };
};

// Optional authentication - doesn't fail if no token
const optionalAuth = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (token) {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Handle admin tokens specially - check BEFORE any database queries
        if (decoded.userId === 'admin' || decoded.role === 'admin') {
          req.user = {
            userId: 'admin',
            email: 'admin',
            roles: ['admin'],
            isActive: true
          };
          return next();
        }

        // Only query database if userId is not 'admin'
        if (decoded.userId && decoded.userId !== 'admin') {
          const user = await User.findById(decoded.userId);

          if (user && user.isActive) {
            req.user = {
              userId: user._id,
              email: user.email,
              roles: user.roles,
              isActive: user.isActive
            };
          }
        }
      } catch (error) {
        // Silent fail for optional auth
        console.log('Optional auth failed:', error.message);
      }
    }

    next();
  } catch (error) {
    next();
  }
};

module.exports = {
  protect,
  authorize,
  optionalAuth
};
