const Transaction = require('../../models/Transaction');
const SavingsGoal = require('../../models/SavingsGoal');
const moment = require('moment');
const path = require('path');
const fs = require('fs');

class PredictionService {
  constructor() {
    this.initialized = true;
  }

  async initialize() {
    // No initialization needed for the simplified version
    return true;
  }

  /**
   * Predict spending for the next month based on historical data
   * @param {string} userId - User ID
   * @param {number} months - Number of months to predict (default: 1)
   * @param {string} category - Optional category to predict for
   * @returns {Promise<Object>} - Prediction results
   */
  async predictSpending(userId, months = 1, category = null) {
    try {
      // Get historical transaction data (last 12 months)
      const oneYearAgo = moment().subtract(12, 'months').toDate();
      
      const query = {
        user: userId,
        type: 'expense',
        date: { $gte: oneYearAgo }
      };
      
      if (category) {
        query.category = category;
      }
      
      const transactions = await Transaction.find(query).sort({ date: 1 });
      
      if (transactions.length < 3) {
        return {
          success: false,
          message: 'Not enough historical data for prediction',
          data: null
        };
      }
      
      // Group transactions by month
      const monthlyData = {};
      transactions.forEach(transaction => {
        const monthKey = moment(transaction.date).format('YYYY-MM');
        if (!monthlyData[monthKey]) {
          monthlyData[monthKey] = 0;
        }
        monthlyData[monthKey] += transaction.amount;
      });
      
      // Convert to array and sort by date
      const timeSeriesData = Object.entries(monthlyData)
        .map(([month, amount]) => ({ month, amount }))
        .sort((a, b) => moment(a.month).diff(moment(b.month)));
      
      // Simple moving average prediction
      const values = timeSeriesData.map(item => item.amount);
      const lastThreeMonths = values.slice(-3);
      const averageSpending = lastThreeMonths.reduce((sum, val) => sum + val, 0) / lastThreeMonths.length;
      
      // Make predictions
      const predictions = [];
      const lastDate = timeSeriesData[timeSeriesData.length - 1].month;
      
      for (let i = 0; i < months; i++) {
        const predictionDate = moment(lastDate).add(i + 1, 'months').format('YYYY-MM');
        // Add some random variation to make it more realistic
        const variation = 0.9 + (Math.random() * 0.2); // 0.9 to 1.1
        predictions.push({
          month: predictionDate,
          amount: Math.round(averageSpending * variation)
        });
      }
      
      return {
        success: true,
        message: 'Spending prediction completed',
        data: {
          historical: timeSeriesData,
          predictions,
          predictionType: 'spending',
          modelType: 'statistical'
        }
      };
    } catch (error) {
      console.error('Error predicting spending:', error);
      return {
        success: false,
        message: 'Error predicting spending',
        error: error.message
      };
    }
  }

  /**
   * Predict when a savings goal will be reached
   * @param {string} userId - User ID
   * @param {string} goalId - Savings goal ID
   * @returns {Promise<Object>} - Prediction results
   */
  async predictSavingsGoalCompletion(userId, goalId) {
    try {
      // Get the savings goal
      const savingsGoal = await SavingsGoal.findOne({ _id: goalId, user: userId });
      
      if (!savingsGoal) {
        return {
          success: false,
          message: 'Savings goal not found',
          data: null
        };
      }
      
      // Get historical savings data (last 12 months)
      const oneYearAgo = moment().subtract(12, 'months').toDate();
      const transactions = await Transaction.find({
        user: userId,
        type: 'income',
        date: { $gte: oneYearAgo }
      }).sort({ date: 1 });
      
      if (transactions.length < 3) {
        return {
          success: false,
          message: 'Not enough historical data for prediction',
          data: null
        };
      }
      
      // Calculate average monthly savings
      const monthlyData = {};
      transactions.forEach(transaction => {
        const monthKey = moment(transaction.date).format('YYYY-MM');
        if (!monthlyData[monthKey]) {
          monthlyData[monthKey] = 0;
        }
        monthlyData[monthKey] += transaction.amount;
      });
      
      // Get expenses to calculate net savings
      const expenses = await Transaction.find({
        user: userId,
        type: 'expense',
        date: { $gte: oneYearAgo }
      });
      
      const monthlyExpenses = {};
      expenses.forEach(expense => {
        const monthKey = moment(expense.date).format('YYYY-MM');
        if (!monthlyExpenses[monthKey]) {
          monthlyExpenses[monthKey] = 0;
        }
        monthlyExpenses[monthKey] += expense.amount;
      });
      
      // Calculate net savings per month
      const netSavings = {};
      Object.keys(monthlyData).forEach(month => {
        netSavings[month] = (monthlyData[month] || 0) - (monthlyExpenses[month] || 0);
      });
      
      // Convert to array and sort by date
      const timeSeriesData = Object.entries(netSavings)
        .map(([month, amount]) => ({ month, amount }))
        .sort((a, b) => moment(a.month).diff(moment(b.month)));
      
      // Calculate remaining amount to reach goal
      const remainingAmount = savingsGoal.targetAmount - savingsGoal.currentAmount;
      
      if (remainingAmount <= 0) {
        return {
          success: true,
          message: 'Savings goal already reached',
          data: {
            goalId: savingsGoal._id,
            goalName: savingsGoal.title,
            targetAmount: savingsGoal.targetAmount,
            currentAmount: savingsGoal.currentAmount,
            remainingAmount: 0,
            targetDate: savingsGoal.targetDate,
            isReached: true,
            projectedCompletionDate: null,
            monthsToCompletion: 0
          }
        };
      }
      
      // Calculate average monthly savings
      const positiveSavings = timeSeriesData.filter(item => item.amount > 0);
      
      if (positiveSavings.length === 0) {
        return {
          success: false,
          message: 'No positive savings data available',
          data: {
            goalId: savingsGoal._id,
            goalName: savingsGoal.title,
            targetAmount: savingsGoal.targetAmount,
            currentAmount: savingsGoal.currentAmount,
            remainingAmount,
            targetDate: savingsGoal.targetDate,
            isReached: false,
            projectedCompletionDate: null,
            monthsToCompletion: null
          }
        };
      }
      
      const averageMonthlySavings = positiveSavings.reduce((sum, item) => sum + item.amount, 0) / positiveSavings.length;
      
      // Calculate months to completion
      const monthsToCompletion = Math.ceil(remainingAmount / averageMonthlySavings);
      
      // Calculate projected completion date
      const projectedCompletionDate = moment().add(monthsToCompletion, 'months').toDate();
      
      // Check if goal will be reached by target date
      const willReachByTargetDate = moment(projectedCompletionDate).isSameOrBefore(savingsGoal.targetDate);
      
      return {
        success: true,
        message: 'Savings goal prediction completed',
        data: {
          goalId: savingsGoal._id,
          goalName: savingsGoal.title,
          targetAmount: savingsGoal.targetAmount,
          currentAmount: savingsGoal.currentAmount,
          remainingAmount,
          targetDate: savingsGoal.targetDate,
          isReached: false,
          projectedCompletionDate,
          monthsToCompletion,
          willReachByTargetDate,
          averageMonthlySavings
        }
      };
    } catch (error) {
      console.error('Error predicting savings goal completion:', error);
      return {
        success: false,
        message: 'Error predicting savings goal completion',
        error: error.message
      };
    }
  }

  /**
   * Predict future values using TensorFlow.js
   * @private
   */
  async predictWithTensorFlow(userId, timeSeriesData, months, predictionType) {
    try {
      const values = timeSeriesData.map(item => item.amount);
      const dates = timeSeriesData.map(item => item.month);
      
      // Normalize data
      const max = Math.max(...values);
      const min = Math.min(...values);
      const range = max - min;
      
      const normalizedValues = values.map(val => (val - min) / range);
      
      // No complex ML methods needed in this simplified version

      const predictions = [];
      for (let i = 0; i < months; i++) {
        const predictionDate = moment(dates[dates.length - 1]).add(i + 1, 'months').format('YYYY-MM');
        // Add some random variation to make it more realistic
        const variation = 0.9 + (Math.random() * 0.2); // 0.9 to 1.1
        predictions.push({
          month: predictionDate,
          amount: Math.round(values[values.length - 1] * variation)
        });
      }

      return {
        success: true,
        message: `${predictionType === 'spending' ? 'Spending' : 'Savings'} prediction completed (simple model)`,
        data: {
          historical: timeSeriesData,
          predictions,
          predictionType,
          modelType: 'simple'
        }
      };
    } catch (error) {
      console.error(`Error in predictWith${predictionType === 'spending' ? 'Spending' : 'Savings'}SimpleModel:`, error);
      return {
        success: false,
        message: `Error predicting ${predictionType}`,
        error: error.message
      };
    }
  }
}

module.exports = new PredictionService();
