const jwt = require('jsonwebtoken');
const ShopOwner = require('../models/ShopOwner');

// Register shop owner
exports.register = async (req, res) => {
  try {
    const { name, email, phone, password, businessName, businessType } = req.body;

    // Validate input
    if (!name || !email || !phone || !password) {
      return res.status(400).json({ message: 'Please provide all required fields' });
    }

    // Check if owner already exists
    const existingOwner = await ShopOwner.findOne({ email });
    if (existingOwner) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    // Create new owner
    const owner = new ShopOwner({
      name,
      email,
      phone,
      password,
      businessName: businessName || '',
      businessType: businessType || 'restaurant',
    });

    await owner.save();

    // Generate token
    const token = jwt.sign(
      { id: owner._id, email: owner.email },
      process.env.JWT_SECRET || 'your_secret_key',
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.status(201).json({
      message: 'Registration successful',
      token,
      owner: {
        id: owner._id,
        name: owner.name,
        email: owner.email,
        phone: owner.phone,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Error registering owner', error: error.message });
  }
};

// Login shop owner
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide email and password' });
    }

    const owner = await ShopOwner.findOne({ email });
    if (!owner) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const isPasswordValid = await owner.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: owner._id, email: owner.email },
      process.env.JWT_SECRET || 'your_secret_key',
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      owner: {
        id: owner._id,
        name: owner.name,
        email: owner.email,
        phone: owner.phone,
        businessName: owner.businessName,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Error logging in', error: error.message });
  }
};

// Get owner profile
exports.getProfile = async (req, res) => {
  try {
    const owner = await ShopOwner.findById(req.user.id).select('-password');
    if (!owner) {
      return res.status(404).json({ message: 'Owner not found' });
    }
    res.json(owner);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching profile', error: error.message });
  }
};

// Update owner profile
exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, businessName, businessType, bankDetails, documents } = req.body;
    const owner = await ShopOwner.findByIdAndUpdate(
      req.user.id,
      {
        name,
        phone,
        businessName,
        businessType,
        bankDetails,
        documents,
        updatedAt: new Date(),
      },
      { new: true }
    ).select('-password');

    res.json({ message: 'Profile updated successfully', owner });
  } catch (error) {
    res.status(500).json({ message: 'Error updating profile', error: error.message });
  }
};
