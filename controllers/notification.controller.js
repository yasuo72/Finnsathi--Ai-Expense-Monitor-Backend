const Notification = require('../models/Notification');
const User = require('../models/User');
const mongoose = require('mongoose');

// @desc    Get all notifications for a user
// @route   GET /api/notifications
// @access  Private
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20, unreadOnly = false, type } = req.query;
    
    // Build query
    const query = { user: userId };
    
    // Filter by read status if requested
    if (unreadOnly === 'true') {
      query.isRead = false;
    }
    
    // Filter by type if provided
    if (type) {
      query.type = type;
    }
    
    // Count total notifications matching the query
    const total = await Notification.countDocuments(query);
    
    // Get paginated notifications
    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));
    
    // Count total unread notifications
    const unreadCount = await Notification.countDocuments({ 
      user: userId, 
      isRead: false 
    });
    
    res.status(200).json({
      success: true,
      count: notifications.length,
      total,
      unreadCount,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      },
      data: notifications
    });
  } catch (error) {
    console.error('Error in getNotifications:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get a single notification
// @route   GET /api/notifications/:id
// @access  Private
exports.getNotification = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }
    
    // Check if notification belongs to the user
    if (notification.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this notification'
      });
    }
    
    res.status(200).json({
      success: true,
      data: notification
    });
  } catch (error) {
    console.error('Error in getNotification:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Create a new notification
// @route   POST /api/notifications
// @access  Private (Admin only)
exports.createNotification = async (req, res) => {
  try {
    const { title, message, type, icon, color, actionLink, userId, userIds, relatedItemId, relatedItemType, expiresAt } = req.body;
    
    // Check if admin or system role
    if (req.user.role !== 'admin' && req.user.role !== 'system') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to create notifications'
      });
    }
    
    // Validate required fields
    if (!title || !message) {
      return res.status(400).json({
        success: false,
        message: 'Please provide title and message'
      });
    }
    
    // Create notification for a single user
    if (userId) {
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }
      
      // Check if user has notifications enabled
      if (user.preferences && user.preferences.notifications === false) {
        return res.status(200).json({
          success: true,
          message: 'Notification not sent - user has notifications disabled',
          data: null
        });
      }
      
      const notification = await Notification.create({
        user: userId,
        title,
        message,
        type: type || 'info',
        icon: icon || 'notification',
        color: color || '#4A6CF7',
        actionLink: actionLink || null,
        relatedItemId: relatedItemId || null,
        relatedItemType: relatedItemType || null,
        expiresAt: expiresAt ? new Date(expiresAt) : undefined
      });
      
      res.status(201).json({
        success: true,
        data: notification
      });
    }
    // Create notifications for multiple users
    else if (userIds && Array.isArray(userIds)) {
      // Get users with notifications enabled
      const users = await User.find({
        _id: { $in: userIds },
        'preferences.notifications': { $ne: false }
      });
      
      if (users.length === 0) {
        return res.status(200).json({
          success: true,
          message: 'No notifications sent - users not found or all have notifications disabled',
          data: []
        });
      }
      
      // Create notifications for all eligible users
      const notifications = await Promise.all(
        users.map(user => 
          Notification.create({
            user: user._id,
            title,
            message,
            type: type || 'info',
            icon: icon || 'notification',
            color: color || '#4A6CF7',
            actionLink: actionLink || null,
            relatedItemId: relatedItemId || null,
            relatedItemType: relatedItemType || null,
            expiresAt: expiresAt ? new Date(expiresAt) : undefined
          })
        )
      );
      
      res.status(201).json({
        success: true,
        count: notifications.length,
        data: notifications
      });
    } else {
      return res.status(400).json({
        success: false,
        message: 'Please provide userId or userIds array'
      });
    }
  } catch (error) {
    console.error('Error in createNotification:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Create a system notification (internal use)
// @route   Not exposed as API endpoint
// @access  Internal
exports.createSystemNotification = async (userId, title, message, options = {}) => {
  try {
    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      console.error(`Cannot create notification: User ${userId} not found`);
      return null;
    }
    
    // Check if user has notifications enabled
    if (user.preferences && user.preferences.notifications === false) {
      // Skip notification creation if user has disabled notifications
      return null;
    }
    
    // Create notification
    const notification = await Notification.create({
      user: userId,
      title,
      message,
      type: options.type || 'system',
      icon: options.icon || 'system',
      color: options.color || '#4A6CF7',
      actionLink: options.actionLink || null,
      relatedItemId: options.relatedItemId || null,
      relatedItemType: options.relatedItemType || null,
      expiresAt: options.expiresAt ? new Date(options.expiresAt) : undefined
    });
    
    return notification;
  } catch (error) {
    console.error('Error in createSystemNotification:', error);
    return null;
  }
};

// @desc    Mark notification as read
// @route   PATCH /api/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }
    
    // Check if notification belongs to the user
    if (notification.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this notification'
      });
    }
    
    // Update read status
    notification.isRead = true;
    await notification.save();
    
    res.status(200).json({
      success: true,
      data: notification
    });
  } catch (error) {
    console.error('Error in markAsRead:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Mark all notifications as read
// @route   PATCH /api/notifications/read-all
// @access  Private
exports.markAllAsRead = async (req, res) => {
  try {
    const result = await Notification.updateMany(
      { user: req.user.id, isRead: false },
      { isRead: true }
    );
    
    res.status(200).json({
      success: true,
      message: `Marked ${result.modifiedCount} notifications as read`,
      count: result.modifiedCount
    });
  } catch (error) {
    console.error('Error in markAllAsRead:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Delete a notification
// @route   DELETE /api/notifications/:id
// @access  Private
exports.deleteNotification = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }
    
    // Check if notification belongs to the user
    if (notification.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this notification'
      });
    }
    
    await notification.remove();
    
    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    console.error('Error in deleteNotification:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Delete all read notifications
// @route   DELETE /api/notifications/read
// @access  Private
exports.deleteReadNotifications = async (req, res) => {
  try {
    const result = await Notification.deleteMany({
      user: req.user.id,
      isRead: true
    });
    
    res.status(200).json({
      success: true,
      message: `Deleted ${result.deletedCount} read notifications`,
      count: result.deletedCount
    });
  } catch (error) {
    console.error('Error in deleteReadNotifications:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get notification settings
// @route   GET /api/notifications/settings
// @access  Private
exports.getNotificationSettings = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Initialize preferences if they don't exist
    if (!user.preferences) {
      user.preferences = {};
    }
    
    const notificationSettings = {
      notifications: user.preferences.notifications !== false, // Default to true if not set
      budgetReminders: user.preferences.budgetReminders !== false, // Default to true if not set
      savingsReminders: user.preferences.savingsReminders !== false, // Default to true if not set
      transactionAlerts: user.preferences.transactionAlerts !== false, // Default to true if not set
      weeklyReports: user.preferences.weeklyReports !== false, // Default to true if not set
      loginNotifications: user.security?.loginNotifications !== false // Default to true if not set
    };
    
    res.status(200).json({
      success: true,
      data: notificationSettings
    });
  } catch (error) {
    console.error('Error in getNotificationSettings:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Update notification settings
// @route   PUT /api/notifications/settings
// @access  Private
exports.updateNotificationSettings = async (req, res) => {
  try {
    const { 
      notifications, 
      budgetReminders, 
      savingsReminders, 
      transactionAlerts,
      weeklyReports,
      loginNotifications
    } = req.body;
    
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Initialize preferences if they don't exist
    if (!user.preferences) {
      user.preferences = {};
    }
    
    // Initialize security if it doesn't exist
    if (!user.security) {
      user.security = {};
    }
    
    // Update notification preferences
    if (notifications !== undefined) user.preferences.notifications = notifications;
    if (budgetReminders !== undefined) user.preferences.budgetReminders = budgetReminders;
    if (savingsReminders !== undefined) user.preferences.savingsReminders = savingsReminders;
    if (transactionAlerts !== undefined) user.preferences.transactionAlerts = transactionAlerts;
    if (weeklyReports !== undefined) user.preferences.weeklyReports = weeklyReports;
    if (loginNotifications !== undefined) user.security.loginNotifications = loginNotifications;
    
    await user.save();
    
    // Return updated settings
    const notificationSettings = {
      notifications: user.preferences.notifications !== false,
      budgetReminders: user.preferences.budgetReminders !== false,
      savingsReminders: user.preferences.savingsReminders !== false,
      transactionAlerts: user.preferences.transactionAlerts !== false,
      weeklyReports: user.preferences.weeklyReports !== false,
      loginNotifications: user.security.loginNotifications !== false
    };
    
    res.status(200).json({
      success: true,
      message: 'Notification settings updated successfully',
      data: notificationSettings
    });
  } catch (error) {
    console.error('Error in updateNotificationSettings:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};
