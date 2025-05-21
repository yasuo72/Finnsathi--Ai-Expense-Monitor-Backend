const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const receiptController = require('../controllers/receipt.controller');

// All routes are protected with authentication
router.use(protect);

// Receipt scanning routes
router.post('/direct-integration', receiptController.directIntegration);
router.get('/status', receiptController.getServiceStatus);
router.get('/', receiptController.getReceiptTransactions);
router.get('/:id', receiptController.getReceiptTransaction);
router.put('/:id', receiptController.updateReceiptTransaction);

module.exports = router;
