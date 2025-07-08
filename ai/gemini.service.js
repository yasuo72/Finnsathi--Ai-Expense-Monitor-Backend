const axios = require('axios');

/**
 * Simple wrapper around the Google Gemini REST API (Vertex / Generative Language API).
 * We intentionally avoid the official @google/generative-ai SDK because it requires
 * ESM-only imports which would force a breaking change across the whole codebase.
 */

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
// Allow overriding the model via env var so we can switch without code changes
const GEMINI_MODEL_ID = process.env.GEMINI_MODEL_ID || 'gemini-2.0-flash';

if (!GEMINI_API_KEY) {
  // Fail fast on startup so that mis-configuration is obvious in the logs
  console.warn('[Gemini] GEMINI_API_KEY is not set – Gemini features will be disabled.');
}

/**
 * Send a prompt to Gemini and return plain-text response.
 * @param {string} prompt – The text prompt to send.
 * @returns {Promise<string>} Gemini response text (may be empty on error).
 */
async function generateContent(prompt) {
  if (!GEMINI_API_KEY) {
    return 'Gemini API key not configured on the server.';
  }

  // v1beta endpoint is still used for public key access; only the model ID changes.
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL_ID}:generateContent?key=${GEMINI_API_KEY}`;

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
