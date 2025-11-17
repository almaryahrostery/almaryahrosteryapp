const mongoose = require('mongoose');

// Timeline entry subdocument
const timelineEntrySchema = new mongoose.Schema({
  stage: {
    type: String,
    required: true,
    enum: [
      'accepted_by_staff',
      'preparing',
      'ready_for_handover',
      'picked_by_driver',
      'on_the_way',
      'arriving',
      'delivered',
      'cancelled'
    ]
  },
  time: {
    type: Date,
    required: true,
    default: Date.now
  },
  message: String
}, { _id: false });

// Location subdocument
const locationSchema = new mongoose.Schema({
  lat: {
    type: Number,
    required: true
  },
  lng: {
    type: Number,
    required: true
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  speed: Number,
  heading: Number
}, { _id: false });

// ETA subdocument
const etaSchema = new mongoose.Schema({
  start: {
    type: Date,
    required: true
  },
  end: {
    type: Date,
    required: true
  },
  distanceMeters: Number,
  durationSeconds: Number
}, { _id: false });

// Order tracking schema extension
const orderTrackingSchema = new mongoose.Schema({
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    required: true,
    unique: true
  },
  status: {
    type: String,
    required: true,
    enum: [
      'accepted_by_staff',
      'preparing',
      'ready_for_handover',
      'picked_by_driver',
      'on_the_way',
      'arriving',
      'delivered',
      'cancelled'
    ],
    default: 'preparing'
  },
  staffLocation: locationSchema,
  driverLocation: locationSchema,
  userLocation: locationSchema,
  eta: etaSchema,
  timeline: [timelineEntrySchema],
  isDriverStationary: {
    type: Boolean,
    default: false
  },
  lastUpdate: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Update lastUpdate timestamp before saving
orderTrackingSchema.pre('save', function(next) {
  this.lastUpdate = new Date();
  next();
});

// Add timeline entry method
orderTrackingSchema.methods.addTimelineEntry = function(stage, message) {
  this.timeline.push({
    stage,
    time: new Date(),
    message
  });
};

// Update status method
orderTrackingSchema.methods.updateStatus = function(newStatus, message) {
  this.status = newStatus;
  this.addTimelineEntry(newStatus, message);
};

module.exports = mongoose.model('OrderTracking', orderTrackingSchema);
