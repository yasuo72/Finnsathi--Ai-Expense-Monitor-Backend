const tf = require('@tensorflow/tfjs-node');
const brain = require('brain.js');
const Transaction = require('../../models/Transaction');
const SavingsGoal = require('../../models/SavingsGoal');
const moment = require('moment');
const path = require('path');
const fs = require('fs');

class PredictionService {
  constructor() {
    this.spendingModel = null;
    this.savingsModel = null;
    this.brainNetwork = null;
    this.modelPath = path.join(__dirname, '../models');
    this.initialized = false;
  }

  async initialize() {
    if (this.initialized) return;

    try {
      // Create models directory if it doesn't exist
      if (!fs.existsSync(this.modelPath)) {
        fs.mkdirSync(this.modelPath, { recursive: true });
      }

      // Initialize brain.js network for simple predictions
      this.brainNetwork = new brain.NeuralNetwork({
        hiddenLayers: [10, 8],
        activation: 'sigmoid'
      });

      // Check if TensorFlow models exist and load them
      const spendingModelPath = `file://${path.join(this.modelPath, 'spending-model')}`;
      const savingsModelPath = `file://${path.join(this.modelPath, 'savings-model')}`;

      try {
        if (fs.existsSync(path.join(this.modelPath, 'spending-model', 'model.json'))) {
          this.spendingModel = await tf.loadLayersModel(spendingModelPath);
          console.log('Spending prediction model loaded');
        }

        if (fs.existsSync(path.join(this.modelPath, 'savings-model', 'model.json'))) {
          this.savingsModel = await tf.loadLayersModel(savingsModelPath);
          console.log('Savings prediction model loaded');
        }
      } catch (modelError) {
        console.error('Error loading models:', modelError);
        // Models will be created when needed
      }

      this.initialized = true;
    } catch (error) {
      console.error('Error initializing prediction service:', error);
      throw error;
    }
  }

  /**
   * Predict spending for the next month based on historical data
   * @param {string} userId - User ID
   * @param {number} months - Number of months to predict (default: 1)
   * @param {string} category - Optional category to predict for
   * @returns {Promise<Object>} - Prediction results
   */
  async predictSpending(userId, months = 1, category = null) {
    await this.initialize();

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
      
      // If we have enough data, use TensorFlow for time series prediction
      if (timeSeriesData.length >= 6) {
        return await this.predictWithTensorFlow(userId, timeSeriesData, months, 'spending');
      } else {
        // Use brain.js for simpler prediction with less data
        return await this.predictWithBrainJS(userId, timeSeriesData, months, 'spending');
      }
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
    await this.initialize();

    try {
      // Get the savings goal
      const goal = await SavingsGoal.findOne({ _id: goalId, user: userId });
      
      if (!goal) {
        return {
          success: false,
          message: 'Savings goal not found',
          data: null
        };
      }
      
      // Calculate remaining amount
      const remainingAmount = goal.targetAmount - goal.currentAmount;
      
      if (remainingAmount <= 0) {
        return {
          success: true,
          message: 'Goal already reached',
          data: {
            goalId: goal._id,
            goalName: goal.name,
            isComplete: true,
            completionDate: new Date(),
            daysToCompletion: 0,
            monthsToCompletion: 0
          }
        };
      }
      
      // Get historical savings data
      const savingsTransactions = await Transaction.find({
        user: userId,
        savingsGoalId: goalId
      }).sort({ date: 1 });
      
      // If no transactions specifically for this goal, get general savings rate
      let savingsRate;
      
      if (savingsTransactions.length < 3) {
        // Calculate average monthly savings from income/expense difference
        const sixMonthsAgo = moment().subtract(6, 'months').toDate();
        
        const transactions = await Transaction.find({
          user: userId,
          date: { $gte: sixMonthsAgo }
        });
        
        // Group by month
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
        
        // Calculate monthly savings
        const monthlySavings = Object.values(monthlyData).map(month => {
          return month.income - month.expense;
        });
        
        // Calculate average monthly savings
        const totalSavings = monthlySavings.reduce((sum, val) => sum + val, 0);
        const months = Object.keys(monthlyData).length || 1;
        savingsRate = totalSavings / months;
        
        // If negative or zero, use 10% of average income as default
        if (savingsRate <= 0) {
          const totalIncome = Object.values(monthlyData).reduce((sum, month) => sum + month.income, 0);
          const avgIncome = totalIncome / months;
          savingsRate = avgIncome * 0.1; // Assume 10% of income
        }
      } else {
        // Calculate average monthly contribution from transactions
        const contributions = {};
        savingsTransactions.forEach(transaction => {
          const monthKey = moment(transaction.date).format('YYYY-MM');
          if (!contributions[monthKey]) {
            contributions[monthKey] = 0;
          }
          contributions[monthKey] += transaction.amount;
        });
        
        const totalContribution = Object.values(contributions).reduce((sum, val) => sum + val, 0);
        const months = Object.keys(contributions).length;
        savingsRate = totalContribution / months;
      }
      
      // Calculate months to completion
      const monthsToCompletion = remainingAmount / savingsRate;
      const daysToCompletion = monthsToCompletion * 30;
      
      // Calculate completion date
      const completionDate = moment().add(daysToCompletion, 'days').toDate();
      
      return {
        success: true,
        message: 'Savings goal completion predicted',
        data: {
          goalId: goal._id,
          goalName: goal.name,
          currentAmount: goal.currentAmount,
          targetAmount: goal.targetAmount,
          remainingAmount,
          monthlySavingsRate: savingsRate,
          isComplete: false,
          completionDate,
          daysToCompletion: Math.round(daysToCompletion),
          monthsToCompletion: Math.round(monthsToCompletion * 10) / 10
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
      
      // Prepare data for time series prediction
      const sequenceLength = 3; // Use 3 months to predict the next
      const xs = [];
      const ys = [];
      
      for (let i = 0; i < normalizedValues.length - sequenceLength; i++) {
        xs.push(normalizedValues.slice(i, i + sequenceLength));
        ys.push(normalizedValues[i + sequenceLength]);
      }
      
      // If we don't have enough sequences, use brain.js instead
      if (xs.length < 3) {
        return await this.predictWithBrainJS(userId, timeSeriesData, months, predictionType);
      }
      
      // Convert to tensors
      const xsTensor = tf.tensor2d(xs);
      const ysTensor = tf.tensor1d(ys);
      
      // Check if model exists, otherwise create one
      let model;
      if (predictionType === 'spending' && this.spendingModel) {
        model = this.spendingModel;
      } else if (predictionType === 'savings' && this.savingsModel) {
        model = this.savingsModel;
      } else {
        // Create a new model
        model = tf.sequential();
        
        model.add(tf.layers.lstm({
          units: 8,
          inputShape: [sequenceLength, 1],
          returnSequences: false
        }));
        
        model.add(tf.layers.dense({ units: 1 }));
        
        model.compile({
          optimizer: tf.train.adam(0.01),
          loss: 'meanSquaredError'
        });
        
        // Reshape input for LSTM [samples, time steps, features]
        const reshapedXs = xsTensor.reshape([xs.length, sequenceLength, 1]);
        
        // Train the model
        await model.fit(reshapedXs, ysTensor, {
          epochs: 100,
          batchSize: 4,
          shuffle: true,
          verbose: 0
        });
        
        // Save the model
        const modelSavePath = `file://${path.join(this.modelPath, predictionType === 'spending' ? 'spending-model' : 'savings-model')}`;
        await model.save(modelSavePath);
        
        // Update class property
        if (predictionType === 'spending') {
          this.spendingModel = model;
        } else {
          this.savingsModel = model;
        }
      }
      
      // Make predictions for future months
      const predictions = [];
      let lastSequence = normalizedValues.slice(-sequenceLength);
      
      for (let i = 0; i < months; i++) {
        // Reshape the input
        const predictTensor = tf.tensor2d([lastSequence]).reshape([1, sequenceLength, 1]);
        
        // Get prediction
        const predictResult = model.predict(predictTensor);
        const predictValue = predictResult.dataSync()[0];
        
        // Denormalize
        const denormalizedValue = predictValue * range + min;
        
        // Add to predictions
        const predictionDate = moment(dates[dates.length - 1]).add(i + 1, 'months').format('YYYY-MM');
        predictions.push({
          month: predictionDate,
          amount: Math.max(0, denormalizedValue) // Ensure non-negative
        });
        
        // Update sequence for next prediction
        lastSequence = [...lastSequence.slice(1), predictValue];
      }
      
      return {
        success: true,
        message: `${predictionType === 'spending' ? 'Spending' : 'Savings'} prediction completed`,
        data: {
          historical: timeSeriesData,
          predictions,
          predictionType
        }
      };
    } catch (error) {
      console.error(`Error in predictWith${predictionType === 'spending' ? 'Spending' : 'Savings'}TensorFlow:`, error);
      return {
        success: false,
        message: `Error predicting ${predictionType}`,
        error: error.message
      };
    }
  }

  /**
   * Predict future values using Brain.js (simpler model for less data)
   * @private
   */
  async predictWithBrainJS(userId, timeSeriesData, months, predictionType) {
    try {
      if (timeSeriesData.length < 2) {
        return {
          success: false,
          message: 'Not enough data for prediction',
          data: null
        };
      }
      
      // Normalize data for brain.js
      const values = timeSeriesData.map(item => item.amount);
      const dates = timeSeriesData.map(item => item.month);
      
      const max = Math.max(...values);
      const min = Math.min(...values);
      const range = max - min || 1; // Avoid division by zero
      
      const normalizedData = values.map(val => (val - min) / range);
      
      // Prepare training data
      const trainingData = [];
      for (let i = 0; i < normalizedData.length - 1; i++) {
        trainingData.push({
          input: { value: normalizedData[i] },
          output: { prediction: normalizedData[i + 1] }
        });
      }
      
      // Train the network
      this.brainNetwork.train(trainingData, {
        iterations: 1000,
        errorThresh: 0.005,
        log: false
      });
      
      // Make predictions
      const predictions = [];
      let lastValue = normalizedData[normalizedData.length - 1];
      
      for (let i = 0; i < months; i++) {
        // Get prediction
        const output = this.brainNetwork.run({ value: lastValue });
        const predictedNormalized = output.prediction;
        
        // Denormalize
        const predictedValue = predictedNormalized * range + min;
        
        // Add to predictions
        const predictionDate = moment(dates[dates.length - 1]).add(i + 1, 'months').format('YYYY-MM');
        predictions.push({
          month: predictionDate,
          amount: Math.max(0, predictedValue) // Ensure non-negative
        });
        
        // Update for next prediction
        lastValue = predictedNormalized;
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
      console.error(`Error in predictWith${predictionType === 'spending' ? 'Spending' : 'Savings'}BrainJS:`, error);
      return {
        success: false,
        message: `Error predicting ${predictionType}`,
        error: error.message
      };
    }
  }
}

module.exports = new PredictionService();
