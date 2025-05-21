const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: [true, 'Please add a notification title'],
    trim: true,
    maxlength: [100, 'Title cannot be more than 100 characters']
  },
  message: {
    type: String,
    required: [true, 'Please add a notification message'],
    maxlength: [500, 'Message cannot be more than 500 characters']
  },
  type: {
    type: String,
    enum: ['info', 'success', 'warning', 'error', 'budget', 'transaction', 'goal', 'system'],
    default: 'info'
  },
  icon: {
    type: String,
    default: 'notification'
  },
  color: {
    type: String,
    default: '#4A6CF7' // Default blue color
  },
  isRead: {
    type: Boolean,
    default: false
  },
  actionLink: {
    type: String,
    default: null
  },
  relatedItemId: {
    type: mongoose.Schema.Types.ObjectId,
    default: null
  },
  relatedItemType: {
    type: String,
    enum: ['transaction', 'budget', 'savingsGoal', 'user', 'system', null],
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  expiresAt: {
    type: Date,
    default: function() {
      // Default expiration is 30 days from creation
      const date = new Date();
      date.setDate(date.getDate() + 30);
      return date;
    }
  }
}, {
  timestamps: true
});

// Index for faster queries
NotificationSchema.index({ user: 1, isRead: 1, createdAt: -1 });
NotificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index for auto-deletion

module.exports = mongoose.model('Notification', NotificationSchema);
