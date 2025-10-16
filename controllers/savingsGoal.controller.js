const SavingsGoal = require('../models/SavingsGoal');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');
const GamificationService = require('../services/gamification.service');

// @desc    Get all savings goals
// @route   GET /api/savings-goals
// @access  Private
exports.getSavingsGoals = async (req, res) => {
  try {
    const savingsGoals = await SavingsGoal.find({ user: req.user.id });
    
    res.status(200).json({
      success: true,
      count: savingsGoals.length,
      data: savingsGoals
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get savings goal by ID
// @route   GET /api/savings-goals/:id
// @access  Private
exports.getSavingsGoal = async (req, res) => {
  try {
    const savingsGoal = await SavingsGoal.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!savingsGoal) {
      return res.status(404).json({
        success: false,
        message: 'Savings goal not found'
      });
    }
    
    res.status(200).json({
      success: true,
      data: savingsGoal
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Create new savings goal
// @route   POST /api/savings-goals
// @access  Private
exports.createSavingsGoal = async (req, res) => {
  try {
    // Add user to request body
    req.body.user = req.user.id;
    
    const savingsGoal = await SavingsGoal.create(req.body);
    
    // Update gamification (XP, achievements, challenges)
    try {
      await GamificationService.updateAfterSavingsGoal(req.user.id, savingsGoal);
    } catch (gamificationError) {
      console.error('Error updating gamification:', gamificationError);
    }
    
    res.status(201).json({
      success: true,
      data: savingsGoal
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

// @desc    Update savings goal
// @route   PUT /api/savings-goals/:id
// @access  Private
exports.updateSavingsGoal = async (req, res) => {
  try {
    let savingsGoal = await SavingsGoal.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!savingsGoal) {
      return res.status(404).json({
        success: false,
        message: 'Savings goal not found'
      });
    }
    
    savingsGoal = await SavingsGoal.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );
    
    res.status(200).json({
      success: true,
      data: savingsGoal
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

// @desc    Delete savings goal
// @route   DELETE /api/savings-goals/:id
// @access  Private
exports.deleteSavingsGoal = async (req, res) => {
  try {
    const savingsGoal = await SavingsGoal.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!savingsGoal) {
      return res.status(404).json({
        success: false,
        message: 'Savings goal not found'
      });
    }
    
    await savingsGoal.remove();
    
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

// @desc    Add amount to savings goal
// @route   POST /api/savings-goals/:id/add
// @access  Private
exports.addToSavingsGoal = async (req, res) => {
  try {
    const { amount, description, createTransaction } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid amount'
      });
    }
    
    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid savings goal ID format'
      });
    }
    
    let savingsGoal = await SavingsGoal.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!savingsGoal) {
      return res.status(404).json({
        success: false,
        message: 'Savings goal not found'
      });
    }
    
    // Update current amount
    savingsGoal.currentAmount += amount;
    
    // Check if goal is completed
    const isCompleted = savingsGoal.currentAmount >= savingsGoal.targetAmount;
    
    // If goal is completed for the first time, record completion date
    if (isCompleted && !savingsGoal.completedDate) {
      savingsGoal.completedDate = new Date();
    }
    
    // Add a contribution entry
    savingsGoal.contributions.push({
      amount,
      date: new Date(),
      description: description || 'Contribution to savings goal'
    });
    
    await savingsGoal.save();
    
    // Update gamification (XP, challenges)
    try {
      await GamificationService.updateAfterSavingsGoal(req.user.id, savingsGoal);
    } catch (gamificationError) {
      console.error('Error updating gamification:', gamificationError);
    }
    
    // Create a transaction record if requested
    if (createTransaction) {
      await Transaction.create({
        user: req.user.id,
        amount,
        type: 'expense', // Saving money is considered an expense (money going out of available funds)
        category: 'Savings',
        description: description || `Contribution to ${savingsGoal.name} savings goal`,
        date: new Date(),
        paymentMethod: 'transfer'
      });
    }
    
    res.status(200).json({
      success: true,
      data: {
        savingsGoal,
        isCompleted,
        progress: savingsGoal.currentAmount / savingsGoal.targetAmount,
        remainingAmount: Math.max(0, savingsGoal.targetAmount - savingsGoal.currentAmount)
      }
    });
  } catch (error) {
    console.error('Error in addToSavingsGoal:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Withdraw amount from savings goal
// @route   POST /api/savings-goals/:id/withdraw
// @access  Private
exports.withdrawFromSavingsGoal = async (req, res) => {
  try {
    const { amount, description, createTransaction } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid amount'
      });
    }
    
    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid savings goal ID format'
      });
    }
    
    let savingsGoal = await SavingsGoal.findOne({
      _id: req.params.id,
      user: req.user.id
    });
    
    if (!savingsGoal) {
      return res.status(404).json({
        success: false,
        message: 'Savings goal not found'
      });
    }
    
    // Check if there's enough money to withdraw
    if (amount > savingsGoal.currentAmount) {
      return res.status(400).json({
        success: false,
        message: 'Insufficient funds in savings goal'
      });
    }
    
    // Update current amount
    savingsGoal.currentAmount -= amount;
    
    // Add a withdrawal entry
    savingsGoal.withdrawals.push({
      amount,
      date: new Date(),
      description: description || 'Withdrawal from savings goal'
    });
    
    await savingsGoal.save();
    
    // Create a transaction record if requested
    if (createTransaction) {
      await Transaction.create({
        user: req.user.id,
        amount,
        type: 'income', // Withdrawing from savings is considered income (money coming back to available funds)
        category: 'Savings Withdrawal',
        description: description || `Withdrawal from ${savingsGoal.name} savings goal`,
        date: new Date(),
        paymentMethod: 'transfer'
      });
    }
    
    res.status(200).json({
      success: true,
      data: {
        savingsGoal,
        progress: savingsGoal.currentAmount / savingsGoal.targetAmount,
        remainingAmount: Math.max(0, savingsGoal.targetAmount - savingsGoal.currentAmount)
      }
    });
  } catch (error) {
    console.error('Error in withdrawFromSavingsGoal:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get savings goals statistics
// @route   GET /api/savings-goals/stats
// @access  Private
exports.getSavingsGoalsStats = async (req, res) => {
  try {
    const savingsGoals = await SavingsGoal.find({ user: req.user.id });
    
    if (savingsGoals.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          totalSaved: 0,
          totalTarget: 0,
          overallProgress: 0,
          completedGoals: 0,
          activeGoals: 0,
          isEmpty: true
        }
      });
    }
    
    // Calculate overall statistics
    const totalSaved = savingsGoals.reduce((sum, goal) => sum + goal.currentAmount, 0);
    const totalTarget = savingsGoals.reduce((sum, goal) => sum + goal.targetAmount, 0);
    const overallProgress = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;
    
    const completedGoals = savingsGoals.filter(goal => goal.currentAmount >= goal.targetAmount).length;
    const activeGoals = savingsGoals.length - completedGoals;
    
    // Get goals by category
    const categoryMap = {};
    savingsGoals.forEach(goal => {
      if (!categoryMap[goal.category]) {
        categoryMap[goal.category] = {
          category: goal.category,
          totalSaved: 0,
          totalTarget: 0,
          count: 0
        };
      }
      categoryMap[goal.category].totalSaved += goal.currentAmount;
      categoryMap[goal.category].totalTarget += goal.targetAmount;
      categoryMap[goal.category].count += 1;
    });
    
    const categoryStats = Object.values(categoryMap).map(cat => ({
      ...cat,
      progress: cat.totalTarget > 0 ? (cat.totalSaved / cat.totalTarget) * 100 : 0
    }));
    
    // Calculate monthly contributions
    const monthlyContributions = {};
    savingsGoals.forEach(goal => {
      if (goal.contributions && goal.contributions.length > 0) {
        goal.contributions.forEach(contribution => {
          const date = new Date(contribution.date);
          const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
          
          if (!monthlyContributions[monthKey]) {
            monthlyContributions[monthKey] = {
              month: monthKey,
              amount: 0,
              date: new Date(date.getFullYear(), date.getMonth(), 1)
            };
          }
          
          monthlyContributions[monthKey].amount += contribution.amount;
        });
      }
    });
    
    const contributionTrend = Object.values(monthlyContributions).sort((a, b) => a.date - b.date);
    
    // Format goals with progress info
    const goalsWithProgress = savingsGoals.map(goal => ({
      _id: goal._id,
      name: goal.name,
      category: goal.category,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      targetDate: goal.targetDate,
      progress: goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) * 100 : 0,
      isCompleted: goal.currentAmount >= goal.targetAmount,
      completedDate: goal.completedDate,
      icon: goal.icon,
      color: goal.color
    }));
    
    res.status(200).json({
      success: true,
      data: {
        totalSaved,
        totalTarget,
        overallProgress,
        completedGoals,
        activeGoals,
        categoryStats,
        contributionTrend,
        goals: goalsWithProgress,
        isEmpty: false
      }
    });
  } catch (error) {
    console.error('Error in getSavingsGoalsStats:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};
