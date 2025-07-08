const express = require('express');
const router = express.Router();
const { analyzeExpenses, chat } = require('../controllers/gemini.controller');
const { protect } = require('../middleware/auth');

// Protected routes
router.use(protect);
router.post('/analyze-expenses', analyzeExpenses);
router.post('/chat', chat);


module.exports = router;
