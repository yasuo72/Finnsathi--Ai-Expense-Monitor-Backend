const express = require('express');
const router = express.Router();
const { 
  processMessage,
  trainModel
} = require('../controllers/chatbot.controller');
const { protect, authorize } = require('../middleware/auth');

// All routes are protected
router.use(protect);

// Process chatbot messages
router.post('/message', processMessage);

// Admin only route for training the model
router.post('/train', authorize('admin'), trainModel);

module.exports = router;
