const mongoose = require('mongoose');

const otpSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  email: {
    type: String,
    required: function() {
      return !this.mobile;
    }
  },
  mobile: {
    type: String,
    required: function() {
      return !this.email;
    }
  },
  otp: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['signup', 'password_reset', 'login'],
    default: 'password_reset'
  },
  attempts: {
    type: Number,
    default: 0,
    max: 3
  },
  verified: {
    type: Boolean,
    default: false
  },
  expiresAt: {
    type: Date,
    required: true,
    // OTP expires in 5 minutes
    default: () => new Date(Date.now() + 5 * 60 * 1000)
  }
}, {
  timestamps: true
});

// Index for automatic deletion of expired OTPs
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Index for faster queries
otpSchema.index({ user: 1, type: 1 });
otpSchema.index({ email: 1, type: 1 });
otpSchema.index({ mobile: 1, type: 1 });

// Method to check if OTP is expired
otpSchema.methods.isExpired = function() {
  return this.expiresAt < new Date();
};

// Method to check if max attempts reached
otpSchema.methods.maxAttemptsReached = function() {
  return this.attempts >= 3;
};

// Method to increment attempts
otpSchema.methods.incrementAttempts = function() {
  this.attempts += 1;
  return this.save();
};

module.exports = mongoose.model('Otp', otpSchema);
