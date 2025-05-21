const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const NotificationService = require('../services/notification.service');

// @desc    Register user
// @route   POST /api/auth/signup
// @access  Public
exports.signup = async (req, res) => {
  try {
    const { name, email, password, dob, mobile } = req.body;

    // Check if user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'User already exists'
      });
    }

    // Create user
    const user = await User.create({
      name,
      email,
      password,
      dob,
      mobile
    });

    // Generate token
    const token = user.getSignedJwtToken();

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        dob: user.dob,
        mobile: user.mobile,
        profilePicture: user.profilePicture
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

// @desc    Login user
// @route   POST /api/auth/signin
// @access  Public
exports.signin = async (req, res) => {
  try {
    const { email, mobile, password } = req.body;

    // Validate email/mobile and password
    if ((!email && !mobile) || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email/mobile and password'
      });
    }

    // Check for user
    let user;
    if (email) {
      user = await User.findOne({ email }).select('+password');
    } else if (mobile) {
      user = await User.findOne({ mobile }).select('+password');
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if password matches
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate token
    const token = user.getSignedJwtToken();
    
    // Send login notification if enabled
    try {
      // Get device and location info from request headers or defaults
      const userAgent = req.headers['user-agent'] || 'Unknown device';
      const ipAddress = req.headers['x-forwarded-for'] || 
                       req.connection.remoteAddress || 
                       'Unknown location';
      
      // Send notification asynchronously (don't wait for it)
      NotificationService.sendSecurityNotification(
        user._id,
        'login',
        { device: userAgent, location: ipAddress }
      ).catch(err => console.error('Error sending login notification:', err));
    } catch (notificationError) {
      // Log but don't fail the login process
      console.error('Error sending login notification:', notificationError);
    }

    res.status(200).json({
      success: true,
      message: 'User logged in successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        dob: user.dob,
        mobile: user.mobile,
        profilePicture: user.profilePicture
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

// @desc    Verify OTP
// @route   POST /api/auth/verify
// @access  Public
exports.verifyOtp = async (req, res) => {
  try {
    const { email, mobile, otp } = req.body;

    // For demo purposes, consider any 4-digit OTP as valid
    if (otp && otp.length === 4 && /^\d+$/.test(otp)) {
      return res.status(200).json({
        success: true,
        message: 'OTP verified successfully',
        token: 'mock_verified_token_12345'
      });
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP. Please enter a 4-digit code.'
      });
    }
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Forgot password
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res) => {
  try {
    const { email, mobile } = req.body;

    if (!email && !mobile) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email or mobile'
      });
    }

    // Check if user exists
    let user;
    if (email) {
      user = await User.findOne({ email });
    } else if (mobile) {
      user = await User.findOne({ mobile });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // In a real application, send OTP via email or SMS
    // For demo, just return success
    res.status(200).json({
      success: true,
      message: 'OTP sent successfully'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Reset password
// @route   POST /api/auth/reset-password
// @access  Public
exports.resetPassword = async (req, res) => {
  try {
    const { email, mobile, otp, newPassword } = req.body;

    if ((!email && !mobile) || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields'
      });
    }

    // For demo purposes, consider any 4-digit OTP as valid
    if (otp.length !== 4 || !/^\d+$/.test(otp)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP. Please enter a 4-digit code.'
      });
    }

    // Find user
    let user;
    if (email) {
      user = await User.findOne({ email });
    } else if (mobile) {
      user = await User.findOne({ mobile });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Update password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();
    
    // Send password change notification
    try {
      // Send notification asynchronously (don't wait for it)
      NotificationService.sendSecurityNotification(
        user._id,
        'password_change'
      ).catch(err => console.error('Error sending password change notification:', err));
    } catch (notificationError) {
      // Log but don't fail the password reset process
      console.error('Error sending password change notification:', notificationError);
    }

    res.status(200).json({
      success: true,
      message: 'Password reset successfully'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get current user profile
// @route   GET /api/auth/me
// @access  Private
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        dob: user.dob,
        mobile: user.mobile,
        profilePicture: user.profilePicture,
        createdAt: user.createdAt
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
