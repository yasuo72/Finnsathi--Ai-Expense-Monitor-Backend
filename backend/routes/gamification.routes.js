const express = require('express');
const router = express.Router();
const { 
  getGamificationData,
  getFinancialHealthScore,
  getChallenges,
  completeChallenge,
  getAchievements
} = require('../controllers/gamification.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

router.get('/', getGamificationData);
router.get('/financial-health', getFinancialHealthScore);
router.get('/challenges', getChallenges);
router.post('/challenges/:id/complete', completeChallenge);
router.get('/achievements', getAchievements);

module.exports = router;
