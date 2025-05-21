const mongoose = require('mongoose');

const ContributionSchema = new mongoose.Schema({
  amount: {
    type: Number,
    required: true
  },
  date: {
    type: Date,
    default: Date.now
  },
  description: {
    type: String,
    trim: true
  }
});

const WithdrawalSchema = new mongoose.Schema({
  amount: {
    type: Number,
    required: true
  },
  date: {
    type: Date,
    default: Date.now
  },
  description: {
    type: String,
    trim: true
  }
});

const SavingsGoalSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  name: {
    type: String,
    required: [true, 'Please add a name'],
    trim: true,
    maxlength: [100, 'Name cannot be more than 100 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot be more than 500 characters']
  },
  category: {
    type: String,
    required: [true, 'Please add a category'],
    trim: true,
    default: 'General'
  },
  targetAmount: {
    type: Number,
    required: [true, 'Please add a target amount']
  },
  currentAmount: {
    type: Number,
    default: 0
  },
  createdDate: {
    type: Date,
    default: Date.now
  },
  targetDate: {
    type: Date
  },
  completedDate: {
    type: Date
  },
  contributions: [ContributionSchema],
  withdrawals: [WithdrawalSchema],
  color: {
    type: String,
    default: '#3551A2' // Default blue color
  },
  icon: {
    type: String,
    default: 'savings'
  }
});

// Virtual to calculate progress (0.0 to 1.0)
SavingsGoalSchema.virtual('progress').get(function() {
  return this.targetAmount > 0 ? this.currentAmount / this.targetAmount : 0;
});

// Virtual to calculate progress percentage (0 to 100)
SavingsGoalSchema.virtual('progressPercentage').get(function() {
  return this.targetAmount > 0 ? (this.currentAmount / this.targetAmount) * 100 : 0;
});

// Virtual to calculate remaining amount
SavingsGoalSchema.virtual('remainingAmount').get(function() {
  return Math.max(0, this.targetAmount - this.currentAmount);
});

// Virtual to determine if goal is completed
SavingsGoalSchema.virtual('isCompleted').get(function() {
  return this.currentAmount >= this.targetAmount;
});

// Virtual to calculate days remaining until target date
SavingsGoalSchema.virtual('daysRemaining').get(function() {
  if (!this.targetDate) return 0;
  const today = new Date();
  return Math.max(0, Math.ceil((this.targetDate - today) / (1000 * 60 * 60 * 24)));
});

// Virtual to calculate daily amount needed to reach goal on time
SavingsGoalSchema.virtual('dailyAmountNeeded').get(function() {
  if (!this.targetDate) return 0;
  const daysRemaining = this.daysRemaining;
  if (daysRemaining <= 0) return 0;
  return this.remainingAmount / daysRemaining;
});

// Virtual to calculate total contributions
SavingsGoalSchema.virtual('totalContributions').get(function() {
  return this.contributions ? this.contributions.reduce((sum, contribution) => sum + contribution.amount, 0) : 0;
});

// Virtual to calculate total withdrawals
SavingsGoalSchema.virtual('totalWithdrawals').get(function() {
  return this.withdrawals ? this.withdrawals.reduce((sum, withdrawal) => sum + withdrawal.amount, 0) : 0;
});

module.exports = mongoose.model('SavingsGoal', SavingsGoalSchema);
