const express = require('express');
const router = express.Router();
const { 
  predictSpending,
  predictSavingsGoalCompletion,
  getFinancialInsights
} = require('../controllers/prediction.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

// Prediction routes
router.get('/spending', predictSpending);
router.get('/savings-goal/:id', predictSavingsGoalCompletion);
router.get('/insights', getFinancialInsights);

module.exports = router;
