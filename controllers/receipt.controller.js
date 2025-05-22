const Transaction = require('../models/Transaction');
const https = require('https');
const fs = require('fs');
const path = require('path');

// @desc    Scan receipt image and extract data - Direct integration approach
// @route   POST /api/receipts/direct-integration
// @access  Private
exports.directIntegration = async (req, res) => {
  try {
    // This endpoint expects the data to already be processed by the OCR service
    // The Flutter app will call the OCR service directly and then send the results here
    const { extractedText, extractedData } = req.body;
    const userId = req.user.id;
    
    if (!extractedText || !extractedData) {
      return res.status(400).json({
        success: false,
        message: 'Please provide extracted text and data from the OCR service'
      });
    }
    
    // Create transaction from extracted data
    const transaction = new Transaction({
      user: userId,
      type: 'expense',
      amount: extractedData.total || 0,
      date: extractedData.date ? new Date(extractedData.date) : new Date(),
      category: determineCategory(extractedData),
      description: extractedData.merchant || 'Receipt Scan',
      paymentMethod: 'cash', // Default payment method
      notes: `Receipt scanned from ${extractedData.merchant || 'unknown merchant'}`,
      receiptData: {
        merchant: extractedData.merchant,
        address: extractedData.address,
        phone: extractedData.phone,
        items: extractedData.items,
        subtotal: extractedData.subtotal,
        tax: extractedData.tax,
        total: extractedData.total,
        date: extractedData.date,
        time: extractedData.time,
        receiptNumber: extractedData.receipt_number
      }
    });

    // Save transaction
    await transaction.save();
    
    res.status(200).json({
      success: true,
      message: 'Receipt processed successfully',
      data: {
        transaction,
        extractedText,
        extractedData
      }
    });
  } catch (error) {
    console.error('Error in directIntegration:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get receipt service status
// @route   GET /api/receipts/status
// @access  Private
exports.getServiceStatus = async (req, res) => {
  try {
    // Check OCR service health directly
    const OCR_SERVICE_URL = process.env.OCR_SERVICE_URL || 'https://ocr-for-receipt-production.up.railway.app/api';
    
    // Create a promise-based request
    const checkServiceHealth = () => {
      return new Promise((resolve, reject) => {
        https.get(`${OCR_SERVICE_URL}/health`, (response) => {
          const { statusCode } = response;
          
          if (statusCode !== 200) {
            reject(new Error(`Request Failed. Status Code: ${statusCode}`));
            response.resume(); // Consume response data to free up memory
            return;
          }
          
          response.setEncoding('utf8');
          let rawData = '';
          
          response.on('data', (chunk) => { rawData += chunk; });
          
          response.on('end', () => {
            try {
              const parsedData = JSON.parse(rawData);
              resolve(parsedData);
            } catch (e) {
              reject(new Error(`Error parsing JSON: ${e.message}`));
            }
          });
        }).on('error', (e) => {
          reject(new Error(`Error connecting to OCR service: ${e.message}`));
        });
      });
    };
    
    // Check service health
    const healthData = await checkServiceHealth();
    const isAvailable = healthData && healthData.status === 'ok';
    
    res.status(200).json({
      success: true,
      data: {
        available: isAvailable,
        serviceUrl: OCR_SERVICE_URL,
        serviceTimestamp: healthData.timestamp
      }
    });
  } catch (error) {
    console.error('Error in getServiceStatus:', error);
    res.status(500).json({
      success: false,
      message: 'OCR service is unavailable',
      error: error.message
    });
  }
};

// @desc    Get transactions with receipt data
// @route   GET /api/receipts
// @access  Private
exports.getReceiptTransactions = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Find transactions with receipt data
    const transactions = await Transaction.find({
      user: userId,
      'receiptData.merchant': { $exists: true }
    }).sort({ date: -1 });
    
    res.status(200).json({
      success: true,
      count: transactions.length,
      data: transactions
    });
  } catch (error) {
    console.error('Error in getReceiptTransactions:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get transaction with receipt data by ID
// @route   GET /api/receipts/:id
// @access  Private
exports.getReceiptTransaction = async (req, res) => {
  try {
    const userId = req.user.id;
    const transactionId = req.params.id;
    
    // Find transaction
    const transaction = await Transaction.findOne({
      _id: transactionId,
      user: userId,
      'receiptData.merchant': { $exists: true }
    });
    
    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: 'Receipt transaction not found'
      });
    }
    
    res.status(200).json({
      success: true,
      data: transaction
    });
  } catch (error) {
    console.error('Error in getReceiptTransaction:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Update transaction from receipt data
// @route   PUT /api/receipts/:id
// @access  Private
exports.updateReceiptTransaction = async (req, res) => {
  try {
    const userId = req.user.id;
    const transactionId = req.params.id;
    const { category, description, amount, date, paymentMethod, notes } = req.body;
    
    // Find transaction
    const transaction = await Transaction.findOne({
      _id: transactionId,
      user: userId
    });
    
    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }
    
    // Update transaction fields
    if (category) transaction.category = category;
    if (description) transaction.description = description;
    if (amount) transaction.amount = amount;
    if (date) transaction.date = new Date(date);
    if (paymentMethod) transaction.paymentMethod = paymentMethod;
    if (notes) transaction.notes = notes;
    
    // Save transaction
    await transaction.save();
    
    res.status(200).json({
      success: true,
      message: 'Transaction updated successfully',
      data: transaction
    });
  } catch (error) {
    console.error('Error in updateReceiptTransaction:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

/**
 * Determine transaction category based on receipt data
 * @private
 * @param {Object} receiptData - Receipt data
 * @returns {string} - Category name
 */
function determineCategory(receiptData) {
  // Simple category determination based on merchant name or items
  const merchant = (receiptData.merchant || '').toLowerCase();
  const items = receiptData.items || [];
  
  // Check merchant name for common categories
  if (merchant.includes('restaurant') || merchant.includes('cafe') || merchant.includes('bar')) {
    return 'food';
  } else if (merchant.includes('market') || merchant.includes('grocery') || merchant.includes('food')) {
    return 'groceries';
  } else if (merchant.includes('gas') || merchant.includes('petrol') || merchant.includes('fuel')) {
    return 'transport';
  } else if (merchant.includes('pharmacy') || merchant.includes('drug') || merchant.includes('health')) {
    return 'health';
  } else if (merchant.includes('clothing') || merchant.includes('apparel') || merchant.includes('fashion')) {
    return 'shopping';
  }
  
  // Check items for common categories
  const itemNames = items.map(item => (item.name || '').toLowerCase());
  const itemString = itemNames.join(' ');
  
  if (itemString.includes('food') || itemString.includes('grocery')) {
    return 'groceries';
  } else if (itemString.includes('medicine') || itemString.includes('drug')) {
    return 'health';
  } else if (itemString.includes('clothing') || itemString.includes('shirt') || itemString.includes('pants')) {
    return 'shopping';
  }
  
  // Default category
  return 'other_expense';
}
