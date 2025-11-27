const express = require('express');
const shopController = require('../controllers/shopController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Public routes (no authentication required)
router.get('/', shopController.getAllShops);
router.get('/:shopId/reviews', shopController.getShopReviews);
router.get('/admin/stats', shopController.getGlobalStats);
router.get('/admin/:shopId/owner', shopController.adminGetShopOwnerInfo);
router.patch('/admin/:shopId', shopController.adminUpdateShop);

// Protected routes (authentication required) - specific routes MUST come before generic routes
router.get('/stats', authMiddleware, shopController.getShopStats);
router.get('/my-shop', authMiddleware, shopController.getMyShop);
router.post('/upload-image', authMiddleware, shopController.uploadShopImage);
router.put('/toggle-status', authMiddleware, shopController.toggleShopStatus);

// Generic routes AFTER specific routes
router.get('/:shopId', shopController.getShopById);
router.post('/', authMiddleware, shopController.createShop);
router.put('/', authMiddleware, shopController.updateShop);

module.exports = router;
