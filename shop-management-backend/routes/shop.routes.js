const express = require('express');
const shopController = require('../controllers/shopController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

router.post('/', authMiddleware, shopController.createShop);
router.get('/my-shop', authMiddleware, shopController.getMyShop);
router.put('/', authMiddleware, shopController.updateShop);
router.post('/upload-image', authMiddleware, shopController.uploadShopImage);
router.get('/stats', authMiddleware, shopController.getShopStats);
router.put('/toggle-status', authMiddleware, shopController.toggleShopStatus);

module.exports = router;
