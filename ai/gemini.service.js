const axios = require('axios');

/**
 * Simple wrapper around the Google Gemini REST API (Vertex / Generative Language API).
 * We intentionally avoid the official @google/generative-ai SDK because it requires
 * ESM-only imports which would force a breaking change across the whole codebase.
 */

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY) {
  // Fail fast on startup so that mis-configuration is obvious in the logs
  console.warn('[Gemini] GEMINI_API_KEY is not set – Gemini features will be disabled.');
}

/**
 * Send a prompt to Gemini-Pro and return plain-text response.
 * @param {string} prompt – The text prompt to send.
 * @returns {Promise<string>} Gemini response text (may be empty on error).
 */
async function generateContent(prompt) {
  if (!GEMINI_API_KEY) {
    return 'Gemini API key not configured on the server.';
  }

  const url = `https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}`;

  try {
    const { data } = await axios.post(url, {
      contents: [
        {
          parts: [{ text: prompt }]
        }
      ]
    });

    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
    return text.trim();
  } catch (err) {
    console.error('[Gemini] API call failed:', err.response?.data || err.message);
    throw new Error('Failed to fetch response from Gemini API');
  }
}

module.exports = {
  generateContent
};
