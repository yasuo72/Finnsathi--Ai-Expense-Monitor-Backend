const express = require('express');
const orderController = require('../controllers/orderController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

router.get('/', authMiddleware, orderController.getShopOrders);
router.post('/', authMiddleware, orderController.createOrderFromApp);
router.get('/user', authMiddleware, orderController.getUserOrders);
router.put('/:orderId/rate', authMiddleware, orderController.rateOrder);
router.get('/:orderId', authMiddleware, orderController.getOrderDetails);
router.put('/:orderId/status', authMiddleware, orderController.updateOrderStatus);
router.put('/:orderId/cancel', authMiddleware, orderController.cancelOrder);
router.get('/stats/overview', authMiddleware, orderController.getOrderStats);

module.exports = router;
