const Gamification = require('../models/Gamification');
const Transaction = require('../models/Transaction');
const Budget = require('../models/Budget');
const SavingsGoal = require('../models/SavingsGoal');
const ChallengeAssignmentService = require('../services/challengeAssignment.service');

// @desc    Get user gamification data
// @route   GET /api/gamification
// @access  Private
exports.getGamificationData = async (req, res) => {
  try {
    let gamification = await Gamification.findOne({ user: req.user.id });
    
    // If gamification data doesn't exist, create it with default values
    if (!gamification) {
      const initialChallenges = await ChallengeAssignmentService.assignDailyChallenges(
        req.user.id,
        null
      );
      
      gamification = await Gamification.create({
        user: req.user.id,
        points: 0,
        level: 1,
        streak: 0,
        coins: 0,
        financialHealthScore: 50,
        challenges: initialChallenges,
        achievements: generateDefaultAchievements()
      });
    }
    
    // Check if user needs new challenges (daily refresh at 5 AM)
    if (ChallengeAssignmentService.needsChallengeRefresh(gamification)) {
      const newChallenges = await ChallengeAssignmentService.assignDailyChallenges(
        req.user.id,
        gamification
      );
      
      // Replace old challenges with new ones (don't keep completed ones)
      gamification.challenges = newChallenges;
      await gamification.save();
      console.log(`🔄 Refreshed challenges for user ${req.user.id} - ${newChallenges.length} new challenges`);
    }
    
    // Auto-check challenge completion
    await ChallengeAssignmentService.autoCheckChallenges(req.user.id, gamification);
    
    // Check and update streak
    await updateStreak(gamification);
    
    // Reload gamification to get latest changes
    gamification = await Gamification.findOne({ user: req.user.id });
    
    res.status(200).json({
      success: true,
      data: gamification
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get financial health score
// @route   GET /api/gamification/financial-health
// @access  Private
exports.getFinancialHealthScore = async (req, res) => {
  try {
    let gamification = await Gamification.findOne({ user: req.user.id });
    
    if (!gamification) {
      return res.status(404).json({
        success: false,
        message: 'Gamification data not found'
      });
    }
    
    // Calculate financial health score
    const score = await calculateFinancialHealthScore(req.user.id);
    
    // Update score in database
    gamification.financialHealthScore = score;
    await gamification.save();
    
    res.status(200).json({
      success: true,
      data: {
        score,
        breakdown: {
          savingsRate: score * 0.3, // 30% of score
          budgetAdherence: score * 0.25, // 25% of score
          expenseManagement: score * 0.25, // 25% of score
          goalProgress: score * 0.2 // 20% of score
        }
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

// @desc    Get challenges
// @route   GET /api/gamification/challenges
// @access  Private
exports.getChallenges = async (req, res) => {
  try {
    const gamification = await Gamification.findOne({ user: req.user.id });
    
    if (!gamification) {
      return res.status(404).json({
        success: false,
        message: 'Gamification data not found'
      });
    }
    
    // Check for expired challenges and generate new ones
    await refreshChallenges(gamification);
    
    res.status(200).json({
      success: true,
      data: {
        challenges: gamification.challenges
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

// @desc    Complete a challenge
// @route   POST /api/gamification/challenges/:id/complete
// @access  Private
exports.completeChallenge = async (req, res) => {
  try {
    const gamification = await Gamification.findOne({ user: req.user.id });
    
    if (!gamification) {
      return res.status(404).json({
        success: false,
        message: 'Gamification data not found'
      });
    }
    
    // Find the challenge - try both MongoDB ID and string ID matching
    let challenge = gamification.challenges.id(req.params.id);
    
    // If not found by MongoDB ID, try to find by string ID
    if (!challenge) {
      challenge = gamification.challenges.find(c => c.id === req.params.id);
    }
    
    if (!challenge) {
      console.log(`Challenge not found: ${req.params.id}`);
      console.log(`Available challenges: ${gamification.challenges.map(c => c.id).join(', ')}`);
      return res.status(404).json({
        success: false,
        message: 'Challenge not found'
      });
    }
    
    if (challenge.isCompleted) {
      return res.status(400).json({
        success: false,
        message: 'Challenge already completed'
      });
    }
    
    // Mark as completed and add points
    challenge.isCompleted = true;
    challenge.completedDate = new Date();
    gamification.points += challenge.points;
    
    // Check if level up is needed
    const oldLevel = gamification.level;
    gamification.level = Math.floor(gamification.points / 100) + 1;
    
    const leveledUp = gamification.level > oldLevel;
    
    await gamification.save();
    
    res.status(200).json({
      success: true,
      data: {
        challenge,
        points: gamification.points,
        level: gamification.level,
        leveledUp,
        nextLevelXP: gamification.nextLevelXP,
        levelProgress: gamification.levelProgress
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

// @desc    Get achievements
// @route   GET /api/gamification/achievements
// @access  Private
exports.getAchievements = async (req, res) => {
  try {
    const gamification = await Gamification.findOne({ user: req.user.id });
    
    if (!gamification) {
      return res.status(404).json({
        success: false,
        message: 'Gamification data not found'
      });
    }
    
    // Check for new achievements
    await checkAchievements(req.user.id, gamification);
    
    res.status(200).json({
      success: true,
      data: {
        achievements: gamification.achievements
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

// Helper functions

// Generate default challenges
function generateDefaultChallenges() {
  const now = new Date();
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(5, 0, 0, 0); // Reset at 5 AM
  
  return [
    {
      title: 'Track Your Spending',
      description: 'Add 3 expenses to track your spending',
      points: 10,
      type: 'daily',
      category: 'tracking',
      isCompleted: false,
      expiryDate: tomorrow,
      icon: 'receipt',
      currentValue: 0,
      targetValue: 3
    },
    {
      title: 'Save Some Money',
      description: 'Add money to one of your savings goals',
      points: 15,
      type: 'daily',
      category: 'savings',
      isCompleted: false,
      expiryDate: tomorrow,
      icon: 'savings',
      currentValue: 0,
      targetValue: 1
    },
    {
      title: 'Budget Master',
      description: 'Stay under budget for all categories today',
      points: 20,
      type: 'daily',
      category: 'budgeting',
      isCompleted: false,
      expiryDate: tomorrow,
      icon: 'account_balance',
      currentValue: 0,
      targetValue: 1
    }
  ];
}

// Generate default achievements
function generateDefaultAchievements() {
  return [
    {
      title: 'First Steps',
      description: 'Complete your first financial transaction',
      points: 10,
      category: 'tracking',
      isUnlocked: false,
      icon: 'emoji_events',
      level: 1
    },
    {
      title: 'Budget Beginner',
      description: 'Create your first budget',
      points: 15,
      category: 'budgeting',
      isUnlocked: false,
      icon: 'account_balance_wallet',
      level: 1
    },
    {
      title: 'Savings Starter',
      description: 'Create your first savings goal',
      points: 15,
      category: 'savings',
      isUnlocked: false,
      icon: 'savings',
      level: 1
    },
    {
      title: 'Expense Tracker',
      description: 'Track 10 expenses',
      points: 20,
      category: 'tracking',
      isUnlocked: false,
      icon: 'trending_down',
      level: 2
    },
    {
      title: 'Income Tracker',
      description: 'Track 5 income sources',
      points: 20,
      category: 'tracking',
      isUnlocked: false,
      icon: 'trending_up',
      level: 2
    },
    {
      title: 'Budget Master',
      description: 'Stay under budget for a full month',
      points: 50,
      category: 'budgeting',
      isUnlocked: false,
      icon: 'workspace_premium',
      level: 3
    }
  ];
}

// Update user streak
async function updateStreak(gamification) {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  
  // Get last active date (default to epoch if not set)
  const lastActive = gamification.lastActive ? new Date(gamification.lastActive) : new Date(0);
  const lastActiveDate = new Date(lastActive.getFullYear(), lastActive.getMonth(), lastActive.getDate());
  
  // Calculate days difference
  const daysDiff = Math.floor((today - lastActiveDate) / (1000 * 60 * 60 * 24));
  
  if (daysDiff === 0) {
    // Same day - no change to streak
    return;
  } else if (daysDiff === 1) {
    // Consecutive day - increment streak
    gamification.streak = (gamification.streak || 0) + 1;
    if (gamification.streak > (gamification.longestStreak || 0)) {
      gamification.longestStreak = gamification.streak;
    }
    console.log(`🔥 User streak: ${gamification.streak} days`);
  } else {
    // Missed days - reset streak to 1
    gamification.streak = 1;
    console.log(`⚠️ Streak reset to 1 (missed ${daysDiff - 1} days)`);
  }
  
  // Update last active to today
  gamification.lastActive = now;
  await gamification.save();
}

// Refresh challenges
async function refreshChallenges(gamification) {
  const now = new Date();
  
  // Filter out expired challenges
  const activeChallenges = gamification.challenges.filter(challenge => {
    return new Date(challenge.expiryDate) > now || challenge.isCompleted;
  });
  
  // Generate new challenges if needed
  if (activeChallenges.length < 3) {
    const newChallenges = generateDefaultChallenges();
    
    // Only add challenges that don't already exist
    for (const newChallenge of newChallenges) {
      const exists = activeChallenges.some(
        c => c.title === newChallenge.title && !c.isCompleted
      );
      
      if (!exists) {
        activeChallenges.push(newChallenge);
      }
      
      // Stop adding once we have 3 active challenges
      if (activeChallenges.length >= 3) break;
    }
  }
  
  gamification.challenges = activeChallenges;
  await gamification.save();
}

// Calculate financial health score
async function calculateFinancialHealthScore(userId) {
  try {
    // Get user's transactions for the last 3 months
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);
    
    const transactions = await Transaction.find({
      user: userId,
      date: { $gte: threeMonthsAgo }
    });
    
    // Get user's budgets
    const budgets = await Budget.find({ user: userId });
    
    // Get user's savings goals
    const savingsGoals = await SavingsGoal.find({ user: userId });
    
    // Calculate savings rate (30% of score)
    let savingsRateScore = 0;
    const income = transactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const expenses = transactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    
    if (income > 0) {
      const savingsRate = (income - expenses) / income;
      savingsRateScore = Math.min(30, savingsRate * 100);
    }
    
    // Calculate budget adherence (25% of score)
    let budgetAdherenceScore = 0;
    if (budgets.length > 0) {
      const budgetsWithinLimit = budgets.filter(b => b.spent <= b.limit).length;
      budgetAdherenceScore = (budgetsWithinLimit / budgets.length) * 25;
    }
    
    // Calculate expense management (25% of score)
    let expenseManagementScore = 0;
    const monthlyExpenseGroups = {};
    
    transactions.forEach(t => {
      if (t.type === 'expense') {
        const monthKey = `${t.date.getFullYear()}-${t.date.getMonth()}`;
        if (!monthlyExpenseGroups[monthKey]) {
          monthlyExpenseGroups[monthKey] = [];
        }
        monthlyExpenseGroups[monthKey].push(t);
      }
    });
    
    // Check for consistent expense tracking
    const monthKeys = Object.keys(monthlyExpenseGroups);
    if (monthKeys.length >= 3) {
      expenseManagementScore += 15; // Consistent tracking
      
      // Check for expense reduction trend
      const monthlyTotals = monthKeys.map(key => {
        return {
          month: key,
          total: monthlyExpenseGroups[key].reduce((sum, t) => sum + t.amount, 0)
        };
      }).sort((a, b) => a.month.localeCompare(b.month));
      
      if (
        monthlyTotals.length >= 3 &&
        monthlyTotals[monthlyTotals.length - 1].total <
          monthlyTotals[monthlyTotals.length - 2].total
      ) {
        expenseManagementScore += 10; // Reducing expenses
      }
    } else if (monthKeys.length >= 1) {
      expenseManagementScore += 5; // Some tracking
    }
    
    // Calculate goal progress (20% of score)
    let goalProgressScore = 0;
    if (savingsGoals.length > 0) {
      const totalProgress = savingsGoals.reduce(
        (sum, goal) => sum + (goal.currentAmount / goal.targetAmount),
        0
      );
      
      goalProgressScore = (totalProgress / savingsGoals.length) * 20;
    }
    
    // Calculate total score
    const totalScore = Math.round(
      savingsRateScore + budgetAdherenceScore + expenseManagementScore + goalProgressScore
    );
    
    return Math.min(100, Math.max(0, totalScore));
  } catch (error) {
    console.error('Error calculating financial health score:', error);
    return 50; // Default score on error
  }
}

// Check for new achievements
async function checkAchievements(userId, gamification) {
  try {
    // Get user's transactions
    const transactions = await Transaction.find({ user: userId });
    
    // Get user's budgets
    const budgets = await Budget.find({ user: userId });
    
    // Get user's savings goals
    const savingsGoals = await SavingsGoal.find({ user: userId });
    
    const achievements = gamification.achievements;
    let pointsEarned = 0;
    
    // Check First Steps achievement
    const firstStepsAchievement = achievements.find(a => a.title === 'First Steps');
    if (firstStepsAchievement && !firstStepsAchievement.isUnlocked && transactions.length > 0) {
      firstStepsAchievement.isUnlocked = true;
      firstStepsAchievement.unlockedDate = new Date();
      pointsEarned += firstStepsAchievement.points;
    }
    
    // Check Budget Beginner achievement
    const budgetBeginnerAchievement = achievements.find(a => a.title === 'Budget Beginner');
    if (budgetBeginnerAchievement && !budgetBeginnerAchievement.isUnlocked && budgets.length > 0) {
      budgetBeginnerAchievement.isUnlocked = true;
      budgetBeginnerAchievement.unlockedDate = new Date();
      pointsEarned += budgetBeginnerAchievement.points;
    }
    
    // Check Savings Starter achievement
    const savingsStarterAchievement = achievements.find(a => a.title === 'Savings Starter');
    if (savingsStarterAchievement && !savingsStarterAchievement.isUnlocked && savingsGoals.length > 0) {
      savingsStarterAchievement.isUnlocked = true;
      savingsStarterAchievement.unlockedDate = new Date();
      pointsEarned += savingsStarterAchievement.points;
    }
    
    // Check Expense Tracker achievement
    const expenseTrackerAchievement = achievements.find(a => a.title === 'Expense Tracker');
    if (expenseTrackerAchievement && !expenseTrackerAchievement.isUnlocked) {
      const expenseCount = transactions.filter(t => t.type === 'expense').length;
      if (expenseCount >= 10) {
        expenseTrackerAchievement.isUnlocked = true;
        expenseTrackerAchievement.unlockedDate = new Date();
        pointsEarned += expenseTrackerAchievement.points;
      }
    }
    
    // Check Income Tracker achievement
    const incomeTrackerAchievement = achievements.find(a => a.title === 'Income Tracker');
    if (incomeTrackerAchievement && !incomeTrackerAchievement.isUnlocked) {
      const incomeCount = transactions.filter(t => t.type === 'income').length;
      if (incomeCount >= 5) {
        incomeTrackerAchievement.isUnlocked = true;
        incomeTrackerAchievement.unlockedDate = new Date();
        pointsEarned += incomeTrackerAchievement.points;
      }
    }
    
    // Add points earned from achievements
    if (pointsEarned > 0) {
      gamification.points += pointsEarned;
      
      // Check if level up is needed
      gamification.level = Math.floor(gamification.points / 100) + 1;
      
      await gamification.save();
    }
  } catch (error) {
    console.error('Error checking achievements:', error);
  }
}

// @desc    Update user gamification data
// @route   PUT /api/gamification
// @access  Private
exports.updateGamificationData = async (req, res) => {
  try {
    let gamification = await Gamification.findOne({ user: req.user.id });
    
    if (!gamification) {
      return res.status(404).json({
        success: false,
        message: 'Gamification data not found'
      });
    }
    
    // Update fields from request body
    if (req.body.streak !== undefined) gamification.streak = req.body.streak;
    if (req.body.longestStreak !== undefined) {
      // Only update if the new streak is longer
      if (req.body.longestStreak > gamification.longestStreak) {
        gamification.longestStreak = req.body.longestStreak;
      }
    }
    if (req.body.lastActivityDate !== undefined) gamification.lastActive = new Date(req.body.lastActivityDate);
    if (req.body.points !== undefined) gamification.points = req.body.points;
    if (req.body.level !== undefined) gamification.level = req.body.level;
    if (req.body.financialHealthScore !== undefined) gamification.financialHealthScore = req.body.financialHealthScore;
    
    // Save the updated gamification data
    await gamification.save();
    
    res.status(200).json({
      success: true,
      data: gamification
    });
  } catch (error) {
    console.error('Error updating gamification data:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Update challenges
// @route   PUT /api/gamification/challenges
// @access  Private
exports.updateChallenges = async (req, res) => {
  try {
    let gamification = await Gamification.findOne({ user: req.user.id });
    
    if (!gamification) {
      return res.status(404).json({
        success: false,
        message: 'Gamification data not found'
      });
    }
    
    // Update challenges if provided
    if (req.body.challenges && Array.isArray(req.body.challenges)) {
      console.log(`Received ${req.body.challenges.length} challenges to update`);
      
      // For each challenge in the request, sanitize then update or add it
      req.body.challenges.forEach(incomingChallenge => {
        // Sanitize incoming challenge to avoid CastError / validation errors
        // 1. Remove invalid _id (empty string or not a valid 24-char hex) so Mongoose can generate one
        if (typeof incomingChallenge._id === 'string') {
          const idStr = incomingChallenge._id.trim();
          if (!idStr || !/^[0-9a-fA-F]{24}$/.test(idStr)) {
            delete incomingChallenge._id;
          }
        }

        // 2. Fix wrongly mapped category/type values coming from older clients
        const validCategories = ['savings', 'spending', 'budgeting', 'tracking'];
        const validTypes = ['daily', 'weekly', 'monthly', 'one-time'];

        // If category contains a type value (e.g. "daily"), swap them
        if (incomingChallenge.category && !validCategories.includes(incomingChallenge.category)) {
          // If it's actually a type value, move it
          if (validTypes.includes(incomingChallenge.category)) {
            incomingChallenge.type = incomingChallenge.category;
          }
          // Set a safe default category if none provided or invalid
          incomingChallenge.category = incomingChallenge.category && validCategories.includes(incomingChallenge.category)
            ? incomingChallenge.category
            : 'tracking';
        }

        // Ensure type is valid, otherwise default to 'daily'
        if (!incomingChallenge.type || !validTypes.includes(incomingChallenge.type)) {
          incomingChallenge.type = 'daily';
        }
        // Try to find an existing challenge with the same ID
        let existingChallenge = gamification.challenges.id(incomingChallenge.id);
        
        // If not found by MongoDB ID, try to find by string ID
        if (!existingChallenge && incomingChallenge.id) {
          existingChallenge = gamification.challenges.find(c => c.id === incomingChallenge.id);
        }
        
        if (existingChallenge) {
          console.log(`Merging challenge: ${existingChallenge.id}`);
          // DON'T overwrite backend progress - merge intelligently
          Object.keys(incomingChallenge).forEach(key => {
            // Skip overwriting currentValue if backend has higher value
            if (key === 'currentValue') {
              const serverValue = existingChallenge.currentValue || 0;
              const clientValue = incomingChallenge.currentValue || 0;
              existingChallenge.currentValue = Math.max(serverValue, clientValue);
            }
            // Skip overwriting isCompleted if already completed on server
            else if (key === 'isCompleted') {
              existingChallenge.isCompleted = existingChallenge.isCompleted || incomingChallenge.isCompleted;
            }
            // Skip overwriting completedDate if already set
            else if (key === 'completedDate') {
              if (!existingChallenge.completedDate && incomingChallenge.completedDate) {
                existingChallenge.completedDate = incomingChallenge.completedDate;
              }
            }
            // Update other fields normally
            else {
              existingChallenge[key] = incomingChallenge[key];
            }
          });
          console.log(`Final values - currentValue: ${existingChallenge.currentValue}, isCompleted: ${existingChallenge.isCompleted}`);
        } else {
          console.log(`Adding new challenge: ${incomingChallenge.id || 'unknown id'}`);
          // Add new challenge
          gamification.challenges.push(incomingChallenge);
        }
      });
    }
    
    // Save the updated gamification data
    await gamification.save();
    
    res.status(200).json({
      success: true,
      data: {
        challenges: gamification.challenges
      }
    });
  } catch (error) {
    console.error('Error updating challenges:', error);
    console.error('Request body:', JSON.stringify(req.body, null, 2));
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
      stack: process.env.NODE_ENV === 'production' ? null : error.stack
    });
  }
};

// @desc    Update badges/achievements
// @route   PUT /api/gamification/badges
// @access  Private
exports.updateBadges = async (req, res) => {
  try {
    let gamification = await Gamification.findOne({ user: req.user.id });
    
    if (!gamification) {
      return res.status(404).json({
        success: false,
        message: 'Gamification data not found'
      });
    }
    
    // Update badges/achievements based on the request
    if (req.body.badges && Array.isArray(req.body.badges)) {
      // For each badge ID, find the corresponding achievement and mark it as unlocked
      for (const badgeId of req.body.badges) {
        const achievement = gamification.achievements.find(a => a._id.toString() === badgeId || a.id === badgeId);
        if (achievement && !achievement.isUnlocked) {
          achievement.isUnlocked = true;
          achievement.unlockedDate = new Date();
          
          // Award points for unlocking this achievement
          gamification.points += achievement.points || 10;
          
          console.log(`User ${req.user.id} unlocked achievement: ${achievement.title}`);
        }
      }
      
      // Check if level up is needed after adding points
      const oldLevel = gamification.level;
      gamification.level = Math.floor(gamification.points / 100) + 1;
      
      if (gamification.level > oldLevel) {
        console.log(`User ${req.user.id} leveled up from ${oldLevel} to ${gamification.level}`);
      }
    }
    
    // Save the updated gamification data
    await gamification.save();
    
    res.status(200).json({
      success: true,
      data: {
        achievements: gamification.achievements,
        level: gamification.level,
        points: gamification.points
      }
    });
  } catch (error) {
    console.error('Error updating badges:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};
