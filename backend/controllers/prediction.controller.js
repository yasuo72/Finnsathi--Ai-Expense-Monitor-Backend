const predictionService = require('../ai/predictions/prediction.service');
const SavingsGoal = require('../models/SavingsGoal');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');
const moment = require('moment');

// @desc    Predict spending for next month(s)
// @route   GET /api/predictions/spending
// @access  Private
exports.predictSpending = async (req, res) => {
  try {
    const userId = req.user.id;
    const { months = 1, category } = req.query;
    
    // Validate months parameter
    const monthsNum = parseInt(months);
    if (isNaN(monthsNum) || monthsNum < 1 || monthsNum > 12) {
      return res.status(400).json({
        success: false,
        message: 'Months parameter must be between 1 and 12'
      });
    }
    
    // Get prediction
    const prediction = await predictionService.predictSpending(userId, monthsNum, category);
    
    res.status(200).json({
      success: prediction.success,
      message: prediction.message,
      data: prediction.data
    });
  } catch (error) {
    console.error('Error in predictSpending:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Predict savings goal completion
// @route   GET /api/predictions/savings-goal/:id
// @access  Private
exports.predictSavingsGoalCompletion = async (req, res) => {
  try {
    const userId = req.user.id;
    const goalId = req.params.id;
    
    // Validate goalId
    if (!mongoose.Types.ObjectId.isValid(goalId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid goal ID'
      });
    }
    
    // Get prediction
    const prediction = await predictionService.predictSavingsGoalCompletion(userId, goalId);
    
    res.status(200).json({
      success: prediction.success,
      message: prediction.message,
      data: prediction.data
    });
  } catch (error) {
    console.error('Error in predictSavingsGoalCompletion:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get financial insights with predictions
// @route   GET /api/predictions/insights
// @access  Private
exports.getFinancialInsights = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get recent transactions (last 6 months)
    const sixMonthsAgo = moment().subtract(6, 'months').toDate();
    const transactions = await Transaction.find({
      user: userId,
      date: { $gte: sixMonthsAgo }
    }).sort({ date: -1 });
    
    // Get savings goals
    const savingsGoals = await SavingsGoal.find({ user: userId });
    
    // Calculate basic metrics
    const incomeTransactions = transactions.filter(t => t.type === 'income');
    const expenseTransactions = transactions.filter(t => t.type === 'expense');
    
    const totalIncome = incomeTransactions.reduce((sum, t) => sum + t.amount, 0);
    const totalExpense = expenseTransactions.reduce((sum, t) => sum + t.amount, 0);
    const netSavings = totalIncome - totalExpense;
    const savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0;
    
    // Group transactions by month
    const monthlyData = {};
    transactions.forEach(transaction => {
      const monthKey = moment(transaction.date).format('YYYY-MM');
      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = { income: 0, expense: 0 };
      }
      
      if (transaction.type === 'income') {
        monthlyData[monthKey].income += transaction.amount;
      } else {
        monthlyData[monthKey].expense += transaction.amount;
      }
    });
    
    // Calculate monthly averages
    const months = Object.keys(monthlyData).length || 1;
    const avgMonthlyIncome = totalIncome / months;
    const avgMonthlyExpense = totalExpense / months;
    const avgMonthlySavings = netSavings / months;
    
    // Get spending prediction for next month
    const spendingPrediction = await predictionService.predictSpending(userId, 3);
    
    // Generate insights
    const insights = [];
    
    // Savings rate insight
    if (savingsRate >= 20) {
      insights.push({
        type: 'success',
        title: 'Healthy Savings Rate',
        description: `Great job! You're saving ${savingsRate.toFixed(1)}% of your income, which is above the recommended 20%.`,
        metric: `${savingsRate.toFixed(1)}%`
      });
    } else if (savingsRate > 0) {
      insights.push({
        type: 'warning',
        title: 'Improve Your Savings Rate',
        description: `You're currently saving ${savingsRate.toFixed(1)}% of your income. Try to reach at least 20% for financial security.`,
        metric: `${savingsRate.toFixed(1)}%`
      });
    } else {
      insights.push({
        type: 'error',
        title: 'Negative Savings Rate',
        description: `You're spending more than you earn. Focus on reducing expenses to avoid debt.`,
        metric: `${savingsRate.toFixed(1)}%`
      });
    }
    
    // Spending trend insight
    if (spendingPrediction.success && spendingPrediction.data) {
      const predictedSpending = spendingPrediction.data.predictions[0]?.amount || 0;
      const lastMonthExpense = Object.values(monthlyData).pop()?.expense || avgMonthlyExpense;
      
      const spendingChange = ((predictedSpending - lastMonthExpense) / lastMonthExpense) * 100;
      
      if (spendingChange > 10) {
        insights.push({
          type: 'warning',
          title: 'Spending Increase Predicted',
          description: `Your spending is predicted to increase by ${spendingChange.toFixed(1)}% next month. Consider reviewing your budget.`,
          metric: `+${spendingChange.toFixed(1)}%`
        });
      } else if (spendingChange < -10) {
        insights.push({
          type: 'success',
          title: 'Spending Decrease Predicted',
          description: `Your spending is predicted to decrease by ${Math.abs(spendingChange).toFixed(1)}% next month. Keep up the good work!`,
          metric: `${spendingChange.toFixed(1)}%`
        });
      }
    }
    
    // Savings goals insights
    if (savingsGoals.length > 0) {
      // Get the goal closest to completion
      const sortedGoals = [...savingsGoals].sort((a, b) => {
        const progressA = a.targetAmount > 0 ? (a.currentAmount / a.targetAmount) : 0;
        const progressB = b.targetAmount > 0 ? (b.currentAmount / b.targetAmount) : 0;
        return progressB - progressA;
      });
      
      const topGoal = sortedGoals[0];
      const topGoalProgress = (topGoal.currentAmount / topGoal.targetAmount) * 100;
      
      if (topGoalProgress >= 90) {
        insights.push({
          type: 'success',
          title: 'Goal Almost Achieved',
          description: `You're ${topGoalProgress.toFixed(1)}% of the way to your "${topGoal.name}" goal. Just a little more to go!`,
          metric: `${topGoalProgress.toFixed(1)}%`
        });
      } else if (topGoalProgress >= 50) {
        insights.push({
          type: 'info',
          title: 'Goal Progress',
          description: `You're making good progress on your "${topGoal.name}" goal at ${topGoalProgress.toFixed(1)}% complete.`,
          metric: `${topGoalProgress.toFixed(1)}%`
        });
      }
      
      // For the goal with the least progress, predict completion
      const leastProgressGoal = [...savingsGoals].sort((a, b) => {
        const progressA = a.targetAmount > 0 ? (a.currentAmount / a.targetAmount) : 0;
        const progressB = b.targetAmount > 0 ? (b.currentAmount / b.targetAmount) : 0;
        return progressA - progressB;
      })[0];
      
      if (leastProgressGoal && leastProgressGoal.currentAmount < leastProgressGoal.targetAmount) {
        const goalPrediction = await predictionService.predictSavingsGoalCompletion(userId, leastProgressGoal._id);
        
        if (goalPrediction.success && goalPrediction.data) {
          const { monthsToCompletion } = goalPrediction.data;
          
          insights.push({
            type: 'info',
            title: 'Goal Completion Prediction',
            description: `At your current savings rate, you'll reach your "${leastProgressGoal.name}" goal in approximately ${monthsToCompletion} months.`,
            metric: `${monthsToCompletion} months`
          });
        }
      }
    }
    
    // Spending category insight
    const categorySpending = {};
    expenseTransactions.forEach(transaction => {
      if (!categorySpending[transaction.category]) {
        categorySpending[transaction.category] = 0;
      }
      categorySpending[transaction.category] += transaction.amount;
    });
    
    const topCategories = Object.entries(categorySpending)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([category, amount]) => ({ category, amount }));
    
    if (topCategories.length > 0) {
      const topCategory = topCategories[0];
      const topCategoryPercentage = (topCategory.amount / totalExpense) * 100;
      
      if (topCategoryPercentage > 40) {
        insights.push({
          type: 'warning',
          title: 'High Spending Concentration',
          description: `${topCategoryPercentage.toFixed(1)}% of your expenses are in the "${topCategory.category}" category. Consider diversifying your spending.`,
          metric: `${topCategoryPercentage.toFixed(1)}%`
        });
      }
    }
    
    res.status(200).json({
      success: true,
      data: {
        insights,
        metrics: {
          totalIncome,
          totalExpense,
          netSavings,
          savingsRate,
          avgMonthlyIncome,
          avgMonthlyExpense,
          avgMonthlySavings
        },
        predictions: {
          spending: spendingPrediction.success ? spendingPrediction.data : null
        }
      }
    });
  } catch (error) {
    console.error('Error in getFinancialInsights:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};
