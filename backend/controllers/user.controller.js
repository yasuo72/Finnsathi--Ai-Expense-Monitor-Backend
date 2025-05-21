const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Budget = require('../models/Budget');
const SavingsGoal = require('../models/SavingsGoal');
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

// @desc    Get user profile
// @route   GET /api/users/profile
// @access  Private
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Update last active timestamp
    user.lastActive = new Date();
    await user.save();
    
    res.status(200).json({
      success: true,
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        fullName: user.fullName,
        dob: user.dob,
        gender: user.gender,
        occupation: user.occupation,
        address: user.address,
        mobile: user.mobile,
        profilePicture: user.profilePicture,
        bio: user.bio,
        monthlyIncome: user.monthlyIncome,
        financialGoals: user.financialGoals,
        preferences: user.preferences,
        isVerified: user.isVerified,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('Error in getProfile:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
exports.updateProfile = async (req, res) => {
  try {
    const { 
      name, firstName, lastName, dob, gender, occupation, 
      address, bio, mobile, monthlyIncome, financialGoals,
      email, profilePicture
    } = req.body;
    
    // Find user
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Validate email format if provided
    if (email && email !== user.email) {
      const emailRegex = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid email address'
        });
      }
      
      // Check if email is already in use
      const existingUser = await User.findOne({ email, _id: { $ne: user._id } });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Email is already in use'
        });
      }
      
      user.email = email;
    }
    
    // Validate mobile format if provided
    if (mobile && mobile !== user.mobile) {
      const mobileRegex = /^[0-9]{10}$/;
      if (!mobileRegex.test(mobile)) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid 10-digit mobile number'
        });
      }
      
      // Check if mobile is already in use
      const existingUser = await User.findOne({ mobile, _id: { $ne: user._id } });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Mobile number is already in use'
        });
      }
      
      user.mobile = mobile;
    }
    
    // Update basic fields if provided
    if (name) user.name = name;
    if (firstName) user.firstName = firstName;
    if (lastName) user.lastName = lastName;
    if (dob) user.dob = new Date(dob);
    if (gender && ['male', 'female', 'other', 'prefer_not_to_say'].includes(gender)) {
      user.gender = gender;
    }
    if (occupation) user.occupation = occupation;
    if (bio) {
      if (bio.length > 500) {
        return res.status(400).json({
          success: false,
          message: 'Bio cannot be more than 500 characters'
        });
      }
      user.bio = bio;
    }
    if (monthlyIncome !== undefined) {
      // Ensure monthlyIncome is a positive number
      const income = Number(monthlyIncome);
      if (isNaN(income) || income < 0) {
        return res.status(400).json({
          success: false,
          message: 'Monthly income must be a positive number'
        });
      }
      user.monthlyIncome = income;
    }
    if (profilePicture) user.profilePicture = profilePicture;
    
    // Update address if provided
    if (address) {
      user.address = {
        ...user.address,
        ...address
      };
    }
    
    // Update financial goals if provided
    if (financialGoals && Array.isArray(financialGoals)) {
      // Validate each financial goal
      const validatedGoals = financialGoals.map(goal => {
        const { title, description, targetDate } = goal;
        return {
          title: title || 'Untitled Goal',
          description: description || '',
          targetDate: targetDate ? new Date(targetDate) : null
        };
      });
      user.financialGoals = validatedGoals;
    }
    
    // Update last active timestamp
    user.lastActive = new Date();
    
    await user.save();
    
    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        fullName: user.fullName,
        dob: user.dob,
        gender: user.gender,
        occupation: user.occupation,
        address: user.address,
        mobile: user.mobile,
        profilePicture: user.profilePicture,
        bio: user.bio,
        monthlyIncome: user.monthlyIncome,
        financialGoals: user.financialGoals,
        preferences: user.preferences,
        isVerified: user.isVerified,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('Error in updateProfile:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Change password
// @route   POST /api/users/change-password
// @access  Private
exports.changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    
    if (!oldPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide old and new password'
      });
    }
    
    // Find user with password
    const user = await User.findById(req.user.id).select('+password');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Check if old password matches
    const isMatch = await user.matchPassword(oldPassword);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }
    
    // Update password
    user.password = newPassword;
    await user.save();
    
    res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Upload profile picture
// @route   POST /api/users/profile-picture
// @access  Private
exports.uploadProfilePicture = async (req, res) => {
  try {
    // Check if files exist in the request
    if (!req.files || !req.files.profilePicture) {
      return res.status(400).json({
        success: false,
        message: 'Please upload a file'
      });
    }
    
    const file = req.files.profilePicture;
    
    // Check if image
    if (!file.mimetype.startsWith('image')) {
      return res.status(400).json({
        success: false,
        message: 'Please upload an image file'
      });
    }
    
    // Check file size (limit to 5MB)
    if (file.size > 5 * 1024 * 1024) {
      return res.status(400).json({
        success: false,
        message: 'Image size should be less than 5MB'
      });
    }
    
    // Make sure the uploads directory exists
    const uploadsDir = './public/uploads';
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }
    
    // Create custom filename
    const path = require('path');
    const fileName = `photo_${req.user.id}_${Date.now()}${path.parse(file.name).ext}`;
    const filePath = `${uploadsDir}/${fileName}`;
    
    // Move file to upload path using a promise-based approach
    await new Promise((resolve, reject) => {
      file.mv(filePath, (err) => {
        if (err) {
          console.error('File upload error:', err);
          reject(err);
        } else {
          resolve();
        }
      });
    });
    
    // Find user
    const user = await User.findById(req.user.id);
    
    if (!user) {
      // Remove the uploaded file if user not found
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
      
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Delete old profile picture if it's not the default
    if (user.profilePicture && user.profilePicture !== 'default-profile.jpg') {
      const oldFilePath = `./public${user.profilePicture}`;
      if (fs.existsSync(oldFilePath)) {
        fs.unlinkSync(oldFilePath);
      }
    }
    
    // Update user profile
    const profilePicture = `/uploads/${fileName}`;
    user.profilePicture = profilePicture;
    await user.save();
    
    res.status(200).json({
      success: true,
      message: 'Profile picture updated successfully',
      data: {
        profilePicture,
        id: user._id,
        name: user.name
      }
    });
  } catch (error) {
    console.error('Error in uploadProfilePicture:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Update user preferences
// @route   PUT /api/users/preferences
// @access  Private
exports.updatePreferences = async (req, res) => {
  try {
    const { currency, theme, notifications, budgetReminders, savingsReminders, language } = req.body;
    
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Initialize preferences if not already set
    if (!user.preferences) {
      user.preferences = {};
    }
    
    // Update preferences if provided
    if (currency) user.preferences.currency = currency;
    if (theme) user.preferences.theme = theme;
    if (notifications !== undefined) user.preferences.notifications = notifications;
    if (budgetReminders !== undefined) user.preferences.budgetReminders = budgetReminders;
    if (savingsReminders !== undefined) user.preferences.savingsReminders = savingsReminders;
    if (language) user.preferences.language = language;
    
    await user.save();
    
    res.status(200).json({
      success: true,
      message: 'Preferences updated successfully',
      data: user.preferences
    });
  } catch (error) {
    console.error('Error in updatePreferences:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Sync profile data with frontend
// @route   POST /api/users/sync-profile
// @access  Private
exports.syncProfileData = async (req, res) => {
  try {
    const userId = req.user.id;
    const { profileData, lastSyncTimestamp } = req.body;
    
    if (!profileData) {
      return res.status(400).json({
        success: false,
        message: 'Profile data is required'
      });
    }
    
    // Find user
    const user = await User.findById(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Check if server has newer data
    const serverLastModified = user.lastActive.getTime();
    const clientLastSync = lastSyncTimestamp ? new Date(lastSyncTimestamp).getTime() : 0;
    
    let responseData;
    let conflictResolution = 'none';
    
    if (serverLastModified > clientLastSync) {
      // Server has newer data, send it back for client to merge
      responseData = {
        id: user._id,
        name: user.name,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        fullName: user.fullName,
        dob: user.dob,
        gender: user.gender,
        occupation: user.occupation,
        address: user.address,
        mobile: user.mobile,
        profilePicture: user.profilePicture,
        bio: user.bio,
        monthlyIncome: user.monthlyIncome,
        financialGoals: user.financialGoals,
        preferences: user.preferences,
        isVerified: user.isVerified,
        lastActive: user.lastActive,
        createdAt: user.createdAt
      };
      conflictResolution = 'server_newer';
    } else {
      // Client has newer or same age data, update server
      // Update basic profile fields
      if (profileData.name) user.name = profileData.name;
      if (profileData.firstName) user.firstName = profileData.firstName;
      if (profileData.lastName) user.lastName = profileData.lastName;
      if (profileData.dob) user.dob = new Date(profileData.dob);
      if (profileData.gender && ['male', 'female', 'other', 'prefer_not_to_say'].includes(profileData.gender)) {
        user.gender = profileData.gender;
      }
      if (profileData.occupation) user.occupation = profileData.occupation;
      if (profileData.bio && profileData.bio.length <= 500) user.bio = profileData.bio;
      if (profileData.mobile) user.mobile = profileData.mobile;
      if (profileData.monthlyIncome !== undefined) {
        const income = Number(profileData.monthlyIncome);
        if (!isNaN(income) && income >= 0) {
          user.monthlyIncome = income;
        }
      }
      
      // Update address if provided
      if (profileData.address) {
        user.address = {
          ...user.address,
          ...profileData.address
        };
      }
      
      // Update preferences if provided
      if (profileData.preferences) {
        user.preferences = {
          ...user.preferences,
          ...profileData.preferences
        };
      }
      
      // Update financial goals if provided
      if (profileData.financialGoals && Array.isArray(profileData.financialGoals)) {
        user.financialGoals = profileData.financialGoals.map(goal => ({
          title: goal.title || 'Untitled Goal',
          description: goal.description || '',
          targetDate: goal.targetDate ? new Date(goal.targetDate) : null
        }));
      }
      
      // Update last active timestamp
      user.lastActive = new Date();
      
      await user.save();
      
      responseData = {
        id: user._id,
        name: user.name,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        fullName: user.fullName,
        dob: user.dob,
        gender: user.gender,
        occupation: user.occupation,
        address: user.address,
        mobile: user.mobile,
        profilePicture: user.profilePicture,
        bio: user.bio,
        monthlyIncome: user.monthlyIncome,
        financialGoals: user.financialGoals,
        preferences: user.preferences,
        isVerified: user.isVerified,
        lastActive: user.lastActive,
        createdAt: user.createdAt
      };
      conflictResolution = 'client_updated';
    }
    
    res.status(200).json({
      success: true,
      message: 'Profile sync completed',
      conflictResolution,
      data: responseData,
      syncTimestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error in syncProfileData:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get user financial summary
// @route   GET /api/users/financial-summary
// @access  Private
exports.getFinancialSummary = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get user data
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Get total transactions
    const transactions = await Transaction.find({ user: userId });
    const totalIncome = transactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const totalExpenses = transactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    
    // Get budgets
    const budgets = await Budget.find({ user: userId });
    const totalBudgeted = budgets.reduce((sum, budget) => sum + budget.limit, 0);
    const totalSpent = budgets.reduce((sum, budget) => sum + budget.spent, 0);
    
    // Get savings goals
    const savingsGoals = await SavingsGoal.find({ user: userId });
    const totalSavingsTarget = savingsGoals.reduce((sum, goal) => sum + goal.targetAmount, 0);
    const totalSaved = savingsGoals.reduce((sum, goal) => sum + goal.currentAmount, 0);
    
    // Calculate net worth and savings rate
    const netWorth = totalIncome - totalExpenses;
    const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;
    
    res.status(200).json({
      success: true,
      data: {
        totalIncome,
        totalExpenses,
        netWorth,
        savingsRate,
        monthlyIncome: user.monthlyIncome,
        budgetSummary: {
          totalBudgeted,
          totalSpent,
          budgetCount: budgets.length
        },
        savingsSummary: {
          totalSavingsTarget,
          totalSaved,
          savingsGoalCount: savingsGoals.length
        },
        transactionSummary: {
          totalCount: transactions.length,
          incomeCount: transactions.filter(t => t.type === 'income').length,
          expenseCount: transactions.filter(t => t.type === 'expense').length
        }
      }
    });
  } catch (error) {
    console.error('Error in getFinancialSummary:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};
