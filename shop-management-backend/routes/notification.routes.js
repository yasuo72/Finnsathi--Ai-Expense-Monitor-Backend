const express = require('express');
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

router.get('/', authMiddleware, notificationController.getNotifications);
router.put('/mark-all-read', authMiddleware, notificationController.markAllRead);
router.put('/:id/read', authMiddleware, notificationController.markNotificationRead);

module.exports = router;
