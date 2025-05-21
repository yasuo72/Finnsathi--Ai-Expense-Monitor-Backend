const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const transactionRoutes = require('./routes/transaction.routes');
const budgetRoutes = require('./routes/budget.routes');
const savingsGoalRoutes = require('./routes/savingsGoal.routes');
const walletRoutes = require('./routes/wallet.routes');
const gamificationRoutes = require('./routes/gamification.routes');
const statisticsRoutes = require('./routes/statistics.routes');
const notificationRoutes = require('./routes/notification.routes');
const chatbotRoutes = require('./routes/chatbot.routes');
const predictionRoutes = require('./routes/prediction.routes');

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/finnsathi', {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.error('MongoDB connection error:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/savings-goals', savingsGoalRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/gamification', gamificationRoutes);
app.use('/api/statistics', statisticsRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/predictions', predictionRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to FinSathi API' });
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
