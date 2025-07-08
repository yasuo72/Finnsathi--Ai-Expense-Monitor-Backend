const express = require('express');
const router = express.Router();
const { analyzeExpenses, chat } = require('../controllers/gemini.controller');
const auth = require('../middleware/auth');

// Protected routes
router.post('/analyze-expenses', auth, analyzeExpenses);
router.post('/chat', auth, chat);


module.exports = router;
