const express = require('express');
const router = express.Router();
const { 
  getBudgets,
  getBudget,
  createBudget,
  updateBudget,
  deleteBudget,
  getBudgetStatus,
  getBudgetStats
} = require('../controllers/budget.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

router.route('/')
  .get(getBudgets)
  .post(createBudget);

router.route('/:id')
  .get(getBudget)
  .put(updateBudget)
  .delete(deleteBudget);

router.get('/alerts', getBudgetAlerts);
router.get('/stats', getBudgetStats);
router.get('/:id/status', getBudgetStatus);

module.exports = router;
