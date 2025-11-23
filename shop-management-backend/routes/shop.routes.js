const express = require('express');
const shopController = require('../controllers/shopController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Specific routes MUST come before generic routes
router.get('/stats', authMiddleware, shopController.getShopStats);
router.get('/my-shop', authMiddleware, shopController.getMyShop);
router.post('/upload-image', authMiddleware, shopController.uploadShopImage);
router.put('/toggle-status', authMiddleware, shopController.toggleShopStatus);

// Generic routes AFTER specific routes
router.post('/', authMiddleware, shopController.createShop);
router.put('/', authMiddleware, shopController.updateShop);

module.exports = router;
