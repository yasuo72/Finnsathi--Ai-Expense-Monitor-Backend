const express = require('express');
const menuController = require('../controllers/menuController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

router.post('/', authMiddleware, menuController.addMenuItem);
router.get('/', authMiddleware, menuController.getShopMenu);
router.put('/:itemId', authMiddleware, menuController.updateMenuItem);
router.delete('/:itemId', authMiddleware, menuController.deleteMenuItem);
router.post('/:itemId/upload-image', authMiddleware, menuController.uploadMenuItemImage);
router.put('/:itemId/toggle-availability', authMiddleware, menuController.toggleAvailability);
router.get('/by-category', authMiddleware, menuController.getMenuByCategory);

module.exports = router;
