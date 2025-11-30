const mongoose = require('mongoose');

const ChallengeSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  points: {
    type: Number,
    required: true
  },
  type: {
    type: String,
    enum: ['daily', 'weekly', 'monthly', 'one-time', 'weekend', 'milestone'],
    default: 'daily'
  },
  category: {
    type: String,
    enum: ['savings', 'spending', 'budgeting', 'tracking'],
    required: true
  },
  isCompleted: {
    type: Boolean,
    default: false
  },
  completedDate: {
    type: Date
  },
  expiryDate: {
    type: Date
  },
  icon: {
    type: String,
    default: 'star'
  },
  currentValue: {
    type: Number,
    default: 0
  },
  targetValue: {
    type: Number,
    default: 1
  }
});

const AchievementSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  points: {
    type: Number,
    required: true
  },
  category: {
    type: String,
    enum: ['savings', 'spending', 'budgeting', 'tracking', 'milestone'],
    required: true
  },
  isUnlocked: {
    type: Boolean,
    default: false
  },
  unlockedDate: {
    type: Date
  },
  icon: {
    type: String,
    default: 'trophy'
  },
  level: {
    type: Number,
    default: 1
  }
});

const GamificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  points: {
    type: Number,
    default: 0
  },
  level: {
    type: Number,
    default: 1
  },
  streak: {
    type: Number,
    default: 0
  },
  longestStreak: {
    type: Number,
    default: 0
  },
  lastActive: {
    type: Date,
    default: Date.now
  },
  coins: {
    type: Number,
    default: 0
  },
  financialHealthScore: {
    type: Number,
    default: 50 // Score from 0-100
  },
  challenges: [ChallengeSchema],
  achievements: [AchievementSchema],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Virtual to calculate experience points needed for next level
GamificationSchema.virtual('nextLevelXP').get(function() {
  return this.level * 100;
});

// Virtual to calculate progress to next level (0.0 to 1.0)
GamificationSchema.virtual('levelProgress').get(function() {
  const pointsForCurrentLevel = (this.level - 1) * 100;
  const pointsForNextLevel = this.level * 100;
  const pointsInCurrentLevel = this.points - pointsForCurrentLevel;
  const pointsNeededForNextLevel = pointsForNextLevel - pointsForCurrentLevel;
  
  return pointsInCurrentLevel / pointsNeededForNextLevel;
});

module.exports = mongoose.model('Gamification', GamificationSchema);
