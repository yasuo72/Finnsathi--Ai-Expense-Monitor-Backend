const express = require('express');
const router = express.Router();
const { 
  getSavingsGoals,
  getSavingsGoal,
  createSavingsGoal,
  updateSavingsGoal,
  deleteSavingsGoal,
  addToSavingsGoal,
  withdrawFromSavingsGoal,
  getSavingsGoalsStats
} = require('../controllers/savingsGoal.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

router.route('/')
  .get(getSavingsGoals)
  .post(createSavingsGoal);

router.route('/:id')
  .get(getSavingsGoal)
  .put(updateSavingsGoal)
  .delete(deleteSavingsGoal);

router.get('/stats', getSavingsGoalsStats);
router.post('/:id/add', addToSavingsGoal);
router.post('/:id/withdraw', withdrawFromSavingsGoal);

module.exports = router;
