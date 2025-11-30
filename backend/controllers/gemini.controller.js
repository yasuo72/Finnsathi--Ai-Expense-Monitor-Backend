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
/**
 * POST /api/gemini/prompts
 * Body: { screen: string, stats: object }
 * Responds: { prompts: string[] }
 */
exports.generatePrompts = async (req, res, next) => {
  try {
    const { screen, stats } = req.body;
    if (!screen || !stats) {
      return res.status(400).json({ message: 'screen and stats are required' });
    }

    const prompt = `Generate 6 concise, helpful questions a user might ask an AI assistant on the topic of "${screen}". Base the suggestions on this finance snapshot JSON: ${JSON.stringify(stats)}. Return each question on a new line without numbering.`;
    const text = await generateContent(prompt);
    // split by newline and filter empty lines
    const prompts = text.split(/\r?\n/).map(p => p.trim()).filter(Boolean).slice(0, 6);
    res.json({ prompts });
  } catch (err) {
    next(err);
  }
};

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
