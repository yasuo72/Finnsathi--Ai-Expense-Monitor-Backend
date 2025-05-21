const chatbotService = require('../ai/chatbot/chatbot.service');
const Transaction = require('../models/Transaction');
const Budget = require('../models/Budget');
const SavingsGoal = require('../models/SavingsGoal');
const User = require('../models/User');
const mongoose = require('mongoose');
const moment = require('moment');

// @desc    Process chatbot message
// @route   POST /api/chatbot/message
// @access  Private
exports.processMessage = async (req, res) => {
  try {
    const { message } = req.body;
    const userId = req.user.id;
    
    if (!message) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a message'
      });
    }
    
    // Process the message with NLP
    const nlpResponse = await chatbotService.processMessage(message, userId);
    
    // Handle specific intents with additional data
    let enhancedResponse = await enhanceResponseWithData(nlpResponse, userId);
    
    res.status(200).json({
      success: true,
      data: enhancedResponse
    });
  } catch (error) {
    console.error('Error in processMessage:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Train or retrain chatbot model
// @route   POST /api/chatbot/train
// @access  Private (Admin only)
exports.trainModel = async (req, res) => {
  try {
    // Check if admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to train the model'
      });
    }
    
    await chatbotService.trainModel();
    
    res.status(200).json({
      success: true,
      message: 'Chatbot model trained successfully'
    });
  } catch (error) {
    console.error('Error in trainModel:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// Helper function to enhance NLP responses with actual user data
async function enhanceResponseWithData(nlpResponse, userId) {
  // If no intent was matched, return the original response
  if (!nlpResponse.intent || nlpResponse.intent === 'unknown' || nlpResponse.intent === 'error') {
    return nlpResponse;
  }
  
  try {
    const [category, action] = nlpResponse.intent.split('.');
    let enhancedAnswer = nlpResponse.answer;
    let additionalData = {};
    
    switch (category) {
      case 'budget':
        if (action === 'spent') {
          const currentMonth = new Date();
          currentMonth.setDate(1);
          currentMonth.setHours(0, 0, 0, 0);
          
          const expenses = await Transaction.find({
            user: userId,
            type: 'expense',
            date: { $gte: currentMonth }
          });
          
          const totalSpent = expenses.reduce((sum, expense) => sum + expense.amount, 0);
          
          // Get top 3 spending categories
          const categorySpending = {};
          expenses.forEach(expense => {
            if (!categorySpending[expense.category]) {
              categorySpending[expense.category] = 0;
            }
            categorySpending[expense.category] += expense.amount;
          });
          
          const topCategories = Object.entries(categorySpending)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 3)
            .map(([category, amount]) => ({ category, amount }));
          
          enhancedAnswer = `This month, you've spent a total of ${totalSpent.toFixed(2)}. `;
          
          if (topCategories.length > 0) {
            enhancedAnswer += `Your top spending categories are: `;
            topCategories.forEach((cat, index) => {
              enhancedAnswer += `${cat.category} (${cat.amount.toFixed(2)})`;
              if (index < topCategories.length - 1) {
                enhancedAnswer += ', ';
              }
            });
          }
          
          additionalData = {
            totalSpent,
            topCategories,
            transactionCount: expenses.length
          };
        } else if (action === 'remaining') {
          const budgets = await Budget.find({ user: userId });
          const currentMonth = new Date();
          currentMonth.setDate(1);
          currentMonth.setHours(0, 0, 0, 0);
          
          const expenses = await Transaction.find({
            user: userId,
            type: 'expense',
            date: { $gte: currentMonth }
          });
          
          const totalBudget = budgets.reduce((sum, budget) => sum + budget.limit, 0);
          const totalSpent = expenses.reduce((sum, expense) => expense.amount, 0);
          const remaining = totalBudget - totalSpent;
          
          enhancedAnswer = `You have ${remaining.toFixed(2)} remaining from your total budget of ${totalBudget.toFixed(2)} for this month. `;
          
          if (remaining < 0) {
            enhancedAnswer += `You've exceeded your budget by ${Math.abs(remaining).toFixed(2)}.`;
          } else if (remaining < totalBudget * 0.2) {
            enhancedAnswer += `You're getting close to your budget limit. Consider reducing non-essential expenses.`;
          } else {
            enhancedAnswer += `You're doing well at staying within your budget!`;
          }
          
          additionalData = {
            totalBudget,
            totalSpent,
            remaining,
            budgetCategories: budgets.map(b => ({
              category: b.category,
              limit: b.limit,
              spent: b.spent,
              remaining: b.limit - b.spent
            }))
          };
        }
        break;
        
      case 'savings':
        if (action === 'status') {
          const savingsGoals = await SavingsGoal.find({ user: userId });
          
          if (savingsGoals.length === 0) {
            enhancedAnswer = `You don't have any savings goals set up yet. Would you like to create one?`;
          } else {
            const totalSaved = savingsGoals.reduce((sum, goal) => sum + goal.currentAmount, 0);
            const totalTarget = savingsGoals.reduce((sum, goal) => sum + goal.targetAmount, 0);
            const overallProgress = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;
            
            enhancedAnswer = `You've saved ${totalSaved.toFixed(2)} towards your goals, which is ${overallProgress.toFixed(1)}% of your total target. `;
            
            // Add details about individual goals
            if (savingsGoals.length === 1) {
              const goal = savingsGoals[0];
              const progress = (goal.currentAmount / goal.targetAmount) * 100;
              enhancedAnswer += `For your "${goal.name}" goal, you've saved ${goal.currentAmount.toFixed(2)} out of ${goal.targetAmount.toFixed(2)} (${progress.toFixed(1)}%).`;
            } else {
              enhancedAnswer += `You have ${savingsGoals.length} active savings goals. `;
              
              // Find the goal with the highest progress
              const sortedGoals = [...savingsGoals].sort((a, b) => {
                const progressA = a.targetAmount > 0 ? (a.currentAmount / a.targetAmount) : 0;
                const progressB = b.targetAmount > 0 ? (b.currentAmount / b.targetAmount) : 0;
                return progressB - progressA;
              });
              
              const topGoal = sortedGoals[0];
              const topProgress = (topGoal.currentAmount / topGoal.targetAmount) * 100;
              
              enhancedAnswer += `Your "${topGoal.name}" goal has the most progress at ${topProgress.toFixed(1)}%.`;
            }
          }
          
          additionalData = {
            goals: savingsGoals.map(g => ({
              id: g._id,
              name: g.name,
              current: g.currentAmount,
              target: g.targetAmount,
              progress: g.targetAmount > 0 ? (g.currentAmount / g.targetAmount) * 100 : 0,
              deadline: g.targetDate
            }))
          };
        } else if (action === 'recommendation') {
          // Get user income and expenses
          const lastThreeMonths = new Date();
          lastThreeMonths.setMonth(lastThreeMonths.getMonth() - 3);
          
          const transactions = await Transaction.find({
            user: userId,
            date: { $gte: lastThreeMonths }
          });
          
          const incomeTransactions = transactions.filter(t => t.type === 'income');
          const expenseTransactions = transactions.filter(t => t.type === 'expense');
          
          const totalIncome = incomeTransactions.reduce((sum, t) => sum + t.amount, 0);
          const totalExpense = expenseTransactions.reduce((sum, t) => sum + t.amount, 0);
          
          const avgMonthlyIncome = totalIncome / 3;
          const avgMonthlyExpense = totalExpense / 3;
          const avgMonthlySavings = avgMonthlyIncome - avgMonthlyExpense;
          
          // Calculate recommended savings (20% of income is a common rule)
          const recommendedSavings = avgMonthlyIncome * 0.2;
          const currentSavingsRate = avgMonthlyIncome > 0 ? (avgMonthlySavings / avgMonthlyIncome) * 100 : 0;
          
          enhancedAnswer = `Based on your average monthly income of ${avgMonthlyIncome.toFixed(2)}, I recommend saving at least ${recommendedSavings.toFixed(2)} per month (20% of income). `;
          
          if (avgMonthlySavings >= recommendedSavings) {
            enhancedAnswer += `You're currently saving an average of ${avgMonthlySavings.toFixed(2)} per month (${currentSavingsRate.toFixed(1)}% of income), which is excellent!`;
          } else if (avgMonthlySavings > 0) {
            enhancedAnswer += `You're currently saving an average of ${avgMonthlySavings.toFixed(2)} per month (${currentSavingsRate.toFixed(1)}% of income). Try to increase this by reducing expenses in non-essential categories.`;
          } else {
            enhancedAnswer += `You're currently spending more than you earn by ${Math.abs(avgMonthlySavings).toFixed(2)} per month. Focus on reducing expenses to start building savings.`;
          }
          
          additionalData = {
            avgMonthlyIncome,
            avgMonthlyExpense,
            avgMonthlySavings,
            recommendedSavings,
            currentSavingsRate
          };
        }
        break;
        
      case 'expenses':
        if (action === 'top') {
          const lastThreeMonths = new Date();
          lastThreeMonths.setMonth(lastThreeMonths.getMonth() - 3);
          
          const expenses = await Transaction.find({
            user: userId,
            type: 'expense',
            date: { $gte: lastThreeMonths }
          });
          
          // Group by category
          const categorySpending = {};
          expenses.forEach(expense => {
            if (!categorySpending[expense.category]) {
              categorySpending[expense.category] = 0;
            }
            categorySpending[expense.category] += expense.amount;
          });
          
          // Sort categories by amount
          const sortedCategories = Object.entries(categorySpending)
            .sort((a, b) => b[1] - a[1])
            .map(([category, amount]) => ({ category, amount }));
          
          const topCategories = sortedCategories.slice(0, 5);
          
          enhancedAnswer = `Your top spending categories over the last 3 months are: `;
          topCategories.forEach((cat, index) => {
            enhancedAnswer += `${cat.category} (${cat.amount.toFixed(2)})`;
            if (index < topCategories.length - 1) {
              enhancedAnswer += ', ';
            }
          });
          
          if (topCategories.length > 0) {
            enhancedAnswer += `. Your highest spending category is ${topCategories[0].category}, which accounts for ${((topCategories[0].amount / expenses.reduce((sum, e) => sum + e.amount, 0)) * 100).toFixed(1)}% of your total expenses.`;
          }
          
          additionalData = {
            topCategories,
            totalExpenses: expenses.reduce((sum, e) => sum + e.amount, 0),
            expenseCount: expenses.length
          };
        } else if (action === 'reduce') {
          const lastThreeMonths = new Date();
          lastThreeMonths.setMonth(lastThreeMonths.getMonth() - 3);
          
          const expenses = await Transaction.find({
            user: userId,
            type: 'expense',
            date: { $gte: lastThreeMonths }
          });
          
          // Group by category
          const categorySpending = {};
          expenses.forEach(expense => {
            if (!categorySpending[expense.category]) {
              categorySpending[expense.category] = 0;
            }
            categorySpending[expense.category] += expense.amount;
          });
          
          // Sort categories by amount
          const sortedCategories = Object.entries(categorySpending)
            .sort((a, b) => b[1] - a[1])
            .map(([category, amount]) => ({ category, amount }));
          
          const topCategories = sortedCategories.slice(0, 3);
          
          enhancedAnswer = `Based on your spending patterns, here are some tips to reduce expenses:\n\n`;
          
          if (topCategories.length > 0) {
            enhancedAnswer += `1. Focus on your top spending categories: `;
            topCategories.forEach((cat, index) => {
              enhancedAnswer += `${cat.category} (${cat.amount.toFixed(2)})`;
              if (index < topCategories.length - 1) {
                enhancedAnswer += ', ';
              }
            });
            enhancedAnswer += `.\n`;
          }
          
          enhancedAnswer += `2. Set a budget for each category and track your spending regularly.\n`;
          enhancedAnswer += `3. Look for subscriptions you don't use and cancel them.\n`;
          enhancedAnswer += `4. Consider meal planning to reduce food expenses.\n`;
          enhancedAnswer += `5. Wait 24 hours before making non-essential purchases to avoid impulse buying.`;
          
          additionalData = {
            topCategories,
            totalExpenses: expenses.reduce((sum, e) => sum + e.amount, 0)
          };
        }
        break;
        
      case 'income':
        if (action === 'status') {
          const currentMonth = new Date();
          currentMonth.setDate(1);
          currentMonth.setHours(0, 0, 0, 0);
          
          const lastMonth = new Date(currentMonth);
          lastMonth.setMonth(lastMonth.getMonth() - 1);
          
          const currentMonthIncome = await Transaction.find({
            user: userId,
            type: 'income',
            date: { $gte: currentMonth }
          });
          
          const lastMonthIncome = await Transaction.find({
            user: userId,
            type: 'income',
            date: { $gte: lastMonth, $lt: currentMonth }
          });
          
          const currentTotal = currentMonthIncome.reduce((sum, t) => sum + t.amount, 0);
          const lastTotal = lastMonthIncome.reduce((sum, t) => sum + t.amount, 0);
          
          const percentChange = lastTotal > 0 ? ((currentTotal - lastTotal) / lastTotal) * 100 : 0;
          
          enhancedAnswer = `This month, you've earned a total of ${currentTotal.toFixed(2)}. `;
          
          if (currentMonthIncome.length > 0) {
            // Group by source
            const sourceIncome = {};
            currentMonthIncome.forEach(income => {
              if (!sourceIncome[income.category]) {
                sourceIncome[income.category] = 0;
              }
              sourceIncome[income.category] += income.amount;
            });
            
            const sources = Object.entries(sourceIncome)
              .sort((a, b) => b[1] - a[1])
              .map(([category, amount]) => ({ category, amount }));
            
            if (sources.length > 0) {
              enhancedAnswer += `Your main income source is ${sources[0].category} (${sources[0].amount.toFixed(2)}). `;
            }
          }
          
          if (lastTotal > 0) {
            if (percentChange > 0) {
              enhancedAnswer += `Your income has increased by ${percentChange.toFixed(1)}% compared to last month.`;
            } else if (percentChange < 0) {
              enhancedAnswer += `Your income has decreased by ${Math.abs(percentChange).toFixed(1)}% compared to last month.`;
            } else {
              enhancedAnswer += `Your income is the same as last month.`;
            }
          }
          
          additionalData = {
            currentMonthIncome: currentTotal,
            lastMonthIncome: lastTotal,
            percentChange,
            transactionCount: currentMonthIncome.length
          };
        }
        break;
        
      case 'finance':
        if (action === 'health') {
          // Get user data
          const user = await User.findById(userId);
          
          // Get transactions for last 6 months
          const sixMonthsAgo = new Date();
          sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
          
          const transactions = await Transaction.find({
            user: userId,
            date: { $gte: sixMonthsAgo }
          });
          
          const incomeTransactions = transactions.filter(t => t.type === 'income');
          const expenseTransactions = transactions.filter(t => t.type === 'expense');
          
          const totalIncome = incomeTransactions.reduce((sum, t) => sum + t.amount, 0);
          const totalExpense = expenseTransactions.reduce((sum, t) => sum + t.amount, 0);
          
          const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;
          
          // Get savings goals
          const savingsGoals = await SavingsGoal.find({ user: userId });
          const totalSaved = savingsGoals.reduce((sum, goal) => sum + goal.currentAmount, 0);
          const totalTarget = savingsGoals.reduce((sum, goal) => sum + goal.targetAmount, 0);
          const savingsProgress = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;
          
          // Calculate financial health score (simple version)
          let healthScore = 0;
          
          // Savings rate contributes up to 40 points
          if (savingsRate >= 20) {
            healthScore += 40; // Excellent savings rate
          } else if (savingsRate >= 15) {
            healthScore += 35;
          } else if (savingsRate >= 10) {
            healthScore += 25;
          } else if (savingsRate >= 5) {
            healthScore += 15;
          } else if (savingsRate > 0) {
            healthScore += 10;
          }
          
          // Savings goals progress contributes up to 30 points
          if (savingsGoals.length > 0) {
            if (savingsProgress >= 75) {
              healthScore += 30;
            } else if (savingsProgress >= 50) {
              healthScore += 25;
            } else if (savingsProgress >= 25) {
              healthScore += 15;
            } else if (savingsProgress > 0) {
              healthScore += 10;
            }
          }
          
          // Regular income contributes up to 30 points
          const monthlyData = {};
          incomeTransactions.forEach(transaction => {
            const date = new Date(transaction.date);
            const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
            
            if (!monthlyData[monthKey]) {
              monthlyData[monthKey] = { income: 0, expense: 0 };
            }
            
            monthlyData[monthKey].income += transaction.amount;
          });
          
          const monthsWithIncome = Object.keys(monthlyData).length;
          if (monthsWithIncome >= 6) {
            healthScore += 30; // Income for all 6 months
          } else if (monthsWithIncome >= 4) {
            healthScore += 20;
          } else if (monthsWithIncome >= 2) {
            healthScore += 10;
          }
          
          // Interpret health score
          let healthStatus = '';
          if (healthScore >= 80) {
            healthStatus = 'Excellent';
          } else if (healthScore >= 60) {
            healthStatus = 'Good';
          } else if (healthScore >= 40) {
            healthStatus = 'Fair';
          } else {
            healthStatus = 'Needs Improvement';
          }
          
          enhancedAnswer = `Your financial health score is ${healthScore}/100, which is ${healthStatus}. `;
          
          if (savingsRate >= 20) {
            enhancedAnswer += `You have an excellent savings rate of ${savingsRate.toFixed(1)}%. `;
          } else if (savingsRate > 0) {
            enhancedAnswer += `Your savings rate is ${savingsRate.toFixed(1)}%. The recommended rate is at least 20%. `;
          } else {
            enhancedAnswer += `You're currently spending more than you earn. Focus on reducing expenses. `;
          }
          
          if (savingsGoals.length > 0) {
            enhancedAnswer += `You've made ${savingsProgress.toFixed(1)}% progress toward your savings goals. `;
          }
          
          // Add recommendations
          enhancedAnswer += `\n\nRecommendations to improve your financial health:\n`;
          
          if (savingsRate < 20) {
            enhancedAnswer += `- Aim to save at least 20% of your income\n`;
          }
          
          if (monthsWithIncome < 6) {
            enhancedAnswer += `- Work on establishing a stable income source\n`;
          }
          
          if (savingsGoals.length === 0) {
            enhancedAnswer += `- Set up savings goals to track your progress\n`;
          }
          
          enhancedAnswer += `- Review your budget regularly and adjust as needed`;
          
          additionalData = {
            healthScore,
            healthStatus,
            savingsRate,
            savingsProgress,
            monthsWithIncome,
            totalIncome,
            totalExpense
          };
        }
        break;
        
      case 'transaction':
        // These intents are handled by the frontend to show the add transaction form
        if (action === 'add_expense') {
          enhancedAnswer = `I can help you add an expense. Please provide the following details:`;
          additionalData = {
            showTransactionForm: true,
            transactionType: 'expense'
          };
        } else if (action === 'add_income') {
          enhancedAnswer = `I can help you add income. Please provide the following details:`;
          additionalData = {
            showTransactionForm: true,
            transactionType: 'income'
          };
        }
        break;
        
      case 'prediction':
        // These will be handled by the prediction service
        // For now, just return a placeholder response
        if (action === 'spending' || action === 'savings') {
          enhancedAnswer = `I'll analyze your data to make a prediction. Please wait a moment...`;
          additionalData = {
            requiresPrediction: true,
            predictionType: action
          };
        }
        break;
    }
    
    return {
      ...nlpResponse,
      answer: enhancedAnswer,
      additionalData
    };
  } catch (error) {
    console.error('Error enhancing response:', error);
    return nlpResponse;
  }
}
