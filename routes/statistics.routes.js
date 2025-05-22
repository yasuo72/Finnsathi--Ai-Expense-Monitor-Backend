const express = require('express');
const router = express.Router();
const { 
  getFinancialOverview,
  getMonthlyComparison,
  getFinancialInsights,
  getDashboardStatistics,
  getCategoryStatistics
} = require('../controllers/statistics.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

router.get('/overview', getFinancialOverview);
router.get('/monthly-comparison', getMonthlyComparison);
router.get('/insights', getFinancialInsights);
router.get('/dashboard', getDashboardStatistics);
router.get('/categories', getCategoryStatistics);

module.exports = router;
