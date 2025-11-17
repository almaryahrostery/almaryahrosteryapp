const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const compression = require('compression');
require('dotenv').config();

// Security: Validate environment variables before starting server
const { validateAndExit } = require('./config/validation');
validateAndExit();

// 🔥 Updated: 2025-11-13 - Order routes now use Firebase authentication

// Import optimized configurations
const { connectDB } = require('./config/database');
const { securityMiddleware, additionalSecurityHeaders, securityErrorHandler } = require('./config/security');
const { performanceMiddleware, createCacheMiddleware, optimizeJsonResponse } = require('./config/performance');
const { monitoring } = require('./config/monitoring');
// ⚡ NEW: Import performance monitoring
const { performanceMonitoring, startPerformanceReporting } = require('./middleware/performanceMonitoring');
// ⚡ NEW: Import JSON serialization middleware to fix ObjectId serialization
const { serializeResponse } = require('./middleware/jsonSerializer');

const app = express();

console.log('🚀 Starting Al Marya Rostery Server...');

// Initialize monitoring system
monitoring.initializeMiddleware(app);

// ⚡ NEW: Add performance monitoring middleware (MUST BE FIRST to track all requests)
app.use(performanceMonitoring);

// ⚡ PERFORMANCE: Enable compression for all responses (gzip/deflate)
app.use(compression({
  threshold: 1024, // Only compress responses larger than 1KB
  level: 6, // Compression level (0-9, 6 is balanced)
  filter: (req, res) => {
    // Don't compress if explicitly disabled or if already compressed
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  }
}));

// Security middleware (must be first)
securityMiddleware(app);

// Performance middleware
performanceMiddleware(app);

// Additional security headers
app.use(additionalSecurityHeaders);

// ⚡ NEW: JSON serialization middleware (fixes ObjectId buffer issue with .lean())
app.use(serializeResponse);

// JSON optimization
app.use(optimizeJsonResponse);

// Request logging (only in development)
if (process.env.NODE_ENV !== 'production') {
  const morgan = require('morgan');
  app.use(morgan('combined'));
}

// Conditional JSON parsing middleware - skip for multipart/form-data
app.use((req, res, next) => {
  const contentType = req.headers['content-type'];
  if (contentType && contentType.startsWith('multipart/form-data')) {
    // Skip JSON parsing for multipart data, let multer handle it
    return next();
  }
  express.json({ limit: '10mb' })(req, res, next);
});

app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ⚡ PERFORMANCE: Serve static files with aggressive caching
// JavaScript files with 1 day cache
app.use('/js', express.static(path.join(__dirname, 'public/js'), {
  maxAge: '1d',          // Cache for 1 day
  etag: true,            // Enable ETags for cache validation
  lastModified: true,    // Enable Last-Modified headers
  immutable: false       // Allow revalidation
}));

// CSS files with 1 day cache
app.use('/css', express.static(path.join(__dirname, 'public/css'), {
  maxAge: '1d',
  etag: true,
  lastModified: true
}));

// Images with 7 day cache (images change less frequently)
app.use('/images', express.static(path.join(__dirname, 'public/images'), {
  maxAge: '7d',
  etag: true,
  lastModified: true,
  immutable: true        // Images are immutable once uploaded
}));

// Icons with 30 day cache (rarely change)
app.use('/icons', express.static(path.join(__dirname, 'public/icons'), {
  maxAge: '30d',
  etag: true,
  lastModified: true,
  immutable: true
}));

// Serve uploads directory with shorter cache (user-generated content)
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
  maxAge: '1d',
  etag: true,
  lastModified: true
}));

// Serve remaining public files (HTML, etc.) with shorter cache
app.use(express.static(path.join(__dirname, 'public'), {
  maxAge: '5m',          // 5 minutes for HTML files
  etag: true,
  lastModified: true
}));

// Database connection is now handled by the imported connectDB function

// Routes
app.get('/', (req, res) => {
  // Check if request accepts HTML (browser request)
  if (req.headers.accept && req.headers.accept.includes('text/html')) {
    // Serve business portal for browser requests
    res.sendFile(path.join(__dirname, 'public/index.html'));
  } else {
    // Serve JSON API info for API requests
    res.json({
      message: 'Qahwat Al Emarat API Server',
      status: 'Running',
      mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development'
    });
  }
});

// Favicon route
app.get('/favicon.ico', (req, res) => {
  res.sendFile(path.join(__dirname, 'public/favicon.png'));
});

// Setup comprehensive health check endpoints
monitoring.setupHealthEndpoints(app);

// API Routes with caching for public data
app.use('/api/config', require('./routes/config')); // Public configuration (Stripe, etc.)
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));

// Cached routes for better performance
app.use('/api/coffees', createCacheMiddleware({ ttl: 300 }), require('./routes/coffees')); // 5 min cache
app.use('/api/categories', createCacheMiddleware({ ttl: 600 }), require('./routes/categories')); // 10 min cache
app.use('/api/attributes', createCacheMiddleware({ ttl: 600 }), require('./routes/attributes')); // 10 min cache - NEW
app.use('/api/sliders', createCacheMiddleware({ ttl: 300 }), require('./routes/sliders')); // 5 min cache
app.use('/api/quick-categories', createCacheMiddleware({ ttl: 300 }), require('./routes/quickCategories')); // 5 min cache
app.use('/api/brewing-methods', createCacheMiddleware({ ttl: 600 }), require('./routes/brewingMethods')); // 10 min cache
app.use('/api/accessories', createCacheMiddleware({ ttl: 300 }), require('./routes/accessories')); // 5 min cache
app.use('/api/accessory-types', createCacheMiddleware({ ttl: 600 }), require('./routes/accessoryTypes')); // 10 min cache
app.use('/api/gift-sets', createCacheMiddleware({ ttl: 300 }), require('./routes/giftSets')); // 5 min cache

// Non-cached routes (user-specific or frequently changing)
// Order tracking with real-time updates
app.use('/api/tracking', require('./routes/tracking')); // NEW: Real-time order tracking
app.use('/api/orders', require('./routes/userOrders')); // User order management
app.use('/api/wishlist', require('./routes/wishlist')); // User wishlist management
app.use('/api/addresses', require('./routes/addresses')); // User address management
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/newsletters', require('./routes/newsletters'));
app.use('/api/support-tickets', require('./routes/support'));
app.use('/api/feedback', require('./routes/feedback'));

// ⚡ OPTIMIZED: Analytics with authenticated caching (60s for dashboard, 120s for reports)
app.use('/api/analytics', createCacheMiddleware({ 
  ttl: 60, 
  cacheAuthenticated: true  // Enable caching for authenticated admin requests
}), require('./routes/analytics'));

app.use('/api/contact-inquiries', require('./routes/contactInquiries'));

// ===== PHASE 6: STAFF & DRIVER ROUTES =====
app.use('/api/staff/auth', require('./routes/staffAuth')); // PIN + QR Badge Authentication (Phase 6.2)
app.use('/api/staff/admin', require('./routes/staffAdminAuth')); // Staff Admin Panel Authentication (Username/Password)
app.use('/api/staff/products', require('./routes/staffProducts')); // Staff Product Management (Staff Admin)
app.use('/api/staff', require('./routes/staff')); // Staff App API (Legacy Firebase)
app.use('/api/driver/auth', require('./routes/driverAuth').router); // Driver PIN + QR Authentication
app.use('/api/driver', require('./routes/driverOrders')); // Driver App API (PIN-based)

// ===== SECURITY ROUTES =====
app.use('/api/security', require('./routes/security')); // Certificate pins & security configuration (public)

// ===== ADMIN ROUTES =====
// Bulk staff import (must be before main staff routes to avoid path conflicts)
app.use('/api/admin/staff', require('./routes/admin/bulkStaffImport')); // Bulk CSV import

// ⚡ OPTIMIZED: Staff management with authenticated caching (2 min for list/stats)
app.use('/api/admin/staff', createCacheMiddleware({ 
  ttl: 120, 
  cacheAuthenticated: true  // Enable caching for authenticated admin requests
}), require('./routes/admin/staffManagement')); // Admin Staff Management (Phase 6.2)

// ⚡ OPTIMIZED: Driver management with authenticated caching (2 min for list/stats)
app.use('/api/admin/drivers', createCacheMiddleware({ 
  ttl: 120, 
  cacheAuthenticated: true  // Enable caching for authenticated admin requests
}), require('./routes/admin/drivers')); // Admin Driver Management

// Debug routes (for development)
app.use('/api/debug', require('./routes/debug'));

// Email testing routes (admin only)
app.use('/api/test', require('./routes/emailTest'));

// Firebase Sync Routes
// ⚡ OPTIMIZED: Firebase sync with authenticated caching (2 min for user lists)
app.use('/api/firebase-sync', createCacheMiddleware({ 
  ttl: 120, 
  cacheAuthenticated: true  // Enable caching for authenticated admin requests
}), require('./routes/firebaseSync'));

// Auto Firebase Sync Routes
app.use('/api/auto-sync', require('./routes/autoSync'));

// New Feature Routes
// ⚠️ DEPRECATED: /api/reviews - Use /api/feedback instead (migrated Nov 3, 2025)
// Kept for backward compatibility only. See backend/REVIEW_MIGRATION_GUIDE.md
// ⚡ OPTIMIZED: Cache admin stats endpoints (2 min TTL)
app.use('/api/reviews', createCacheMiddleware({ 
  ttl: 120, 
  cacheAuthenticated: true 
}), require('./routes/reviews'));

app.use('/api/loyalty', createCacheMiddleware({ 
  ttl: 120, 
  cacheAuthenticated: true 
}), require('./routes/loyalty'));

app.use('/api/referrals', createCacheMiddleware({ 
  ttl: 120, 
  cacheAuthenticated: true 
}), require('./routes/referrals'));

app.use('/api/subscriptions', createCacheMiddleware({ 
  ttl: 120, 
  cacheAuthenticated: true 
}), require('./routes/subscriptions'));

// Public settings route (no auth required)
const { getPublicSettings } = require('./controllers/settingsController');
app.get('/api/settings/public', getPublicSettings);
app.get('/api/settings', getPublicSettings); // FIXED: Add general settings route for admin panel

// ⚡ NEW: Performance metrics endpoint (admin only)
const { getPerformanceMetrics } = require('./middleware/performanceMonitoring');
const { cacheManager } = require('./utils/cacheManager');
const { memoryCache, cacheUtils } = require('./config/performance');

app.get('/api/admin/performance', (req, res) => {
  try {
    const metrics = getPerformanceMetrics();
    
    // Add node-cache stats (the actual cache being used)
    const nodeCacheStats = memoryCache.getStats();
    const nodeCacheKeys = memoryCache.keys();
    
    res.json({
      success: true,
      data: {
        ...metrics,
        activeCache: {
          type: 'node-cache',
          stats: nodeCacheStats,
          keyCount: nodeCacheKeys.length,
          hitRate: nodeCacheStats.hits > 0 
            ? `${((nodeCacheStats.hits / (nodeCacheStats.hits + nodeCacheStats.misses)) * 100).toFixed(1)}%`
            : '0%'
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get performance metrics',
      error: error.message
    });
  }
});

// ⚡ NEW: Cache stats endpoint (admin only)
app.get('/api/admin/cache-stats', (req, res) => {
  try {
    const stats = cacheManager.getStats();
    const memory = cacheManager.getMemoryInfo();
    res.json({
      success: true,
      data: {
        stats,
        memory
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get cache stats',
      error: error.message
    });
  }
});

// Admin panel route (serve index.html for consistency)
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public/index.html'));
});

// Payment Routes (Stripe/PayPal integration)
app.use('/api/payment', require('./routes/payment'));

// Admin Routes
app.use('/api/admin', require('./routes/admin'));
app.use('/api/admin/settings', require('./routes/settings'));
app.use('/api/admin/orders', require('./routes/orders'));
app.use('/api/admin/reports', require('./routes/reports'));
app.use('/api/admin/token-blacklist', require('./routes/tokenBlacklist'));

// Public Admin Routes (for local development - no auth required)
app.use('/api/public-admin', require('./routes/public-admin'));
app.use('/api/public-admin/orders', require('./routes/public-admin-orders'));
app.use('/api/public-admin/settings', require('./routes/public-admin-settings'));

// Import standardized error handling
const { globalErrorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Security error handler
app.use(securityErrorHandler);

// 404 handler - must be before global error handler
app.use(notFoundHandler);

// Custom 404 handler for admin-related requests
app.use((req, res, next) => {
  const url = req.originalUrl.toLowerCase();
  
  // Check if this might be an admin-related request
  if (url.includes('admin') || url.includes('dashboard') || url.includes('panel') || 
      url.includes('manager') || url.includes('control') || url.includes('backend')) {
    
    console.log(`ℹ️  Admin-related 404: ${req.method} ${req.originalUrl} - suggesting redirect to /`);
    
    // If it's an HTML request, redirect to admin panel
    if (req.accepts('html')) {
      return res.redirect(301, '/');
    }
    
    // If it's an API request, provide helpful JSON response
    return res.status(404).json({
      success: false,
      message: 'Admin endpoint not found',
      suggestion: 'The admin panel is available at /',
      available_endpoints: {
        admin_panel: '/',
        health_check: '/health',
        api_docs: '/api'
      }
    });
  }
  
  // Continue to default 404 handler
  next();
});

// Global error handler - must be last
app.use(globalErrorHandler);

const PORT = process.env.PORT || 10000;

// Production-ready server startup
const startServer = async () => {
  try {
    console.log('🔧 Initializing application...');
    
    // Connect to database with retry logic
    await connectDB();
    
    // Start Auto Firebase Sync Service if enabled
    const autoFirebaseSync = require('./services/autoFirebaseSync');
    if (process.env.ENABLE_AUTO_FIREBASE_SYNC !== 'false') {
      setTimeout(() => {
        autoFirebaseSync.start();
        console.log('🔄 Auto Firebase Sync Service enabled');
      }, 5000); // Start after 5 seconds to ensure everything is initialized
    } else {
      console.log('⚠️ Auto Firebase Sync Service disabled via environment variable');
    }
    
    // Setup graceful shutdown
    monitoring.setupGracefulShutdown();
    
    // Start periodic health checks
    monitoring.startPeriodicHealthChecks();
    
    // ⚡ NEW: Start performance reporting (every 5 minutes)
    startPerformanceReporting();
    
    // Start the server
    const server = app.listen(PORT, () => {
      console.log(`🎉 Al Marya Rostery Server Started Successfully!`);
      console.log(`🌐 Server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`📱 API available at: http://localhost:${PORT}`);
      console.log(`🔍 Health check: http://localhost:${PORT}/health`);
      console.log(`⚡ Performance optimizations: ENABLED`);
      console.log(`🛡️ Security middleware: ENABLED`);
      console.log(`📈 Monitoring: ENABLED`);
      console.log(`📊 Performance tracking: ENABLED`);
      console.log(`💾 In-memory cache: ENABLED`);
    });

    // Initialize Socket.IO for real-time tracking
    try {
      const { initializeSocket } = require('./services/socketService');
      const io = initializeSocket(server);
      app.set('io', io);
      console.log('🔌 Socket.IO initialized for real-time order tracking');
    } catch (error) {
      console.warn('⚠️ Socket.IO initialization failed:', error.message);
      console.warn('   Real-time tracking features will be disabled');
    }

    // Initialize Socket.IO for real-time tracking
    const { initializeSocket } = require('./services/socketService');
    const io = initializeSocket(server);
    app.set('io', io);
    console.log('🔌 Socket.IO initialized for real-time tracking');

    // Handle server errors
    server.on('error', (error) => {
      if (error.syscall !== 'listen') {
        throw error;
      }

      switch (error.code) {
        case 'EACCES':
          console.error(`� Port ${PORT} requires elevated privileges`);
          process.exit(1);
          break;
        case 'EADDRINUSE':
          console.error(`💥 Port ${PORT} is already in use`);
          process.exit(1);
          break;
        default:
          throw error;
      }
    });

    return server;
  } catch (error) {
    console.error('� Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();

module.exports = app;
