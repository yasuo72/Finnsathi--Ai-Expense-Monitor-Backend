const Budget = require('../models/Budget');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');

// @desc    Get all budgets
// @route   GET /api/budgets
// @access  Private
exports.getBudgets = async (req, res) => {
  try {
    const budgets = await Budget.find({ user: req.user.id });
    
    res.status(200).json({
      success: true,
      count: budgets.length,
      data: budgets
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get budget by ID
// @route   GET /api/budgets/:id
// @access  Private
exports.getBudget = async (req, res) => {
  try {
    const budget = await Budget.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: 'Budget not found'
      });
    }
    
    res.status(200).json({
      success: true,
      data: budget
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Create new budget
// @route   POST /api/budgets
// @access  Private
exports.createBudget = async (req, res) => {
  try {
    // Add user to request body
    req.body.user = req.user.id;
    
    const budget = await Budget.create(req.body);
    
    res.status(201).json({
      success: true,
      data: budget
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

// @desc    Update budget
// @route   PUT /api/budgets/:id
// @access  Private
exports.updateBudget = async (req, res) => {
  try {
    let budget = await Budget.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: 'Budget not found'
      });
    }
    
    budget = await Budget.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );
    
    res.status(200).json({
      success: true,
      data: budget
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

// @desc    Delete budget
// @route   DELETE /api/budgets/:id
// @access  Private
exports.deleteBudget = async (req, res) => {
  try {
    const budget = await Budget.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: 'Budget not found'
      });
    }
    
    await budget.remove();
    
    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get budget status with spending
// @route   GET /api/budgets/:id/status
// @access  Private
exports.getBudgetStatus = async (req, res) => {
  try {
    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid budget ID format'
      });
    }
    
    const budget = await Budget.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!budget) {
      return res.status(404).json({
        success: false,
        message: 'Budget not found'
      });
    }
    
    // Calculate spending for this budget's category and date range
    const transactions = await Transaction.find({
      user: req.user.id,
      category: budget.category,
      type: 'expense',
      date: {
        $gte: budget.startDate,
        $lte: budget.endDate
      }
    }).sort({ date: -1 });
    
    const spent = transactions.reduce((total, transaction) => total + transaction.amount, 0);
    const remaining = Math.max(0, budget.limit - spent);
    const percentUsed = budget.limit > 0 ? (spent / budget.limit) * 100 : 0;
    const isExceeded = spent > budget.limit;
    
    // Update the budget's spent amount
    budget.spent = spent;
    await budget.save();
    
    res.status(200).json({
      success: true,
      data: {
        budget,
        spent,
        remaining,
        percentUsed,
        isExceeded,
        transactions: transactions.slice(0, 10) // Limit to 10 most recent transactions
      }
    });
  } catch (error) {
    console.error('Error in getBudgetStatus:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get all budgets with spending data
// @route   GET /api/budgets/stats
// @access  Private
// @desc    Get budget alerts when spending crosses threshold
// @route   GET /api/budgets/alerts?threshold=80
// @access  Private
exports.getBudgetAlerts = async (req, res) => {
  try {
    const threshold = parseFloat(req.query.threshold) || 80; // percent

    // Fetch budgets and their current spending via aggregation similar to getBudgetStats
    const budgets = await Budget.find({ user: req.user.id });
    if (budgets.length === 0) {
      return res.status(200).json({ success: true, data: [] });
    }

    // Get all expense transactions for user
    const transactions = await Transaction.find({ user: req.user.id, type: 'expense' });

    const alertBudgets = [];

    for (const budget of budgets) {
      const relatedTxns = transactions.filter(t => {
        return t.category === budget.category && t.date >= budget.startDate && t.date <= budget.endDate;
      });
      const spent = relatedTxns.reduce((sum, t) => sum + t.amount, 0);
      const percentUsed = budget.limit > 0 ? (spent / budget.limit) * 100 : 0;
      const isExceeded = spent > budget.limit;

      if (isExceeded || percentUsed >= threshold) {
        alertBudgets.push({
          _id: budget._id,
          title: budget.title,
          category: budget.category,
          limit: budget.limit,
          spent,
          percentUsed,
          isExceeded,
          startDate: budget.startDate,
          endDate: budget.endDate,
        });
      }

      // persist spent if changed
      if (budget.spent !== spent) {
        budget.spent = spent;
        await budget.save();
      }
    }

    res.status(200).json({ success: true, count: alertBudgets.length, data: alertBudgets });
  } catch (error) {
    console.error('Error in getBudgetAlerts:', error);
    res.status(500).json({ success: false, message: 'Server error', error: error.message });
  }
};

exports.getBudgetStats = async (req, res) => {
  try {
    // Get all budgets for the user
    const budgets = await Budget.find({ user: req.user.id });
    
    if (budgets.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          budgets: [],
          totalBudgeted: 0,
          totalSpent: 0,
          totalRemaining: 0,
          averageUtilization: 0,
          isEmpty: true
        }
      });
    }
    
    // Get all expense transactions
    const transactions = await Transaction.find({
      user: req.user.id,
      type: 'expense'
    });
    
    // Calculate spending for each budget
    const budgetsWithSpending = await Promise.all(budgets.map(async (budget) => {
      // Filter transactions by category and date range
      const budgetTransactions = transactions.filter(transaction => {
        return transaction.category === budget.category &&
               transaction.date >= budget.startDate &&
               transaction.date <= budget.endDate;
      });
      
      const spent = budgetTransactions.reduce((total, transaction) => total + transaction.amount, 0);
      const remaining = Math.max(0, budget.limit - spent);
      const percentUsed = budget.limit > 0 ? (spent / budget.limit) * 100 : 0;
      const isExceeded = spent > budget.limit;
      
      // Update the budget's spent amount in the database
      budget.spent = spent;
      await budget.save();
      
      return {
        _id: budget._id,
        name: budget.name,
        category: budget.category,
        limit: budget.limit,
        spent,
        remaining,
        percentUsed,
        isExceeded,
        startDate: budget.startDate,
        endDate: budget.endDate,
        color: budget.color,
        icon: budget.icon
      };
    }));
    
    // Calculate overall statistics
    const totalBudgeted = budgets.reduce((total, budget) => total + budget.limit, 0);
    const totalSpent = budgetsWithSpending.reduce((total, budget) => total + budget.spent, 0);
    const totalRemaining = Math.max(0, totalBudgeted - totalSpent);
    
    // Calculate average utilization percentage
    const utilizationPercentages = budgetsWithSpending
      .filter(budget => budget.limit > 0)
      .map(budget => budget.percentUsed);
    
    const averageUtilization = utilizationPercentages.length > 0
      ? utilizationPercentages.reduce((sum, percent) => sum + percent, 0) / utilizationPercentages.length
      : 0;
    
    // Group budgets by category
    const categoryMap = {};
    budgetsWithSpending.forEach(budget => {
      if (!categoryMap[budget.category]) {
        categoryMap[budget.category] = {
          category: budget.category,
          totalLimit: 0,
          totalSpent: 0,
          budgetCount: 0
        };
      }
      categoryMap[budget.category].totalLimit += budget.limit;
      categoryMap[budget.category].totalSpent += budget.spent;
      categoryMap[budget.category].budgetCount += 1;
    });
    
    const categoryStats = Object.values(categoryMap).map(cat => ({
      ...cat,
      percentUsed: cat.totalLimit > 0 ? (cat.totalSpent / cat.totalLimit) * 100 : 0,
      isExceeded: cat.totalSpent > cat.totalLimit
    }));
    
    res.status(200).json({
      success: true,
      data: {
        budgets: budgetsWithSpending,
        totalBudgeted,
        totalSpent,
        totalRemaining,
        averageUtilization,
        categoryStats,
        isEmpty: false
      }
    });
  } catch (error) {
    console.error('Error in getBudgetStats:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};
