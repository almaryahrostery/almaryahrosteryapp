const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true // Automatically creates an index
  },
  value: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  dataType: {
    type: String,
    enum: ['string', 'number', 'boolean', 'object', 'array'],
    default: 'string'
  },
  category: {
    type: String,
    required: true,
    enum: [
      'general',
      'business',
      'email',
      'payment',
      'social',
      'api',
      'security',
      'notification'
    ],
    default: 'general'
  },
  description: {
    type: String,
    default: ''
  },
  isPublic: {
    type: Boolean,
    default: false // Whether this setting can be accessed by frontend/public API
  },
  isRequired: {
    type: Boolean,
    default: false
  },
  validationRules: {
    type: Object,
    default: {}
  }
}, {
  timestamps: true
});

// Static method to get setting by key
settingsSchema.statics.getSetting = async function(key, defaultValue = null) {
  try {
    const setting = await this.findOne({ key });
    return setting ? setting.value : defaultValue;
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error getting setting', { key, error: error.message });
    return defaultValue;
  }
};

// Static method to set setting
settingsSchema.statics.setSetting = async function(key, value, options = {}) {
  try {
    const {
      dataType = typeof value,
      category = 'general',
      description = '',
      isPublic = false,
      isRequired = false,
      validationRules = {}
    } = options;

    const setting = await this.findOneAndUpdate(
      { key },
      {
        key,
        value,
        dataType,
        category,
        description,
        isPublic,
        isRequired,
        validationRules
      },
      {
        upsert: true,
        new: true,
        runValidators: true
      }
    );

    return setting;
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error setting value', { key, error: error.message });
    throw error;
  }
};

// Static method to get multiple settings by category
settingsSchema.statics.getSettingsByCategory = async function(category, includePrivate = false) {
  try {
    const query = { category };
    if (!includePrivate) {
      query.isPublic = true;
    }
    
    const settings = await this.find(query).sort({ key: 1 });
    const result = {};
    
    settings.forEach(setting => {
      result[setting.key] = setting.value;
    });
    
    return result;
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Error getting settings by category', { category, error: error.message });
    return {};
  }
};

// Static method to initialize default settings
settingsSchema.statics.initializeDefaults = async function() {
  const defaults = [
    // General Settings
    { key: 'app_name', value: 'Qahwat Al Emarat', category: 'general', description: 'Application name', isPublic: true },
    { key: 'app_description', value: 'Premium Arabic Coffee Experience', category: 'general', description: 'Application description', isPublic: true },
    { key: 'contact_email', value: 'info@qahwatalemarat.com', category: 'general', description: 'Contact email address', isPublic: true },
    { key: 'contact_phone', value: '+971 025842392', category: 'general', description: 'Business contact phone number', isPublic: true },
    { key: 'address', value: 'Dubai, UAE', category: 'general', description: 'Business address', isPublic: true },
    { key: 'store_latitude', value: '', category: 'general', description: 'Store latitude coordinate for Google Maps', isPublic: true },
    { key: 'store_longitude', value: '', category: 'general', description: 'Store longitude coordinate for Google Maps', isPublic: true },
    { key: 'maintenance_mode', value: false, category: 'general', description: 'Enable maintenance mode', dataType: 'boolean' },
    
    // Business Settings
    { key: 'currency', value: 'AED', category: 'business', description: 'Default currency', isPublic: true },
    { key: 'currency_symbol', value: 'د.إ', category: 'business', description: 'Currency symbol', isPublic: true },
    { key: 'timezone', value: 'Asia/Dubai', category: 'business', description: 'Default timezone', isPublic: true },
    { key: 'date_format', value: 'DD/MM/YYYY', category: 'business', description: 'Date format', isPublic: true },
    { key: 'business_hours', value: '9:00 AM - 10:00 PM', category: 'business', description: 'Business hours', isPublic: true },
    { key: 'minimum_order_amount', value: 50, category: 'business', description: 'Minimum order amount', dataType: 'number', isPublic: true },
    { key: 'delivery_fee', value: 15, category: 'business', description: 'Delivery fee', dataType: 'number', isPublic: true },
    { key: 'free_delivery_threshold', value: 200, category: 'business', description: 'Free delivery threshold', dataType: 'number', isPublic: true },
    { key: 'tax_rate', value: 5, category: 'business', description: 'Tax rate percentage', dataType: 'number', isPublic: true },
    { key: 'primary_color', value: '#8B4513', category: 'business', description: 'Primary brand color', isPublic: true },
    { key: 'secondary_color', value: '#D2691E', category: 'business', description: 'Secondary brand color', isPublic: true },
    { key: 'logo_url', value: '/assets/images/logo.png', category: 'business', description: 'Logo URL', isPublic: true },
    { key: 'low_stock_notifications', value: true, category: 'notification', description: 'Enable low stock notifications', dataType: 'boolean' },
    
    // Email Settings
    { key: 'smtp_host', value: '', category: 'email', description: 'SMTP server host' },
    { key: 'smtp_port', value: 587, category: 'email', description: 'SMTP server port', dataType: 'number' },
    { key: 'smtp_username', value: '', category: 'email', description: 'SMTP username' },
    { key: 'smtp_password', value: '', category: 'email', description: 'SMTP password' },
    { key: 'smtp_secure', value: true, category: 'email', description: 'Use secure SMTP', dataType: 'boolean' },
    { key: 'email_from_name', value: 'Qahwat Al Emarat', category: 'email', description: 'Email sender name', isPublic: true },
    { key: 'email_from_address', value: 'noreply@qahwatalemarat.com', category: 'email', description: 'Email sender address' },
    
    // Payment Settings
    { key: 'stripe_publishable_key', value: '', category: 'payment', description: 'Stripe publishable key', isPublic: true },
    { key: 'stripe_secret_key', value: '', category: 'payment', description: 'Stripe secret key' },
    { key: 'paypal_client_id', value: '', category: 'payment', description: 'PayPal client ID', isPublic: true },
    { key: 'paypal_client_secret', value: '', category: 'payment', description: 'PayPal client secret' },
    { key: 'payment_methods_enabled', value: ['cash', 'card'], category: 'payment', description: 'Enabled payment methods', dataType: 'array', isPublic: true },
    
    // Social Media
    { key: 'facebook_url', value: '', category: 'social', description: 'Facebook page URL', isPublic: true },
    { key: 'instagram_url', value: '', category: 'social', description: 'Instagram profile URL', isPublic: true },
    { key: 'twitter_url', value: '', category: 'social', description: 'Twitter profile URL', isPublic: true },
    { key: 'whatsapp_number', value: '', category: 'social', description: 'WhatsApp business number', isPublic: true },
    
    // API Keys
    { key: 'google_maps_api_key', value: '', category: 'api', description: 'Google Maps API key' },
    { key: 'firebase_server_key', value: '', category: 'api', description: 'Firebase server key for push notifications' },
    { key: 'sms_api_key', value: '', category: 'api', description: 'SMS service API key' },
    
    // Security Settings
    { key: 'max_login_attempts', value: 5, category: 'security', description: 'Maximum login attempts', dataType: 'number' },
    { key: 'lockout_duration', value: 30, category: 'security', description: 'Account lockout duration (minutes)', dataType: 'number' },
    { key: 'session_timeout', value: 24, category: 'security', description: 'Session timeout (hours)', dataType: 'number' },
    { key: 'require_email_verification', value: true, category: 'security', description: 'Require email verification', dataType: 'boolean' },
    
    // Notification Settings
    { key: 'push_notifications_enabled', value: true, category: 'notification', description: 'Enable push notifications', dataType: 'boolean', isPublic: true },
    { key: 'email_notifications_enabled', value: true, category: 'notification', description: 'Enable email notifications', dataType: 'boolean' },
    { key: 'sms_notifications_enabled', value: false, category: 'notification', description: 'Enable SMS notifications', dataType: 'boolean' },
    { key: 'order_status_notifications', value: true, category: 'notification', description: 'Send order status notifications', dataType: 'boolean', isPublic: true }
  ];

  for (const setting of defaults) {
    await this.setSetting(setting.key, setting.value, {
      category: setting.category,
      description: setting.description,
      dataType: setting.dataType || 'string',
      isPublic: setting.isPublic || false,
      isRequired: setting.isRequired || false
    });
  }

  const logger = require('../utils/logger');
  logger.info('Default settings initialized');
};

module.exports = mongoose.model('Settings', settingsSchema);
