const ShopNotification = require('../models/ShopNotification');

// Get notifications for the logged-in shop owner
exports.getNotifications = async (req, res) => {
  try {
    const ownerId = req.user && req.user.id;
    if (!ownerId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const { limit = 50 } = req.query;
    const limitNumber = parseInt(limit, 10) || 50;

    const [notifications, unreadCount] = await Promise.all([
      ShopNotification.find({ ownerId })
        .sort({ createdAt: -1 })
        .limit(limitNumber),
      ShopNotification.countDocuments({ ownerId, isRead: false }),
    ]);

    res.json({ notifications, unreadCount });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching notifications', error: error.message });
  }
};

// Mark a single notification as read
exports.markNotificationRead = async (req, res) => {
  try {
    const ownerId = req.user && req.user.id;
    if (!ownerId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const { id } = req.params;
    const notification = await ShopNotification.findOneAndUpdate(
      { _id: id, ownerId },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    const unreadCount = await ShopNotification.countDocuments({ ownerId, isRead: false });

    res.json({ notification, unreadCount });
  } catch (error) {
    res.status(500).json({ message: 'Error updating notification', error: error.message });
  }
};

// Mark all notifications as read
exports.markAllRead = async (req, res) => {
  try {
    const ownerId = req.user && req.user.id;
    if (!ownerId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    await ShopNotification.updateMany({ ownerId, isRead: false }, { isRead: true });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ message: 'Error updating notifications', error: error.message });
  }
};
