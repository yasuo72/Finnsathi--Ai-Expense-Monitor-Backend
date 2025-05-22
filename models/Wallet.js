const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const CardSchema = new mongoose.Schema({
  number: {
    type: String,
    required: [true, 'Please add a card number'],
    trim: true
  },
  name: {
    type: String,
    required: [true, 'Please add a cardholder name'],
    trim: true
  },
  expiry: {
    type: String,
    required: [true, 'Please add an expiry date'],
    trim: true
  },
  cvv: {
    type: String,
    required: [true, 'Please add a CVV'],
    select: false
  },
  type: {
    type: String,
    enum: ['debit', 'credit'],
    default: 'debit'
  },
  balance: {
    type: Number,
    required: [true, 'Please add a balance']
  },
  colorValue: {
    type: Number,
    default: 0xFF3551A2 // Default blue color
  },
  isDefault: {
    type: Boolean,
    default: false
  }
});

const WalletSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  cashAmount: {
    type: Number,
    default: 0
  },
  cards: [CardSchema],
  walletPassword: {
    type: String,
    required: [true, 'Please add a wallet password'],
    minlength: 4,
    select: false,
    default: '1234' // Default password
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Encrypt wallet password using bcrypt
WalletSchema.pre('save', async function(next) {
  if (!this.isModified('walletPassword')) {
    next();
  }

  const salt = await bcrypt.genSalt(10);
  this.walletPassword = await bcrypt.hash(this.walletPassword, salt);
});

// Match wallet password
WalletSchema.methods.matchWalletPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.walletPassword);
};

// Virtual to calculate total cards amount
WalletSchema.virtual('cardsTotalAmount').get(function() {
  return this.cards.reduce((total, card) => total + card.balance, 0);
});

// Virtual to calculate total balance
WalletSchema.virtual('totalBalance').get(function() {
  return this.cashAmount + this.cardsTotalAmount;
});

module.exports = mongoose.model('Wallet', WalletSchema);
