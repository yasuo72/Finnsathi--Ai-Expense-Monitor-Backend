const { generateContent } = require('../ai/gemini.service');

/**
 * POST /api/gemini/analyze-expenses
 * Request body: {
 *   expenses: [{ amount, category, date, ... }] | string
 * }
 * Responds with: { analysis: string }
 */
exports.analyzeExpenses = async (req, res, next) => {
  try {
    const { expenses } = req.body;
    if (!expenses) {
      return res.status(400).json({ message: 'expenses field is required' });
    }

    // Build a robust prompt. Optimise for structured + natural language.
    const prompt = Array.isArray(expenses)
      ? `You are an AI financial advisor. Analyse the following JSON array of user expenses and provide actionable insights for saving money. Return the advice in plain English (max 200 words). Expenses: ${JSON.stringify(expenses)}`
      : `You are an AI financial advisor. Analyse these user expenses and provide actionable insights (max 200 words): ${expenses}`;

    const analysis = await generateContent(prompt);
    res.json({ analysis });
  } catch (err) {
    next(err); // centralised error middleware
  }
};

/**
 * POST /api/gemini/chat
 * Body: { prompt: string }
 */
exports.chat = async (req, res, next) => {
  try {
    const { prompt } = req.body;
    if (!prompt) {
      return res.status(400).json({ message: 'prompt field is required' });
    }
    const responseText = await generateContent(prompt);
    res.json({ message: responseText });
  } catch (err) {
    next(err);
  }
};
