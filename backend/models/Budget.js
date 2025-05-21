const mongoose = require('mongoose');

// Import categories from Transaction model to ensure consistency
const Transaction = require('./Transaction');

const BudgetSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: [true, 'Please add a title'],
    trim: true,
    maxlength: [100, 'Title cannot be more than 100 characters']
  },
  limit: {
    type: Number,
    required: [true, 'Please add a budget limit']
  },
  startDate: {
    type: Date,
    required: [true, 'Please add a start date']
  },
  endDate: {
    type: Date,
    required: [true, 'Please add an end date']
  },
  category: {
    type: String,
    required: [true, 'Please select a category']
  },
  spent: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Virtual to calculate remaining budget
BudgetSchema.virtual('remaining').get(function() {
  return this.limit - this.spent;
});

// Virtual to calculate percentage used
BudgetSchema.virtual('percentUsed').get(function() {
  return (this.spent / this.limit) * 100;
});

// Virtual to determine if budget is exceeded
BudgetSchema.virtual('isExceeded').get(function() {
  return this.spent > this.limit;
});

module.exports = mongoose.model('Budget', BudgetSchema);
