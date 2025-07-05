const axios = require('axios');
const fs = require('fs');
const path = require('path');

class ChatbotService {
  constructor() {
    // Rasa server configuration
    this.rasaUrl = process.env.RASA_URL || 'http://localhost:5005';
    this.initialized = false;
  }

  async initialize() {
    if (this.initialized) return;

    try {
      // Check if Rasa server is running
      await this.checkRasaStatus();
      this.initialized = true;
      console.log('Rasa chatbot service initialized');
    } catch (error) {
      console.error('Error initializing Rasa chatbot:', error);
      console.log('Falling back to mock responses');
      // Still mark as initialized to use fallback responses
      this.initialized = true;
    }
  }
  
  async checkRasaStatus() {
    try {
      const response = await axios.get(`${this.rasaUrl}/status`);
      return response.data;
    } catch (error) {
      console.error('Rasa server not available:', error.message);
      throw new Error('Rasa server not available');
    }
  }

  // We don't need to train the model here as Rasa handles that separately
  // This method is kept for compatibility but doesn't do anything
  async trainModel() {
    console.log('Training is handled by Rasa separately');
    return true;
  }

  async processMessage(message, userId) {
    if (!this.initialized) {
      await this.initialize();
    }

    try {
      // Try to send the message to Rasa
      const response = await this.sendMessageToRasa(message, userId);
      return {
        intent: response.intent?.name || 'unknown',
        score: response.intent?.confidence || 0,
        answer: response.text || "I'm processing your request...",
        entities: response.entities || []
      };
    } catch (error) {
      console.error('Error processing message with Rasa:', error);
      // Fallback to mock responses if Rasa is unavailable
      return this.getMockResponse(message);
    }
  }

  async sendMessageToRasa(message, userId) {
    try {
      const response = await axios.post(`${this.rasaUrl}/webhooks/rest/webhook`, {
        sender: userId || 'user',
        message: message
      });
      
      // Rasa might return an array of responses, we'll use the first one
      if (response.data && response.data.length > 0) {
        return {
          text: response.data[0].text,
          intent: response.data[0].intent,
          entities: response.data[0].entities || []
        };
      }
      
      // If no response from Rasa
      return {
        text: "I didn't get a response from my brain. Can you try again?",
        intent: { name: 'unknown', confidence: 0 },
        entities: []
      };
    } catch (error) {
      console.error('Error sending message to Rasa:', error.message);
      throw error;
    }
  }
  
  // Fallback responses when Rasa is unavailable
  getMockResponse(message) {
    // Simple keyword matching for fallback
    const lowerMessage = message.toLowerCase();
    
    if (lowerMessage.includes('hello') || lowerMessage.includes('hi')) {
      return {
        intent: 'greetings.hello',
        score: 1.0,
        answer: 'Hello! How can I help with your finances today?',
        entities: []
      };
    } else if (lowerMessage.includes('bye') || lowerMessage.includes('goodbye')) {
      return {
        intent: 'greetings.bye',
        score: 1.0,
        answer: 'Goodbye! Have a great day.',
        entities: []
      };
    } else if (lowerMessage.includes('thank')) {
      return {
        intent: 'greetings.thanks',
        score: 1.0,
        answer: 'You\'re welcome! I\'m here to help with all your financial needs.',
        entities: []
      };
    } else if (lowerMessage.includes('budget') || lowerMessage.includes('spent') || lowerMessage.includes('spending')) {
      return {
        intent: 'budget.spent',
        score: 0.8,
        answer: 'I\'ll check your recent spending. Please wait while I analyze your expenses...',
        entities: []
      };
    } else if (lowerMessage.includes('saving') || lowerMessage.includes('save')) {
      return {
        intent: 'savings.status',
        score: 0.8,
        answer: 'I\'ll analyze your savings progress. Let me check how you\'re doing compared to your goals...',
        entities: []
      };
    } else {
      return {
        intent: 'unknown',
        score: 0.3,
        answer: "I'm not sure I understand. Could you rephrase your question about your finances?",
        entities: []
      };
    }
  }
}

module.exports = new ChatbotService();
