const express = require('express');
const router = express.Router();
const { 
  getNotifications,
  getNotification,
  createNotification,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  deleteReadNotifications,
  getNotificationSettings,
  updateNotificationSettings
} = require('../controllers/notification.controller');
const { protect, authorize } = require('../middleware/auth');

// All routes are protected
router.use(protect);

// User notification routes
router.get('/', getNotifications);
router.get('/settings', getNotificationSettings);
router.put('/settings', updateNotificationSettings);
router.get('/:id', getNotification);
router.patch('/:id/read', markAsRead);
router.patch('/read-all', markAllAsRead);
router.delete('/:id', deleteNotification);
router.delete('/read', deleteReadNotifications);

// Admin only routes
router.post('/', authorize('admin', 'system'), createNotification);

module.exports = router;
