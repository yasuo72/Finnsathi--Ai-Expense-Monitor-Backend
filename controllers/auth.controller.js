const User = require('../models/User');
const Otp = require('../models/Otp');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const NotificationService = require('../services/notification.service');
const emailService = require('../services/email.service');
const smsService = require('../services/sms.service');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// @desc    Register user
// @route   POST /api/auth/signup
// @access  Public
exports.signup = async (req, res) => {
  try {
    const { name, email, password, dob, mobile } = req.body;

    // Check if user already exists by email or mobile
    const userExistsByEmail = await User.findOne({ email });
    if (userExistsByEmail) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }
    
    // Check for duplicate mobile number if provided
    if (mobile) {
      const userExistsByMobile = await User.findOne({ mobile });
      if (userExistsByMobile) {
        return res.status(400).json({
          success: false,
          message: 'User with this mobile number already exists'
        });
      }
    }

    // Initialize user data
    const userData = {
      name,
      email,
      password,
      dob,
      mobile
    };

    // Handle profile image if provided
    let profilePicturePath = null;
    console.log('Request files:', req.files ? Object.keys(req.files) : 'none');
    console.log('Request body:', req.body);
    
    if (req.files && (req.files.profileImage || req.files.profilePicture)) {
      // Support both parameter names for backward compatibility
      const file = req.files.profilePicture || req.files.profileImage;
      
      try {
        console.log('Profile image received:', file.name, file.mimetype, file.size);
        
        // Check if image
        if (!file.mimetype.startsWith('image')) {
          console.log('Invalid file mimetype:', file.mimetype);
          return res.status(400).json({
            success: false,
            message: 'Please upload an image file for profile picture'
          });
        }
        
        // Make sure the file is not empty
        if (file.size === 0) {
          console.log('Empty file received');
          return res.status(400).json({
            success: false,
            message: 'The uploaded profile picture file is empty'
          });
        }
        
        // Check file size (limit to 5MB)
        if (file.size > 5 * 1024 * 1024) {
          return res.status(400).json({
            success: false,
            message: 'Profile image size should be less than 5MB'
          });
        }
      } catch (error) {
        console.error('Error processing profile image:', error);
        return res.status(400).json({
          success: false,
          message: 'Error processing profile image: ' + error.message
        });
      }
      
      // Determine storage method based on configuration
      const useFileSystem = process.env.PROFILE_STORAGE !== 'database';
      
      if (useFileSystem) {
        // FILESYSTEM STORAGE METHOD
        try {
          // Make sure the uploads directory exists
          const publicDir = path.join(__dirname, '../public');
          const uploadsDir = path.join(publicDir, 'uploads');
          
          console.log('Creating upload directories if needed:', publicDir, uploadsDir);
          
          if (!fs.existsSync(publicDir)) {
            console.log('Creating public directory');
            fs.mkdirSync(publicDir, { recursive: true });
          }
          
          if (!fs.existsSync(uploadsDir)) {
            console.log('Creating uploads directory');
            fs.mkdirSync(uploadsDir, { recursive: true });
          }
          
          // Check if directory is writable
          try {
            fs.accessSync(uploadsDir, fs.constants.W_OK);
            console.log('Uploads directory is writable');
          } catch (err) {
            console.error('Uploads directory is not writable:', err);
            throw new Error('Uploads directory is not writable');
          }
          
          // Create custom filename
          const fileName = `photo_${Date.now()}${path.parse(file.name).ext}`;
          const filePath = path.join(uploadsDir, fileName);
          
          // Move file to upload path
          await new Promise((resolve, reject) => {
            file.mv(filePath, (err) => {
              if (err) {
                console.error('File upload error during signup:', err);
                reject(err);
              } else {
                resolve();
              }
            });
          });
          
          // Set profile picture path
          profilePicturePath = `/uploads/${fileName}`;
          userData.profilePicture = profilePicturePath;
          
          // Add metadata
          userData.profilePictureData = {
            url: profilePicturePath,
            uploadDate: new Date(),
            size: file.size,
            contentType: file.mimetype
          };
        } catch (err) {
          console.error('Error in file system storage:', err);
          return res.status(500).json({
            success: false,
            message: 'Error saving profile picture: ' + err.message
          });
        }
      } else {
        // DATABASE STORAGE METHOD
        // Convert file data to base64 for storage in database
        const base64Data = file.data.toString('base64');
        const dataUrl = `data:${file.mimetype};base64,${base64Data}`;
        
        // Set profile picture data URL
        profilePicturePath = dataUrl;
        userData.profilePicture = dataUrl;
        
        // Add metadata
        userData.profilePictureData = {
          url: null, // No URL for database storage
          uploadDate: new Date(),
          size: file.size,
          contentType: file.mimetype
        };
        
        console.log(`Profile picture for new user stored in database (${Math.round(file.size/1024)}KB)`);
      }
    }

    // Create user
    const user = await User.create(userData);

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

    // Delete any existing unverified OTPs for this user
    await Otp.deleteMany({
      user: user._id,
      type: 'password_reset',
      verified: false
    });

    // Generate 4-digit OTP
    const otp = crypto.randomInt(1000, 9999).toString();

    // Save OTP to database
    const otpDoc = await Otp.create({
      user: user._id,
      email: email || null,
      mobile: mobile || null,
      otp: otp,
      type: 'password_reset',
      expiresAt: new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
    });

    console.log(`📧 Generated OTP for ${email || mobile}: ${otp}`);

    // Send OTP via email or SMS
    try {
      if (email) {
        await emailService.sendOtpEmail(email, otp, user.name);
        console.log('✅ OTP email sent successfully');
      } else if (mobile) {
        await smsService.sendOtpSms(mobile, otp);
        console.log('✅ OTP SMS sent successfully');
      }

      res.status(200).json({
        success: true,
        message: email 
          ? 'OTP sent to your email. Please check your inbox.' 
          : 'OTP sent to your mobile number.',
        expiresIn: 300 // 5 minutes in seconds
      });
    } catch (sendError) {
      console.error('❌ Error sending OTP:', sendError);
      // Delete the OTP if sending failed
      await Otp.deleteOne({ _id: otpDoc._id });
      
      return res.status(500).json({
        success: false,
        message: 'Failed to send OTP. Please try again.'
      });
    }
  } catch (error) {
    console.error('❌ Forgot password error:', error);
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

    // Validate OTP format
    if (otp.length !== 4 || !/^\d+$/.test(otp)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP format. Please enter a 4-digit code.'
      });
    }

    // Validate password strength
    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long'
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

    // Find the OTP in database
    const otpDoc = await Otp.findOne({
      user: user._id,
      type: 'password_reset',
      verified: false
    }).sort({ createdAt: -1 }); // Get the most recent OTP

    if (!otpDoc) {
      return res.status(400).json({
        success: false,
        message: 'No OTP found. Please request a new one.'
      });
    }

    // Check if OTP is expired
    if (otpDoc.isExpired()) {
      await Otp.deleteOne({ _id: otpDoc._id });
      return res.status(400).json({
        success: false,
        message: 'OTP has expired. Please request a new one.'
      });
    }

    // Check if max attempts reached
    if (otpDoc.maxAttemptsReached()) {
      await Otp.deleteOne({ _id: otpDoc._id });
      return res.status(400).json({
        success: false,
        message: 'Maximum OTP attempts reached. Please request a new one.'
      });
    }

    // Verify OTP
    if (otpDoc.otp !== otp) {
      // Increment attempts
      await otpDoc.incrementAttempts();
      const remainingAttempts = 3 - otpDoc.attempts;
      
      return res.status(400).json({
        success: false,
        message: `Invalid OTP. ${remainingAttempts} attempt(s) remaining.`
      });
    }

    // OTP is valid - mark as verified
    otpDoc.verified = true;
    await otpDoc.save();

    // Update password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    // Delete all OTPs for this user after successful reset
    await Otp.deleteMany({ user: user._id, type: 'password_reset' });

    console.log(`✅ Password reset successful for user: ${user.email || user.mobile}`);

    // Send confirmation notifications
    try {
      if (email) {
        await emailService.sendPasswordChangedEmail(email, user.name);
      }
      if (mobile && smsService.isAvailable()) {
        await smsService.sendPasswordChangedSms(mobile);
      }
      
      // Send in-app notification
      NotificationService.sendSecurityNotification(
        user._id,
        'password_change'
      ).catch(err => console.error('Error sending security notification:', err));
    } catch (notificationError) {
      // Log but don't fail the password reset process
      console.error('Error sending notifications:', notificationError);
    }

    res.status(200).json({
      success: true,
      message: 'Password reset successfully. You can now log in with your new password.'
    });
  } catch (error) {
    console.error('❌ Reset password error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Authenticate with Google
// @route   POST /api/auth/google
// @access  Public
exports.googleAuth = async (req, res) => {
  try {
    console.log('Google auth request received:', JSON.stringify(req.body, null, 2));
    const { idToken, accessToken, email, name, photoUrl } = req.body;

    // Check if we have either idToken or accessToken, plus required user info
    if ((!idToken && !accessToken) || !email || !name) {
      console.log('Missing required Google auth fields:', { 
        hasIdToken: !!idToken, 
        hasAccessToken: !!accessToken,
        hasEmail: !!email, 
        hasName: !!name 
      });
      return res.status(400).json({
        success: false,
        message: 'Please provide either idToken or accessToken, plus email and name'
      });
    }
    
    // Log token info (first 10 chars only for security)
    console.log('Google auth tokens received:', { 
      idToken: idToken.substring(0, 10) + '...', 
      accessToken: accessToken ? (accessToken.substring(0, 10) + '...') : 'not provided' 
    });

    // Check if user exists
    let user = await User.findOne({ email });

    if (!user) {
      // Create new user if not exists
      user = await User.create({
        name,
        email,
        // Generate a random secure password for Google users
        password: Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8),
        profilePicture: photoUrl || null,
        authProvider: 'google',
        googleId: email // Using email as googleId for simplicity
      });

      console.log(`New user created via Google Sign-In: ${email}`);
    } else {
      // Update existing user's Google information
      user.name = name;
      user.profilePicture = photoUrl || user.profilePicture;
      user.authProvider = 'google';
      user.googleId = email; // Using email as googleId for simplicity
      await user.save();

      console.log(`Existing user authenticated via Google: ${email}`);
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
        { device: userAgent, location: ipAddress, provider: 'Google' }
      ).catch(err => console.error('Error sending Google login notification:', err));
    } catch (notificationError) {
      // Log but don't fail the login process
      console.error('Error sending Google login notification:', notificationError);
    }

    // Create response with all necessary data
    const response = {
      success: true,
      message: 'Google authentication successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        dob: user.dob,
        mobile: user.mobile,
        profilePicture: user.profilePicture
      }
    };
    
    console.log('Google auth successful for:', email);
    res.status(200).json(response);
  } catch (error) {
    console.error('Google authentication error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during Google authentication'
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
