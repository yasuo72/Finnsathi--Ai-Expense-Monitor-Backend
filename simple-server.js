const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Sample data
const mockData = {
  transactions: [
    { id: '1', title: 'Groceries', amount: 1500, type: 'expense', category: 'Food', date: new Date() },
    { id: '2', title: 'Salary', amount: 50000, type: 'income', category: 'Salary', date: new Date() },
    { id: '3', title: 'Restaurant', amount: 2000, type: 'expense', category: 'Food', date: new Date() }
  ],
  budgets: [
    { id: '1', category: 'Food', limit: 10000, spent: 3500, isActive: true },
    { id: '2', category: 'Entertainment', limit: 5000, spent: 2000, isActive: true }
  ],
  savingsGoals: [
    { id: '1', title: 'Vacation', targetAmount: 50000, currentAmount: 20000, targetDate: new Date(2025, 11, 31) },
    { id: '2', title: 'New Laptop', targetAmount: 80000, currentAmount: 30000, targetDate: new Date(2025, 8, 15) }
  ],
  statistics: {
    spendingByCategory: [
      { category: 'Food', amount: 5500 },
      { category: 'Entertainment', amount: 2000 },
      { category: 'Transportation', amount: 3000 }
    ],
    incomeVsExpense: {
      income: 50000,
      expense: 10500
    }
  }
};

// Root endpoint
app.get('/api', (req, res) => {
  res.json({ success: true, message: 'FinSathi API is working!' });
});

// Auth endpoints
app.post('/api/auth/signup', (req, res) => {
  res.json({ 
    success: true, 
    message: 'User registered successfully',
    data: {
      token: 'mock-jwt-token',
      user: {
        id: '123',
        name: req.body.name || 'Test User',
        email: req.body.email || 'test@example.com'
      }
    }
  });
});

app.post('/api/auth/signin', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Login successful',
    data: {
      token: 'mock-jwt-token',
      user: {
        id: '123',
        name: 'Test User',
        email: req.body.email || 'test@example.com'
      }
    }
  });
});

// Transactions endpoints
app.get('/api/transactions', (req, res) => {
  res.json({ success: true, data: mockData.transactions });
});

app.post('/api/transactions', (req, res) => {
  const newTransaction = {
    id: Date.now().toString(),
    ...req.body,
    date: new Date()
  };
  mockData.transactions.push(newTransaction);
  res.json({ success: true, data: newTransaction });
});

// Budgets endpoints
app.get('/api/budgets', (req, res) => {
  res.json({ success: true, data: mockData.budgets });
});

app.post('/api/budgets', (req, res) => {
  const newBudget = {
    id: Date.now().toString(),
    ...req.body,
    isActive: true
  };
  mockData.budgets.push(newBudget);
  res.json({ success: true, data: newBudget });
});

// Savings goals endpoints
app.get('/api/savings-goals', (req, res) => {
  res.json({ success: true, data: mockData.savingsGoals });
});

app.post('/api/savings-goals', (req, res) => {
  const newGoal = {
    id: Date.now().toString(),
    ...req.body
  };
  mockData.savingsGoals.push(newGoal);
  res.json({ success: true, data: newGoal });
});

// Wallet endpoints
app.get('/api/wallet', (req, res) => {
  res.json({ 
    success: true, 
    data: {
      balance: 25000,
      cards: [
        { id: '1', name: 'Main Card', balance: 15000 },
        { id: '2', name: 'Savings Card', balance: 10000 }
      ],
      cash: 5000
    }
  });
});

// Statistics endpoints
app.get('/api/statistics/spending-by-category', (req, res) => {
  res.json({ success: true, data: mockData.statistics.spendingByCategory });
});

app.get('/api/statistics/income-vs-expense', (req, res) => {
  res.json({ success: true, data: mockData.statistics.incomeVsExpense });
});

// Chatbot endpoint
app.post('/api/chatbot', (req, res) => {
  const { message } = req.body;
  let response = "I'm not sure how to respond to that.";
  
  // Simple keyword matching
  if (message.toLowerCase().includes('hello') || message.toLowerCase().includes('hi')) {
    response = "Hello! How can I help with your finances today?";
  } else if (message.toLowerCase().includes('budget')) {
    response = "Your current budget utilization is 35%. You're doing great!";
  } else if (message.toLowerCase().includes('saving')) {
    response = "You're on track with your savings goals. Keep it up!";
  } else if (message.toLowerCase().includes('spend')) {
    response = "You've spent ₹10,500 this month, which is 21% of your income.";
  }
  
  res.json({ 
    success: true, 
    data: {
      text: response,
      intent: 'response',
      confidence: 0.9
    }
  });
});

// Notifications endpoint
app.get('/api/notifications', (req, res) => {
  res.json({ 
    success: true, 
    data: [
      { id: '1', title: 'Budget Alert', message: 'You are close to your Food budget limit', read: false, date: new Date() },
      { id: '2', title: 'Savings Goal', message: 'You are 40% towards your Vacation goal', read: true, date: new Date(Date.now() - 86400000) }
    ]
  });
});

// Predictions endpoint
app.get('/api/predictions/spending', (req, res) => {
  res.json({ 
    success: true, 
    data: {
      nextMonth: 12000,
      trend: 'increasing',
      categories: [
        { category: 'Food', amount: 6000 },
        { category: 'Entertainment', amount: 3000 },
        { category: 'Transportation', amount: 3000 }
      ]
    }
  });
});

// Start the server
app.listen(port, () => {
  console.log(`Simple test server running at http://localhost:${port}`);
  console.log('Use this server to test your API connections without native dependencies');
  console.log('Press Ctrl+C to stop the server');
});
