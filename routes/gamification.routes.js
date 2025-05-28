const express = require('express');
const router = express.Router();
const { 
  getGamificationData,
  getFinancialHealthScore,
  getChallenges,
  completeChallenge,
  getAchievements,
  updateGamificationData,
  updateChallenges,
  updateBadges
} = require('../controllers/gamification.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

router.get('/', getGamificationData);
router.put('/', updateGamificationData);
router.get('/financial-health', getFinancialHealthScore);
router.get('/challenges', getChallenges);
router.put('/challenges', updateChallenges);
router.post('/challenges/:id/complete', completeChallenge);
router.get('/achievements', getAchievements);
router.put('/badges', updateBadges);

module.exports = router;
