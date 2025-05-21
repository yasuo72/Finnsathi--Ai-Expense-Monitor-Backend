const express = require('express');
const router = express.Router();
const { 
  getWallet,
  updateCashAmount,
  addCashAmount,
  addCard,
  removeCard,
  verifyPassword,
  updatePassword,
  updateCardBalance,
  getWalletBalance,
  syncWalletWithTransactions
} = require('../controllers/wallet.controller');
const { protect } = require('../middleware/auth');

// All routes are protected
router.use(protect);

router.get('/', getWallet);
router.get('/balance', getWalletBalance);
router.put('/cash', updateCashAmount);
router.post('/cash/add', addCashAmount);
router.post('/cards', addCard);
router.delete('/cards/:cardId', removeCard);
router.put('/cards/:cardId/balance', updateCardBalance);
router.post('/verify-password', verifyPassword);
router.put('/password', updatePassword);
router.post('/sync', syncWalletWithTransactions);

module.exports = router;
