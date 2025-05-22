const Transaction = require('../models/Transaction');
const NotificationService = require('../services/notification.service');
const Budget = require('../models/Budget');
const mongoose = require('mongoose');

// @desc    Get all transactions
// @route   GET /api/transactions
// @access  Private
exports.getTransactions = async (req, res) => {
  try {
    // Add filtering by date range if query params are provided
    const filter = { user: req.user.id };
    
    if (req.query.startDate && req.query.endDate) {
      filter.date = {
        $gte: new Date(req.query.startDate),
        $lte: new Date(req.query.endDate)
      };
    }
    
    // Add filtering by type if provided
    if (req.query.type && ['income', 'expense'].includes(req.query.type)) {
      filter.type = req.query.type;
    }
    
    // Add filtering by category if provided
    if (req.query.category) {
      filter.category = req.query.category;
    }
    
    const transactions = await Transaction.find(filter)
      .sort({ date: -1 });
    
    res.status(200).json({
      success: true,
      count: transactions.length,
      data: transactions
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get transaction by ID
// @route   GET /api/transactions/:id
// @access  Private
exports.getTransaction = async (req, res) => {
  try {
    const transaction = await Transaction.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }
    
    res.status(200).json({
      success: true,
      data: transaction
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Create new transaction
// @route   POST /api/transactions
// @access  Private
exports.createTransaction = async (req, res) => {
  try {
    // Add user to request body
    req.body.user = req.user.id;
    
    const transaction = await Transaction.create(req.body);
    
    // Send transaction notification if it's enabled for the user
    try {
      // Determine if this is a large expense (over 1000 or customizable threshold)
      let eventType = 'created';
      if (transaction.type === 'expense' && transaction.amount > 1000) {
        eventType = 'large_expense';
      }
      
      // Send notification asynchronously (don't wait for it)
      NotificationService.sendTransactionNotification(
        req.user.id,
        transaction,
        eventType
      ).catch(err => console.error('Error sending transaction notification:', err));
      
      // If it's an expense, check if it affects any budgets
      if (transaction.type === 'expense' && transaction.category) {
        // Find relevant budget for this category
        const budget = await Budget.findOne({
          user: req.user.id,
          category: transaction.category
        });
        
        if (budget) {
          // Update budget spent amount
          budget.spent += transaction.amount;
          await budget.save();
          
          // Calculate percentage used
          const percentUsed = (budget.spent / budget.limit) * 100;
          
          // Send budget alert if threshold is reached
          if (percentUsed >= 75) {
            NotificationService.sendBudgetAlert(
              req.user.id,
              budget,
              percentUsed
            ).catch(err => console.error('Error sending budget alert:', err));
          }
        }
      }
    } catch (notificationError) {
      // Log notification error but don't fail the transaction creation
      console.error('Error processing notifications:', notificationError);
    }
    
    res.status(201).json({
      success: true,
      data: transaction
    });
  } catch (error) {
    console.error(error);
    
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(val => val.message);
      return res.status(400).json({
        success: false,
        message: messages.join(', ')
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Update transaction
// @route   PUT /api/transactions/:id
// @access  Private
exports.updateTransaction = async (req, res) => {
  try {
    let transaction = await Transaction.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }
    
    transaction = await Transaction.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );
    
    res.status(200).json({
      success: true,
      data: transaction
    });
  } catch (error) {
    console.error(error);
    
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(val => val.message);
      return res.status(400).json({
        success: false,
        message: messages.join(', ')
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Delete transaction
// @route   DELETE /api/transactions/:id
// @access  Private
exports.deleteTransaction = async (req, res) => {
  try {
    const transaction = await Transaction.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }
    
    // Use deleteOne instead of deprecated remove() method
    await Transaction.deleteOne({ _id: req.params.id });
    
    // If this is an expense and affects a budget, update the budget
    if (transaction.type === 'expense' && transaction.category) {
      try {
        // Find relevant budget for this category
        const budget = await Budget.findOne({
          user: req.user.id,
          category: transaction.category
        });
        
        if (budget) {
          // Update budget spent amount
          budget.spent = Math.max(0, budget.spent - transaction.amount);
          await budget.save();
        }
      } catch (budgetError) {
        console.error('Error updating budget after transaction deletion:', budgetError);
        // Don't fail the transaction deletion
      }
    }
    
    res.status(200).json({
      success: true,
      data: {},
      message: 'Transaction deleted successfully'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get transaction statistics
// @route   GET /api/transactions/stats
// @access  Private
exports.getTransactionStats = async (req, res) => {
  try {
    // Default to current month if no date range is provided
    let startDate, endDate;
    
    if (req.query.startDate && req.query.endDate) {
      startDate = new Date(req.query.startDate);
      endDate = new Date(req.query.endDate);
      
      // Validate dates
      if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
        return res.status(400).json({
          success: false,
          message: 'Invalid date format. Please use YYYY-MM-DD format.'
        });
      }
    } else {
      const now = new Date();
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    }
    
    // Ensure endDate is at the end of the day for inclusive queries
    endDate.setHours(23, 59, 59, 999);
    
    // Get transactions for the period to avoid multiple database queries
    const transactions = await Transaction.find({
      user: req.user.id,
      date: { $gte: startDate, $lte: endDate }
    }).sort({ date: 1 });
    
    // Handle no transactions case
    if (transactions.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          totalIncome: 0,
          totalExpense: 0,
          balance: 0,
          savingsRate: 0,
          categoryBreakdown: [],
          dailyData: [],
          monthlyData: [],
          isEmpty: true
        }
      });
    }
    
    // Calculate income and expense totals
    const incomeTransactions = transactions.filter(t => t.type === 'income');
    const expenseTransactions = transactions.filter(t => t.type === 'expense');
    
    const totalIncome = incomeTransactions.reduce((sum, t) => sum + t.amount, 0);
    const totalExpense = expenseTransactions.reduce((sum, t) => sum + t.amount, 0);
    const balance = totalIncome - totalExpense;
    const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;
    
    // Generate category breakdown
    const categoryMap = {};
    transactions.forEach(transaction => {
      const key = `${transaction.type}:${transaction.category}`;
      if (!categoryMap[key]) {
        categoryMap[key] = {
          type: transaction.type,
          category: transaction.category,
          total: 0,
          count: 0
        };
      }
      categoryMap[key].total += transaction.amount;
      categoryMap[key].count += 1;
    });
    
    const categoryBreakdown = Object.values(categoryMap).sort((a, b) => b.total - a.total);
    
    // Generate daily data
    const dailyMap = {};
    const dateFormat = new Intl.DateTimeFormat('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' });
    
    transactions.forEach(transaction => {
      const dateStr = dateFormat.format(new Date(transaction.date));
      if (!dailyMap[dateStr]) {
        dailyMap[dateStr] = { date: dateStr, income: 0, expense: 0 };
      }
      if (transaction.type === 'income') {
        dailyMap[dateStr].income += transaction.amount;
      } else {
        dailyMap[dateStr].expense += transaction.amount;
      }
    });
    
    // Fill in missing dates with zeros for continuous chart
    const dailyData = [];
    let currentDate = new Date(startDate);
    while (currentDate <= endDate) {
      const dateStr = dateFormat.format(currentDate);
      if (dailyMap[dateStr]) {
        dailyData.push(dailyMap[dateStr]);
      } else {
        dailyData.push({ date: dateStr, income: 0, expense: 0 });
      }
      currentDate.setDate(currentDate.getDate() + 1);
    }
    
    // Generate monthly data for trends
    const monthlyMap = {};
    transactions.forEach(transaction => {
      const date = new Date(transaction.date);
      const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
      
      if (!monthlyMap[monthKey]) {
        monthlyMap[monthKey] = {
          month: monthKey,
          income: 0,
          expense: 0,
          date: new Date(date.getFullYear(), date.getMonth(), 1)
        };
      }
      
      if (transaction.type === 'income') {
        monthlyMap[monthKey].income += transaction.amount;
      } else {
        monthlyMap[monthKey].expense += transaction.amount;
      }
    });
    
    const monthlyData = Object.values(monthlyMap).sort((a, b) => a.date - b.date);
    
    // Calculate payment method breakdown
    const paymentMethodMap = {};
    transactions.forEach(transaction => {
      const method = transaction.paymentMethod || 'other';
      if (!paymentMethodMap[method]) {
        paymentMethodMap[method] = { method, total: 0, count: 0 };
      }
      paymentMethodMap[method].total += transaction.amount;
      paymentMethodMap[method].count += 1;
    });
    
    const paymentMethodBreakdown = Object.values(paymentMethodMap);
    
    res.status(200).json({
      success: true,
      data: {
        totalIncome,
        totalExpense,
        balance,
        savingsRate,
        transactionCount: transactions.length,
        incomeCount: incomeTransactions.length,
        expenseCount: expenseTransactions.length,
        categoryBreakdown,
        dailyData,
        monthlyData,
        paymentMethodBreakdown,
        dateRange: {
          startDate: startDate.toISOString(),
          endDate: endDate.toISOString()
        },
        isEmpty: false
      }
    });
  } catch (error) {
    console.error('Error in getTransactionStats:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get transaction trends
// @route   GET /api/transactions/trends
// @access  Private
exports.getTransactionTrends = async (req, res) => {
  try {
    // Get transactions for the last 6 months
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    sixMonthsAgo.setDate(1); // Start from the 1st day of the month
    sixMonthsAgo.setHours(0, 0, 0, 0);
    
    const transactions = await Transaction.find({
      user: req.user.id,
      date: { $gte: sixMonthsAgo }
    }).sort({ date: 1 });
    
    // Handle no transactions case
    if (transactions.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          monthlyTrends: [],
          categoryTrends: [],
          isEmpty: true
        }
      });
    }
    
    // Generate monthly trends
    const monthlyMap = {};
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Initialize all months in the range with zero values
    let currentDate = new Date(sixMonthsAgo);
    const now = new Date();
    while (currentDate <= now) {
      const year = currentDate.getFullYear();
      const month = currentDate.getMonth();
      const monthKey = `${year}-${month + 1}`;
      const monthLabel = `${monthNames[month]} ${year}`;
      
      monthlyMap[monthKey] = {
        month: monthKey,
        label: monthLabel,
        income: 0,
        expense: 0,
        date: new Date(year, month, 1)
      };
      
      currentDate.setMonth(currentDate.getMonth() + 1);
    }
    
    // Fill in actual transaction data
    transactions.forEach(transaction => {
      const date = new Date(transaction.date);
      const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
      
      if (monthlyMap[monthKey]) {
        if (transaction.type === 'income') {
          monthlyMap[monthKey].income += transaction.amount;
        } else {
          monthlyMap[monthKey].expense += transaction.amount;
        }
      }
    });
    
    const monthlyTrends = Object.values(monthlyMap).sort((a, b) => a.date - b.date);
    
    // Calculate savings rate and net for each month
    monthlyTrends.forEach(month => {
      month.net = month.income - month.expense;
      month.savingsRate = month.income > 0 ? (month.net / month.income) * 100 : 0;
    });
    
    // Generate category trends
    const categoryMap = {};
    transactions.forEach(transaction => {
      if (!categoryMap[transaction.category]) {
        categoryMap[transaction.category] = {
          category: transaction.category,
          type: transaction.type,
          total: 0,
          months: {}
        };
      }
      
      const date = new Date(transaction.date);
      const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
      
      if (!categoryMap[transaction.category].months[monthKey]) {
        categoryMap[transaction.category].months[monthKey] = 0;
      }
      
      categoryMap[transaction.category].total += transaction.amount;
      categoryMap[transaction.category].months[monthKey] += transaction.amount;
    });
    
    // Format category trends for response
    const categoryTrends = [];
    for (const category in categoryMap) {
      const data = categoryMap[category];
      const monthlyData = [];
      
      for (const month of monthlyTrends) {
        const amount = data.months[month.month] || 0;
        monthlyData.push({
          month: month.label,
          amount
        });
      }
      
      categoryTrends.push({
        category: data.category,
        type: data.type,
        total: data.total,
        monthlyData
      });
    }
    
    // Sort categories by total amount
    categoryTrends.sort((a, b) => b.total - a.total);
    
    res.status(200).json({
      success: true,
      data: {
        monthlyTrends,
        categoryTrends,
        isEmpty: false
      }
    });
  } catch (error) {
    console.error('Error in getTransactionTrends:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};
