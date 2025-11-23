const express = require('express');
const menuController = require('../controllers/menuController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Public routes (no authentication required)
router.get('/shop/:shopId', menuController.getShopMenuPublic);

// Protected routes (authentication required) - specific routes MUST come before generic routes
router.get('/by-category', authMiddleware, menuController.getMenuByCategory);
router.post('/:itemId/upload-image', authMiddleware, menuController.uploadMenuItemImage);
router.put('/:itemId/toggle-availability', authMiddleware, menuController.toggleAvailability);
router.put('/:itemId', authMiddleware, menuController.updateMenuItem);
router.delete('/:itemId', authMiddleware, menuController.deleteMenuItem);

// Generic protected routes AFTER specific routes
router.post('/', authMiddleware, menuController.addMenuItem);
router.get('/', authMiddleware, menuController.getShopMenu);

module.exports = router;
