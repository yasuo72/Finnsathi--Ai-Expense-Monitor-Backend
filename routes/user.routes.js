const express = require('express');
const router = express.Router();
const { 
  getProfile,
  updateProfile, 
  changePassword, 
  uploadProfilePicture,
  updatePreferences,
  getFinancialSummary,
  syncProfileData
} = require('../controllers/user.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.post('/change-password', changePassword);
router.post('/profile-picture', uploadProfilePicture);
router.put('/preferences', updatePreferences);
router.get('/financial-summary', getFinancialSummary);
router.post('/sync-profile', syncProfileData);

module.exports = router;
