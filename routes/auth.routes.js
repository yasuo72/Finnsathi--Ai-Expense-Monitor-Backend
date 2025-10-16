const express = require('express');
const router = express.Router();
const { 
  signup, 
  signin, 
  verifyOtp, 
  forgotPassword, 
  verifyResetOtp,
  resetPassword, 
  googleAuth,
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
router.post('/verify-reset-otp', verifyResetOtp);
router.post('/reset-password', resetPassword);
router.post('/google', googleAuth); // Google authentication endpoint

// Protected routes
router.get('/me', protect, getMe);

module.exports = router;
