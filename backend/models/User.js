const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Define a schema for user preferences
const UserPreferencesSchema = new mongoose.Schema({
  currency: {
    type: String,
    default: 'USD'
  },
  theme: {
    type: String,
    enum: ['light', 'dark', 'system'],
    default: 'system'
  },
  notifications: {
    type: Boolean,
    default: true
  },
  budgetReminders: {
    type: Boolean,
    default: true
  },
  savingsReminders: {
    type: Boolean,
    default: true
  },
  transactionAlerts: {
    type: Boolean,
    default: true
  },
  weeklyReports: {
    type: Boolean,
    default: true
  },
  language: {
    type: String,
    default: 'en'
  }
}, { _id: false });

// Define a schema for user security settings
const SecuritySettingsSchema = new mongoose.Schema({
  twoFactorEnabled: {
    type: Boolean,
    default: false
  },
  lastPasswordChange: {
    type: Date,
    default: Date.now
  },
  loginNotifications: {
    type: Boolean,
    default: true
  },
  securityQuestions: [
    {
      question: String,
      answer: {
        type: String,
        select: false
      }
    }
  ]
}, { _id: false });

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please add a name'],
    trim: true,
    maxlength: [50, 'Name cannot be more than 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Please add an email'],
    unique: true,
    match: [
      /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
      'Please add a valid email'
    ]
  },
  mobile: {
    type: String,
    match: [/^[0-9]{10}$/, 'Please add a valid mobile number'],
    unique: true,
    sparse: true
  },
  password: {
    type: String,
    required: [true, 'Please add a password'],
    minlength: 6,
    select: false
  },
  firstName: {
    type: String,
    trim: true
  },
  lastName: {
    type: String,
    trim: true
  },
  dob: {
    type: Date
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer_not_to_say'],
    default: 'prefer_not_to_say'
  },
  occupation: {
    type: String,
    trim: true
  },
  address: {
    street: String,
    city: String,
    state: String,
    zipCode: String,
    country: String
  },
  profilePicture: {
    type: String,
    default: 'default-profile.jpg'
  },
  profilePictureData: {
    url: {
      type: String,
      default: null
    },
    uploadDate: {
      type: Date,
      default: null
    },
    size: {
      type: Number,
      default: null
    },
    contentType: {
      type: String,
      default: null
    }
  },
  bio: {
    type: String,
    maxlength: [500, 'Bio cannot be more than 500 characters']
  },
  monthlyIncome: {
    type: Number,
    default: 0
  },
  financialGoals: [
    {
      title: String,
      description: String,
      targetDate: Date
    }
  ],
  preferences: UserPreferencesSchema,
  security: SecuritySettingsSchema,
  lastActive: {
    type: Date,
    default: Date.now
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  role: {
    type: String,
    enum: ['user', 'admin', 'system'],
    default: 'user'
  }
}, {
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for full name
UserSchema.virtual('fullName').get(function() {
  if (this.firstName && this.lastName) {
    return `${this.firstName} ${this.lastName}`;
  }
  return this.name;
});

// Encrypt password using bcrypt
UserSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  
  // Update lastPasswordChange date if password is modified
  if (this.isModified('password') && this.security) {
    this.security.lastPasswordChange = Date.now();
  }
  
  // Set name from firstName and lastName if they exist and name is not set
  if (!this.name && this.firstName && this.lastName) {
    this.name = `${this.firstName} ${this.lastName}`;
  }
});

// Sign JWT and return
// Sign JWT and return with configurable expiry (e.g. '30d' or seconds)
UserSchema.methods.getSignedJwtToken = function () {
  const expiresIn = process.env.JWT_EXPIRES_IN || process.env.JWT_EXPIRE || '1d'; // fallback 1 day
  return jwt.sign({ id: this._id }, process.env.JWT_SECRET, { expiresIn });
};

// Match user entered password to hashed password in database
UserSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', UserSchema);
