const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const bcrypt = require('bcryptjs');

// @desc    Get user wallet
// @route   GET /api/wallet
// @access  Private
exports.getWallet = async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ user: req.user.id });
    
    // If wallet doesn't exist, create one with default values
    if (!wallet) {
      wallet = await Wallet.create({
        user: req.user.id,
        cashAmount: 0,
        cards: [],
        walletPassword: '1234' // Default password
      });
    }
    
    // Get recent transactions for the wallet view
    const recentTransactions = await Transaction.find({ user: req.user.id })
      .sort({ date: -1 })
      .limit(10);
    
    res.status(200).json({
      success: true,
      data: {
        cashAmount: wallet.cashAmount,
        cards: wallet.cards,
        cardsTotalAmount: wallet.cardsTotalAmount,
        totalBalance: wallet.totalBalance,
        recentTransactions
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Update cash amount
// @route   PUT /api/wallet/cash
// @access  Private
exports.updateCashAmount = async (req, res) => {
  try {
    const { amount, updateReason } = req.body;
    
    if (amount === undefined || isNaN(amount)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid amount'
      });
    }
    
    let wallet = await Wallet.findOne({ user: req.user.id });
    
    // If wallet doesn't exist, create one
    if (!wallet) {
      wallet = await Wallet.create({
        user: req.user.id,
        cashAmount: amount,
        cards: []
      });
    } else {
      // Calculate the difference to potentially create a transaction
      const difference = amount - wallet.cashAmount;
      
      // Update the wallet cash amount
      wallet.cashAmount = amount;
      await wallet.save();
      
      // If there's a significant change and updateReason is provided, create a transaction record
      if (Math.abs(difference) > 0 && updateReason) {
        await Transaction.create({
          user: req.user.id,
          amount: Math.abs(difference),
          type: difference > 0 ? 'income' : 'expense',
          category: updateReason || (difference > 0 ? 'Cash Deposit' : 'Cash Withdrawal'),
          description: `Manual ${difference > 0 ? 'addition to' : 'reduction from'} cash balance`,
          date: new Date(),
          paymentMethod: 'cash'
        });
      }
    }
    
    res.status(200).json({
      success: true,
      data: {
        cashAmount: wallet.cashAmount,
        cardsTotalAmount: wallet.cardsTotalAmount,
        totalBalance: wallet.totalBalance
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Add cash amount
// @route   POST /api/wallet/cash/add
// @access  Private
exports.addCashAmount = async (req, res) => {
  try {
    const { amount, category, description } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid amount'
      });
    }
    
    let wallet = await Wallet.findOne({ user: req.user.id });
    
    // If wallet doesn't exist, create one
    if (!wallet) {
      wallet = await Wallet.create({
        user: req.user.id,
        cashAmount: amount,
        cards: []
      });
    } else {
      wallet.cashAmount += amount;
      await wallet.save();
    }
    
    // Create a corresponding income transaction
    await Transaction.create({
      user: req.user.id,
      amount,
      type: 'income',
      category: category || 'Cash Deposit',
      description: description || 'Added cash to wallet',
      date: new Date(),
      paymentMethod: 'cash'
    });
    
    res.status(200).json({
      success: true,
      data: {
        cashAmount: wallet.cashAmount,
        cardsTotalAmount: wallet.cardsTotalAmount,
        totalBalance: wallet.totalBalance
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Add a card
// @route   POST /api/wallet/cards
// @access  Private
exports.addCard = async (req, res) => {
  try {
    const { number, name, expiry, cvv, type, balance, colorValue, description } = req.body;
    
    if (!number || !name || !expiry || !cvv || !balance) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required card details'
      });
    }
    
    let wallet = await Wallet.findOne({ user: req.user.id });
    
    // If wallet doesn't exist, create one
    if (!wallet) {
      wallet = await Wallet.create({
        user: req.user.id,
        cashAmount: 0,
        cards: [{
          number,
          name,
          expiry,
          cvv,
          type: type || 'debit',
          balance,
          colorValue: colorValue || 0xFF3551A2
        }]
      });
      
      // Create a transaction record for adding a new card with balance
      await Transaction.create({
        user: req.user.id,
        amount: balance,
        type: 'income',
        category: 'Card Addition',
        description: description || `Added new ${type || 'debit'} card: ${name}`,
        date: new Date(),
        paymentMethod: 'card'
      });
    } else {
      wallet.cards.push({
        number,
        name,
        expiry,
        cvv,
        type: type || 'debit',
        balance,
        colorValue: colorValue || 0xFF3551A2
      });
      
      await wallet.save();
      
      // Create a transaction record for adding a new card with balance
      await Transaction.create({
        user: req.user.id,
        amount: balance,
        type: 'income',
        category: 'Card Addition',
        description: description || `Added new ${type || 'debit'} card: ${name}`,
        date: new Date(),
        paymentMethod: 'card'
      });
    }
    
    res.status(201).json({
      success: true,
      data: {
        cards: wallet.cards,
        cardsTotalAmount: wallet.cardsTotalAmount,
        totalBalance: wallet.totalBalance
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Remove a card
// @route   DELETE /api/wallet/cards/:cardId
// @access  Private
exports.removeCard = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ user: req.user.id });
    
    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }
    
    // Check if card exists
    const card = wallet.cards.id(req.params.cardId);
    if (!card) {
      return res.status(404).json({
        success: false,
        message: 'Card not found'
      });
    }
    
    // Get card details before removing
    const cardDetails = {
      name: card.name,
      balance: card.balance,
      type: card.type
    };
    
    // Remove card
    card.remove();
    await wallet.save();
    
    // Create a transaction record for removing a card
    if (cardDetails.balance > 0) {
      await Transaction.create({
        user: req.user.id,
        amount: cardDetails.balance,
        type: 'expense',
        category: 'Card Removal',
        description: `Removed ${cardDetails.type} card: ${cardDetails.name}`,
        date: new Date(),
        paymentMethod: 'card'
      });
    }
    
    res.status(200).json({
      success: true,
      data: {
        cards: wallet.cards,
        cardsTotalAmount: wallet.cardsTotalAmount,
        totalBalance: wallet.totalBalance
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Verify wallet password
// @route   POST /api/wallet/verify-password
// @access  Private
exports.verifyPassword = async (req, res) => {
  try {
    const { password } = req.body;
    
    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a password'
      });
    }
    
    const wallet = await Wallet.findOne({ user: req.user.id }).select('+walletPassword');
    
    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }
    
    // Check if password matches
    const isMatch = await wallet.matchWalletPassword(password);
    
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid password'
      });
    }
    
    res.status(200).json({
      success: true,
      message: 'Password verified successfully'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Update wallet password
// @route   PUT /api/wallet/password
// @access  Private
exports.updatePassword = async (req, res) => {
  try {
    const { newPassword, currentPassword } = req.body;
    
    if (!newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a new password'
      });
    }
    
    let wallet = await Wallet.findOne({ user: req.user.id }).select('+walletPassword');
    
    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }
    
    // If current password is provided, verify it first
    if (currentPassword) {
      const isMatch = await wallet.matchWalletPassword(currentPassword);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Current password is incorrect'
        });
      }
    }
    
    wallet.walletPassword = newPassword;
    await wallet.save();
    
    res.status(200).json({
      success: true,
      message: 'Wallet password updated successfully'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Update card balance
// @route   PUT /api/wallet/cards/:cardId/balance
// @access  Private
exports.updateCardBalance = async (req, res) => {
  try {
    const { balance, updateReason } = req.body;
    
    if (balance === undefined || isNaN(balance) || balance < 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid balance amount'
      });
    }
    
    const wallet = await Wallet.findOne({ user: req.user.id });
    
    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }
    
    // Find the card
    const card = wallet.cards.id(req.params.cardId);
    if (!card) {
      return res.status(404).json({
        success: false,
        message: 'Card not found'
      });
    }
    
    // Calculate the difference to potentially create a transaction
    const difference = balance - card.balance;
    
    // Update card balance
    card.balance = balance;
    await wallet.save();
    
    // If there's a significant change, create a transaction record
    if (Math.abs(difference) > 0) {
      await Transaction.create({
        user: req.user.id,
        amount: Math.abs(difference),
        type: difference > 0 ? 'income' : 'expense',
        category: updateReason || (difference > 0 ? 'Card Deposit' : 'Card Withdrawal'),
        description: `Manual ${difference > 0 ? 'addition to' : 'reduction from'} card balance (${card.name})`,
        date: new Date(),
        paymentMethod: 'card'
      });
    }
    
    res.status(200).json({
      success: true,
      data: {
        card,
        cardsTotalAmount: wallet.cardsTotalAmount,
        totalBalance: wallet.totalBalance
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get wallet balance summary
// @route   GET /api/wallet/balance
// @access  Private
exports.getWalletBalance = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ user: req.user.id });
    
    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }
    
    // Calculate total income and expenses from transactions
    const transactions = await Transaction.find({ user: req.user.id });
    
    const totalIncome = transactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
      
    const totalExpenses = transactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    
    // Get calculated balance from wallet
    const walletBalance = wallet.totalBalance;
    
    // Calculate theoretical balance from transactions
    const transactionBalance = totalIncome - totalExpenses;
    
    res.status(200).json({
      success: true,
      data: {
        cashAmount: wallet.cashAmount,
        cardsTotalAmount: wallet.cardsTotalAmount,
        walletBalance,
        totalIncome,
        totalExpenses,
        transactionBalance
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Sync wallet balance with transactions
// @route   POST /api/wallet/sync
// @access  Private
exports.syncWalletWithTransactions = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ user: req.user.id });
    
    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }
    
    // Calculate total from transactions
    const transactions = await Transaction.find({ user: req.user.id });
    
    const totalIncome = transactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
      
    const totalExpenses = transactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const transactionBalance = totalIncome - totalExpenses;
    
    // Update wallet cash amount to match transaction balance
    // We'll put all the balance in cash for simplicity
    wallet.cashAmount = Math.max(0, transactionBalance);
    
    // Clear any cards if requested
    if (req.body.resetCards) {
      wallet.cards = [];
    }
    
    await wallet.save();
    
    res.status(200).json({
      success: true,
      data: {
        cashAmount: wallet.cashAmount,
        cardsTotalAmount: wallet.cardsTotalAmount,
        totalBalance: wallet.totalBalance,
        transactionBalance
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};
