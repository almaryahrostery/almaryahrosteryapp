const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const cors = require('cors');
const { inputSanitization } = require('../middleware/sanitization');

/**
 * Production-ready security middleware
 */
const securityMiddleware = (app) => {
  console.log('🛡️ Configuring security middleware...');

  // CORS Configuration
  const corsOptions = {
    origin: function (origin, callback) {
      // Allow requests with no origin (like mobile apps or curl requests)
      if (!origin) return callback(null, true);
      
      const allowedOrigins = [
        process.env.FRONTEND_URL,
        process.env.BASE_URL,
        'http://localhost:3000',
        'http://localhost:5001',
        'http://localhost:8000',  // Add admin panel origin
        'https://almaryahrostery.onrender.com'  // Correct Render URL
      ].filter(Boolean);

      if (allowedOrigins.indexOf(origin) !== -1) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: true,
    optionsSuccessStatus: 200 // Some legacy browsers choke on 204
  };

  app.use(cors(corsOptions));

  // Security headers with Helmet.js
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com", "https://cdn.jsdelivr.net"],
        styleSrcAttr: ["'unsafe-inline'"],
        scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-hashes'", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", "https://accounts.google.com"],
        scriptSrcAttr: ["'self'", "'unsafe-inline'", "'unsafe-hashes'"],
        imgSrc: ["'self'", "data:", "https:", "blob:"],
        connectSrc: ["'self'", process.env.BASE_URL, "https://al-marya-rostary.onrender.com", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com", "https://accounts.google.com"].filter(Boolean),
        fontSrc: ["'self'", "https:", "data:"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
        upgradeInsecureRequests: process.env.NODE_ENV === 'production' ? [] : null
      }
    },
    crossOriginEmbedderPolicy: false, // Disable for API compatibility
    hsts: {
      maxAge: 31536000, // 1 year
      includeSubDomains: true,
      preload: true
    },
    noSniff: true,
    frameguard: { action: 'deny' },
    xssFilter: true,
    referrerPolicy: { policy: 'same-origin' }
  }));

  // Rate limiting for API endpoints
  const apiLimiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // Limit each IP to 100 requests per window
    message: {
      success: false,
      message: 'Too many requests from this IP, please try again later.',
      retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000) / 1000)
    },
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    handler: (req, res) => {
      console.warn(`⚠️ Rate limit exceeded for IP: ${req.ip} on ${req.path}`);
      res.status(429).json({
        success: false,
        message: 'Too many requests from this IP, please try again later.',
        retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000) / 1000)
      });
    }
  });

  // More strict rate limiting for authentication endpoints
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: parseInt(process.env.LOGIN_RATE_LIMIT_MAX) || 5, // Limit each IP to 5 auth attempts per window
    skipSuccessfulRequests: true,
    message: {
      success: false,
      message: 'Too many authentication attempts from this IP, please try again later.',
      retryAfter: 900 // 15 minutes
    },
    handler: (req, res) => {
      console.warn(`🚨 Auth rate limit exceeded for IP: ${req.ip} on ${req.path}`);
      res.status(429).json({
        success: false,
        message: 'Too many authentication attempts from this IP, please try again later.',
        retryAfter: 900
      });
    }
  });

  // Apply rate limiting
  app.use('/api/', apiLimiter);
  app.use('/api/auth/login', authLimiter);
  app.use('/api/auth/admin-login', authLimiter);
  app.use('/api/auth/register', authLimiter);
  app.use('/api/auth/forgot-password', authLimiter);

  // Data sanitization against NoSQL injection attacks
  app.use(mongoSanitize({
    replaceWith: '_'
  }));

  // Comprehensive input sanitization (XSS, SQL injection, path traversal protection)
  app.use(inputSanitization({
    sizeLimit: {
      maxBodySize: '10mb',
      maxParamLength: 1000,
      maxQueryParams: 50,
      maxHeaderSize: 8192
    }
  }));

  // Trust proxy for accurate IP addresses (important for Render.com)
  app.set('trust proxy', 1);

  // Request size limits
  app.use('/api/upload', (req, res, next) => {
    // Larger limit for file uploads
    req.setTimeout(30000); // 30 seconds timeout for uploads
    next();
  });

  console.log('✅ Security middleware configured successfully');
};

/**
 * Additional security headers middleware
 */
const additionalSecurityHeaders = (req, res, next) => {
  // Remove powered by header
  res.removeHeader('X-Powered-By');
  
  // Add custom security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  // Cache control for API responses
  if (req.path.startsWith('/api/')) {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
  }
  
  next();
};

/**
 * Error handling for security middleware
 */
const securityErrorHandler = (error, req, res, next) => {
  // CORS errors
  if (error.message === 'Not allowed by CORS') {
    console.warn(`🚨 CORS violation from origin: ${req.get('Origin')} IP: ${req.ip}`);
    return res.status(403).json({
      success: false,
      message: 'Access denied by CORS policy'
    });
  }

  // Rate limit errors
  if (error.status === 429) {
    return res.status(429).json({
      success: false,
      message: 'Rate limit exceeded'
    });
  }

  // Other security-related errors
  console.error('Security middleware error:', error);
  next(error);
};

module.exports = {
  securityMiddleware,
  additionalSecurityHeaders,
  securityErrorHandler
};
