const User = require('../models/User');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const autoSyncService = require('../services/autoSyncService');

// @desc    Google OAuth Login
// @route   POST /api/auth/google
// @access  Public
exports.googleAuth = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'ID token is required'
      });
    }

    console.log('🔵 Verifying Google ID token...');

    // Verify Google ID token with Firebase
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const { uid, email, name, picture } = decodedToken;

    console.log(`✅ Token verified for: ${email}`);

    // Check if user exists
    let user = await User.findOne({ 
      $or: [
        { email },
        { firebaseUid: uid },
        { providerId: uid }
      ]
    });

    if (!user) {
      // Create new user
      user = await User.create({
        name: name || email.split('@')[0],
        email,
        password: Math.random().toString(36).slice(-16), // Random password (won't be used)
        firebaseUid: uid,
        providerId: uid,
        authProvider: 'google',
        avatar: picture,
        isEmailVerified: true,
        isActive: true,
        firebaseSyncStatus: 'synced',
        lastFirebaseSync: new Date(),
        lastLogin: new Date()
      });

      console.log(`✅ New Google user created: ${email} (ID: ${user._id})`);
      
      // Auto-sync loyalty account for new Google user
      autoSyncService.syncNewUser(user).catch(err => {
        console.error('❌ Auto-sync failed for Google user:', err.message);
      });
    } else {
      // Update existing user
      if (!user.firebaseUid) {
        user.firebaseUid = uid;
      }
      if (!user.providerId) {
        user.providerId = uid;
      }
      if (!user.authProvider || user.authProvider === 'email') {
        user.authProvider = 'google';
      }
      if (picture && !user.avatar) {
        user.avatar = picture;
      }
      user.isEmailVerified = true;
      user.lastLogin = new Date();
      user.firebaseSyncStatus = 'synced';
      user.lastFirebaseSync = new Date();
      await user.save();

      console.log(`✅ Existing user logged in via Google: ${email} (ID: ${user._id})`);
    }

    // Generate JWT token with correct payload structure
    // Auth middleware expects 'userId', not 'id'
    const token = jwt.sign(
      { 
        userId: user._id,  // Changed from 'id' to 'userId' for auth middleware compatibility
        email: user.email,
        roles: user.roles 
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        phone: user.phone,
        roles: user.roles,
        authProvider: user.authProvider,
        isEmailVerified: user.isEmailVerified
      },
      message: user.isNew ? 'Account created successfully' : 'Login successful'
    });

  } catch (error) {
    console.error('❌ Google auth error:', error);
    
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({
        success: false,
        message: 'ID token has expired. Please sign in again.'
      });
    }

    if (error.code === 'auth/invalid-id-token') {
      return res.status(401).json({
        success: false,
        message: 'Invalid ID token. Please sign in again.'
      });
    }

    res.status(400).json({
      success: false,
      message: 'Google authentication failed',
      error: error.message
    });
  }
};

// @desc    Facebook OAuth Login
// @route   POST /api/auth/facebook
// @access  Public
exports.facebookAuth = async (req, res) => {
  try {
    const { accessToken } = req.body;

    if (!accessToken) {
      return res.status(400).json({
        success: false,
        message: 'Access token is required'
      });
    }

    console.log('📘 Verifying Facebook access token...');

    // Verify Facebook access token by getting user profile
    const fetch = require('node-fetch');
    const response = await fetch(
      `https://graph.facebook.com/me?fields=id,name,email,picture.type(large)&access_token=${accessToken}`
    );
    
    if (!response.ok) {
      throw new Error('Invalid Facebook access token');
    }

    const fbUser = await response.json();
    const { id, email, name, picture } = fbUser;

    console.log(`✅ Facebook token verified for: ${email || 'No email'}`);

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email permission is required for Facebook login'
      });
    }

    // Check if user exists
    let user = await User.findOne({ 
      $or: [
        { email },
        { providerId: id }
      ]
    });

    if (!user) {
      // Create new user
      user = await User.create({
        name: name || email.split('@')[0],
        email,
        password: Math.random().toString(36).slice(-16), // Random password (won't be used)
        providerId: id,
        authProvider: 'facebook',
        avatar: picture?.data?.url,
        isEmailVerified: true,
        isActive: true,
        lastLogin: new Date(),
        socialProfiles: {
          facebook: `https://facebook.com/${id}`
        }
      });

      console.log(`✅ New Facebook user created: ${email} (ID: ${user._id})`);
      
      // Auto-sync loyalty account for new Facebook user
      autoSyncService.syncNewUser(user).catch(err => {
        console.error('❌ Auto-sync failed for Facebook user:', err.message);
      });
    } else {
      // Update existing user
      if (!user.providerId) {
        user.providerId = id;
      }
      if (!user.authProvider || user.authProvider === 'email') {
        user.authProvider = 'facebook';
      }
      if (picture?.data?.url && !user.avatar) {
        user.avatar = picture.data.url;
      }
      user.isEmailVerified = true;
      user.lastLogin = new Date();
      if (!user.socialProfiles) {
        user.socialProfiles = {};
      }
      if (!user.socialProfiles.facebook) {
        user.socialProfiles.facebook = `https://facebook.com/${id}`;
      }
      await user.save();

      console.log(`✅ Existing user logged in via Facebook: ${email} (ID: ${user._id})`);
    }

    // Generate JWT token with correct payload structure
    // Auth middleware expects 'userId', not 'id'
    const token = jwt.sign(
      { 
        userId: user._id,  // Changed from 'id' to 'userId' for auth middleware compatibility
        email: user.email,
        roles: user.roles 
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        phone: user.phone,
        roles: user.roles,
        authProvider: user.authProvider,
        isEmailVerified: user.isEmailVerified
      },
      message: user.isNew ? 'Account created successfully' : 'Login successful'
    });

  } catch (error) {
    console.error('❌ Facebook auth error:', error);
    res.status(400).json({
      success: false,
      message: 'Facebook authentication failed',
      error: error.message
    });
  }
};

// @desc    Apple OAuth Login (for future implementation)
// @route   POST /api/auth/apple
// @access  Public
exports.appleAuth = async (req, res) => {
  try {
    const { identityToken, user } = req.body;

    // Apple Sign In implementation
    // This is a placeholder for future implementation

    res.status(501).json({
      success: false,
      message: 'Apple Sign In not yet implemented'
    });

  } catch (error) {
    console.error('❌ Apple auth error:', error);
    res.status(400).json({
      success: false,
      message: 'Apple authentication failed',
      error: error.message
    });
  }
};
