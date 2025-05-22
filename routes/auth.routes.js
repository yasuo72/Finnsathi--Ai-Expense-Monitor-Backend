const express = require('express');
const router = express.Router();
const { 
  signup, 
  signin, 
  verifyOtp, 
  forgotPassword, 
  resetPassword, 
  getMe 
} = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth');

// Public routes
router.post('/signup', signup);
router.post('/register', signup); // Add alias for compatibility
router.post('/signin', signin);
router.post('/login', signin); // Add alias for compatibility
router.post('/verify', verifyOtp);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// Protected routes
router.get('/me', protect, getMe);

module.exports = router;
