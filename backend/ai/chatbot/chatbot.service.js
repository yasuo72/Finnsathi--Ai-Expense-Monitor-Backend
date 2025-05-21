const { NlpManager } = require('node-nlp');
const fs = require('fs');
const path = require('path');

class ChatbotService {
  constructor() {
    this.manager = new NlpManager({ languages: ['en'], forceNER: true });
    this.modelPath = path.join(__dirname, '../models/chatbot-model.nlp');
    this.initialized = false;
  }

  async initialize() {
    if (this.initialized) return;

    try {
      // Check if model exists
      if (fs.existsSync(this.modelPath)) {
        // Load existing model
        await this.manager.load(this.modelPath);
        console.log('Chatbot model loaded from file');
      } else {
        // Train new model
        await this.trainModel();
        console.log('Chatbot model trained and saved');
      }
      this.initialized = true;
    } catch (error) {
      console.error('Error initializing chatbot:', error);
      throw error;
    }
  }

  async trainModel() {
    // Add intents and entities for financial assistant
    
    // Greetings
    this.manager.addDocument('en', 'hello', 'greetings.hello');
    this.manager.addDocument('en', 'hi there', 'greetings.hello');
    this.manager.addDocument('en', 'hey', 'greetings.hello');
    this.manager.addDocument('en', 'howdy', 'greetings.hello');
    this.manager.addDocument('en', 'greetings', 'greetings.hello');
    
    // Farewells
    this.manager.addDocument('en', 'goodbye', 'greetings.bye');
    this.manager.addDocument('en', 'bye', 'greetings.bye');
    this.manager.addDocument('en', 'see you later', 'greetings.bye');
    this.manager.addDocument('en', 'see ya', 'greetings.bye');
    
    // Thanks
    this.manager.addDocument('en', 'thank you', 'greetings.thanks');
    this.manager.addDocument('en', 'thanks', 'greetings.thanks');
    this.manager.addDocument('en', 'appreciate it', 'greetings.thanks');
    
    // Budget inquiries
    this.manager.addDocument('en', 'how much have I spent', 'budget.spent');
    this.manager.addDocument('en', 'what is my spending', 'budget.spent');
    this.manager.addDocument('en', 'show me my expenses', 'budget.spent');
    this.manager.addDocument('en', 'how much did I spend this month', 'budget.spent');
    
    this.manager.addDocument('en', 'how much budget do I have left', 'budget.remaining');
    this.manager.addDocument('en', 'what\'s my remaining budget', 'budget.remaining');
    this.manager.addDocument('en', 'budget left', 'budget.remaining');
    
    // Savings inquiries
    this.manager.addDocument('en', 'how are my savings', 'savings.status');
    this.manager.addDocument('en', 'show me my savings', 'savings.status');
    this.manager.addDocument('en', 'savings progress', 'savings.status');
    this.manager.addDocument('en', 'am I on track with my savings', 'savings.status');
    
    this.manager.addDocument('en', 'how much should I save', 'savings.recommendation');
    this.manager.addDocument('en', 'recommend savings amount', 'savings.recommendation');
    this.manager.addDocument('en', 'savings advice', 'savings.recommendation');
    
    // Expense analysis
    this.manager.addDocument('en', 'where am I spending the most', 'expenses.top');
    this.manager.addDocument('en', 'top expenses', 'expenses.top');
    this.manager.addDocument('en', 'highest spending categories', 'expenses.top');
    this.manager.addDocument('en', 'what are my biggest expenses', 'expenses.top');
    
    this.manager.addDocument('en', 'how can I reduce expenses', 'expenses.reduce');
    this.manager.addDocument('en', 'tips to save money', 'expenses.reduce');
    this.manager.addDocument('en', 'ways to cut spending', 'expenses.reduce');
    this.manager.addDocument('en', 'help me spend less', 'expenses.reduce');
    
    // Income inquiries
    this.manager.addDocument('en', 'show me my income', 'income.status');
    this.manager.addDocument('en', 'how much did I earn', 'income.status');
    this.manager.addDocument('en', 'income this month', 'income.status');
    this.manager.addDocument('en', 'what are my earnings', 'income.status');
    
    // Financial health
    this.manager.addDocument('en', 'how is my financial health', 'finance.health');
    this.manager.addDocument('en', 'am I doing well financially', 'finance.health');
    this.manager.addDocument('en', 'financial status', 'finance.health');
    this.manager.addDocument('en', 'financial wellness check', 'finance.health');
    
    // Add transaction
    this.manager.addDocument('en', 'add expense', 'transaction.add_expense');
    this.manager.addDocument('en', 'record a purchase', 'transaction.add_expense');
    this.manager.addDocument('en', 'log spending', 'transaction.add_expense');
    this.manager.addDocument('en', 'I spent money on', 'transaction.add_expense');
    
    this.manager.addDocument('en', 'add income', 'transaction.add_income');
    this.manager.addDocument('en', 'record earnings', 'transaction.add_income');
    this.manager.addDocument('en', 'log income', 'transaction.add_income');
    this.manager.addDocument('en', 'I received money from', 'transaction.add_income');
    
    // Predictions and forecasts
    this.manager.addDocument('en', 'predict my spending next month', 'prediction.spending');
    this.manager.addDocument('en', 'forecast expenses', 'prediction.spending');
    this.manager.addDocument('en', 'spending prediction', 'prediction.spending');
    this.manager.addDocument('en', 'how much will I spend next month', 'prediction.spending');
    
    this.manager.addDocument('en', 'when will I reach my savings goal', 'prediction.savings');
    this.manager.addDocument('en', 'savings goal timeline', 'prediction.savings');
    this.manager.addDocument('en', 'predict when I can save enough for', 'prediction.savings');
    
    // Add responses
    this.manager.addAnswer('en', 'greetings.hello', 'Hello! How can I help with your finances today?');
    this.manager.addAnswer('en', 'greetings.hello', 'Hi there! I\'m your financial assistant. What would you like to know?');
    this.manager.addAnswer('en', 'greetings.hello', 'Hey! Ready to help you manage your money better.');
    
    this.manager.addAnswer('en', 'greetings.bye', 'Goodbye! Have a great day.');
    this.manager.addAnswer('en', 'greetings.bye', 'See you later! Remember to keep tracking those expenses.');
    
    this.manager.addAnswer('en', 'greetings.thanks', 'You\'re welcome! I\'m here to help with all your financial needs.');
    this.manager.addAnswer('en', 'greetings.thanks', 'Happy to help! Is there anything else you\'d like to know?');
    
    this.manager.addAnswer('en', 'budget.spent', 'I\'ll check your recent spending. Please wait while I analyze your expenses...');
    this.manager.addAnswer('en', 'budget.remaining', 'Let me calculate your remaining budget based on your spending so far...');
    
    this.manager.addAnswer('en', 'savings.status', 'I\'ll analyze your savings progress. Let me check how you\'re doing compared to your goals...');
    this.manager.addAnswer('en', 'savings.recommendation', 'Based on your income and expenses, I can recommend a savings plan. Let me analyze your data...');
    
    this.manager.addAnswer('en', 'expenses.top', 'Let me find your top spending categories. This will help you understand where your money is going...');
    this.manager.addAnswer('en', 'expenses.reduce', 'I can suggest some ways to reduce your expenses based on your spending patterns...');
    
    this.manager.addAnswer('en', 'income.status', 'I\'ll check your income records and provide a summary...');
    
    this.manager.addAnswer('en', 'finance.health', 'Let me analyze your overall financial health including income, expenses, savings, and debt...');
    
    this.manager.addAnswer('en', 'transaction.add_expense', 'I can help you record an expense. Please provide the amount, category, and date (optional).');
    this.manager.addAnswer('en', 'transaction.add_income', 'I can help you add income. Please provide the amount, source, and date (optional).');
    
    this.manager.addAnswer('en', 'prediction.spending', 'Based on your historical data, I can predict your spending for next month. Let me analyze the patterns...');
    this.manager.addAnswer('en', 'prediction.savings', 'I\'ll analyze your savings rate and predict when you\'ll reach your goal...');
    
    // Train the model
    await this.manager.train();
    
    // Save the model
    await this.manager.save(this.modelPath);
  }

  async processMessage(message, userId) {
    if (!this.initialized) {
      await this.initialize();
    }

    try {
      // Process the message
      const response = await this.manager.process('en', message);
      
      // If confidence is too low, provide a default response
      if (response.intent && response.score < 0.6) {
        return {
          intent: 'unknown',
          score: response.score,
          answer: "I'm not sure I understand. Could you rephrase your question about your finances?",
          entities: response.entities
        };
      }
      
      return response;
    } catch (error) {
      console.error('Error processing message:', error);
      return {
        intent: 'error',
        score: 0,
        answer: "Sorry, I encountered an error while processing your message. Please try again.",
        entities: []
      };
    }
  }
}

module.exports = new ChatbotService();
