const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      enum: ['Home', 'Work', 'Other'],
    },
    fullAddress: {
      type: String,
      required: true,
      trim: true,
    },
    buildingName: {
      type: String,
      trim: true,
      default: '',
    },
    streetName: {
      type: String,
      required: true,
      trim: true,
    },
    area: {
      type: String,
      required: true,
      trim: true,
    },
    city: {
      type: String,
      required: true,
      trim: true,
      default: 'Dubai',
    },
    flatNumber: {
      type: String,
      trim: true,
      default: '',
    },
    floorNumber: {
      type: String,
      trim: true,
      default: '',
    },
    landmark: {
      type: String,
      trim: true,
      default: '',
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
        validate: {
          validator: function (coords) {
            return (
              coords.length === 2 &&
              coords[0] >= -180 &&
              coords[0] <= 180 &&
              coords[1] >= -90 &&
              coords[1] <= 90
            );
          },
          message: 'Invalid coordinates',
        },
      },
    },
    contactName: {
      type: String,
      required: true,
      trim: true,
    },
    contactNumber: {
      type: String,
      required: true,
      trim: true,
      validate: {
        validator: function (v) {
          return /^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$/.test(
            v
          );
        },
        message: 'Invalid phone number format',
      },
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
    addressType: {
      type: String,
      enum: ['apartment', 'villa', 'office', 'other'],
      default: 'apartment',
    },
    deliveryInstructions: {
      type: String,
      trim: true,
      default: '',
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  }
);

// Create geospatial index for location-based queries
addressSchema.index({ location: '2dsphere' });

// Create compound index for user queries
addressSchema.index({ userId: 1, isDefault: -1, createdAt: -1 });

// Pre-save middleware to ensure only one default address per user
addressSchema.pre('save', async function (next) {
  if (this.isDefault && this.isModified('isDefault')) {
    await this.constructor.updateMany(
      {
        userId: this.userId,
        _id: { $ne: this._id },
      },
      { $set: { isDefault: false } }
    );
  }
  next();
});

// Method to get formatted address
addressSchema.methods.getFormattedAddress = function () {
  const parts = [];

  if (this.flatNumber) parts.push(`Flat ${this.flatNumber}`);
  if (this.floorNumber) parts.push(`Floor ${this.floorNumber}`);
  if (this.buildingName) parts.push(this.buildingName);
  parts.push(this.streetName);
  parts.push(this.area);
  parts.push(this.city);

  return parts.filter(Boolean).join(', ');
};

// Method to calculate distance from a point (in kilometers)
addressSchema.methods.calculateDistance = function (latitude, longitude) {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(latitude - this.location.coordinates[1]);
  const dLon = toRad(longitude - this.location.coordinates[0]);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(this.location.coordinates[1])) *
      Math.cos(toRad(latitude)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

function toRad(degrees) {
  return (degrees * Math.PI) / 180;
}

// Virtual for getting icon based on address type
addressSchema.virtual('icon').get(function () {
  const icons = {
    apartment: 'apartment',
    villa: 'home',
    office: 'business',
    other: 'location_on',
  };
  return icons[this.addressType] || 'location_on';
});

// Ensure virtuals are included when converting to JSON
addressSchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    ret.latitude = ret.location.coordinates[1];
    ret.longitude = ret.location.coordinates[0];
    delete ret.location;
    delete ret.__v;
    return ret;
  },
});

const Address = mongoose.model('Address', addressSchema);

module.exports = Address;
