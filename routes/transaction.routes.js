const express = require('express');
const router = express.Router();
const { 
  getTransactions,
  getTransaction,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  getTransactionStats,
  getTransactionTrends
} = require('../controllers/transaction.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

router.route('/')
  .get(getTransactions)
  .post(createTransaction);

router.route('/:id')
  .get(getTransaction)
  .put(updateTransaction)
  .delete(deleteTransaction);

router.get('/stats', getTransactionStats);
router.get('/trends', getTransactionTrends);

module.exports = router;
