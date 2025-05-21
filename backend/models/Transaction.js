const mongoose = require('mongoose');

// Define transaction types and categories to match the Flutter app
const transactionTypes = ['income', 'expense'];
const incomeCategories = ['salary', 'investment', 'gifts', 'business', 'rent', 'other_income'];
const expenseCategories = [
  'shopping', 'food', 'transport', 'entertainment', 'bills', 
  'health', 'education', 'travel', 'home', 'groceries', 'dining', 'healthcare', 'transportation',
  'miscellaneous', 'other_expense'
];
const allCategories = [...incomeCategories, ...expenseCategories];

// Define receipt item schema
const ReceiptItemSchema = new mongoose.Schema({
  name: {
    type: String,
    trim: true
  },
  quantity: {
    type: Number,
    default: 1
  },
  price: {
    type: Number,
    default: 0
  },
  total: {
    type: Number,
    default: 0
  }
}, { _id: false });

// Define receipt data schema
const ReceiptDataSchema = new mongoose.Schema({
  merchant: {
    type: String,
    trim: true
  },
  address: {
    type: String,
    trim: true
  },
  phone: {
    type: String,
    trim: true
  },
  items: [ReceiptItemSchema],
  subtotal: {
    type: Number
  },
  tax: {
    type: Number
  },
  total: {
    type: Number
  },
  date: {
    type: Date
  },
  time: {
    type: String,
    trim: true
  },
  receiptNumber: {
    type: String,
    trim: true
  }
}, { _id: false });

const TransactionSchema = new mongoose.Schema({
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
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot be more than 500 characters']
  },
  amount: {
    type: Number,
    required: [true, 'Please add an amount']
  },
  date: {
    type: Date,
    default: Date.now
  },
  category: {
    type: String,
    enum: allCategories,
    required: [true, 'Please select a category']
  },
  type: {
    type: String,
    enum: transactionTypes,
    required: [true, 'Please select a transaction type']
  },
  attachmentPath: {
    type: String
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'credit_card', 'debit_card', 'bank_transfer', 'mobile_payment', 'other'],
    default: 'cash'
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [1000, 'Notes cannot be more than 1000 characters']
  },
  receiptData: ReceiptDataSchema,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Middleware to validate category based on type
TransactionSchema.pre('save', function(next) {
  if (this.type === 'income' && !incomeCategories.includes(this.category)) {
    this.category = 'other_income';
  } else if (this.type === 'expense' && !expenseCategories.includes(this.category)) {
    this.category = 'other_expense';
  }
  next();
});

// Virtual for getting category metadata (to be handled in the frontend)
TransactionSchema.virtual('categoryMetadata').get(function() {
  return {
    name: this.category,
    displayName: this.category.charAt(0).toUpperCase() + this.category.slice(1).replace('_', ' ')
  };
});

module.exports = mongoose.model('Transaction', TransactionSchema);
