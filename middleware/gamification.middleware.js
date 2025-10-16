const Gamification = require('../models/Gamification');

/**
 * Middleware to automatically update gamification data when user performs actions
 * This runs after successful transaction/budget/goal operations
 */

// Auto-update gamification after transaction
exports.updateAfterTransaction = async (req, res, next) => {
  try {
    // Only proceed if there's a user and the operation was successful
    if (!req.user || !req.user.id) {
      return next();
    }

    const transaction = req.transaction; // Set by controller after creating transaction
    if (!transaction) {
      return next();
    }

    let gamification = await Gamification.findOne({ user: req.user.id });
    
    if (!gamification) {
      // Create gamification data if it doesn't exist
      gamification = await Gamification.create({
        user: req.user.id,
        points: 0,
        level: 1,
        streak: 0,
        financialHealthScore: 50,
        challenges: generateDefaultChallenges(),
        achievements: generateDefaultAchievements()
      });
    }

    let pointsEarned = 0;
    let coinsEarned = 0;

    // Award points for adding transaction
    pointsEarned += 5; // Base points for any transaction
    coinsEarned += 2;

    // Check if this completes any challenges
    for (const challenge of gamification.challenges) {
      if (challenge.isCompleted) continue;

      // Track Your Spending challenge
      if (challenge.title === 'Track Your Spending' && transaction.type === 'expense') {
        challenge.currentValue = (challenge.currentValue || 0) + 1;
        challenge.targetValue = challenge.targetValue || 3;
        
        if (challenge.currentValue >= challenge.targetValue && !challenge.isCompleted) {
          challenge.isCompleted = true;
          challenge.completedDate = new Date();
          pointsEarned += challenge.points || 10;
          coinsEarned += 5;
          console.log(`✅ Challenge completed: ${challenge.title}`);
        }
      }
    }

    // Check achievements
    const Transaction = require('../models/Transaction');
    const allTransactions = await Transaction.find({ user: req.user.id });
    
    // First Steps achievement
    const firstSteps = gamification.achievements.find(a => a.title === 'First Steps');
    if (firstSteps && !firstSteps.isUnlocked && allTransactions.length === 1) {
      firstSteps.isUnlocked = true;
      firstSteps.unlockedDate = new Date();
      pointsEarned += firstSteps.points || 10;
      coinsEarned += 10;
      console.log(`🏆 Achievement unlocked: First Steps`);
    }

    // Expense Tracker achievement (10 expenses)
    const expenseTracker = gamification.achievements.find(a => a.title === 'Expense Tracker');
    if (expenseTracker && !expenseTracker.isUnlocked) {
      const expenseCount = allTransactions.filter(t => t.type === 'expense').length;
      if (expenseCount >= 10) {
        expenseTracker.isUnlocked = true;
        expenseTracker.unlockedDate = new Date();
        pointsEarned += expenseTracker.points || 20;
        coinsEarned += 20;
        console.log(`🏆 Achievement unlocked: Expense Tracker`);
      }
    }

    // Income Tracker achievement (5 incomes)
    const incomeTracker = gamification.achievements.find(a => a.title === 'Income Tracker');
    if (incomeTracker && !incomeTracker.isUnlocked) {
      const incomeCount = allTransactions.filter(t => t.type === 'income').length;
      if (incomeCount >= 5) {
        incomeTracker.isUnlocked = true;
        incomeTracker.unlockedDate = new Date();
        pointsEarned += incomeTracker.points || 20;
        coinsEarned += 20;
        console.log(`🏆 Achievement unlocked: Income Tracker`);
      }
    }

    // Update points and level
    if (pointsEarned > 0) {
      gamification.points += pointsEarned;
      gamification.coins = (gamification.coins || 0) + coinsEarned;
      
      const oldLevel = gamification.level;
      gamification.level = Math.floor(gamification.points / 100) + 1;
      
      if (gamification.level > oldLevel) {
        console.log(`🎉 Level up! ${oldLevel} → ${gamification.level}`);
      }
      
      await gamification.save();
      
      console.log(`+${pointsEarned} XP, +${coinsEarned} coins`);
    }

    next();
  } catch (error) {
    console.error('Gamification middleware error:', error);
    // Don't block the main operation if gamification fails
    next();
  }
};

// Auto-update gamification after budget creation
exports.updateAfterBudget = async (req, res, next) => {
  try {
    if (!req.user || !req.user.id || !req.budget) {
      return next();
    }

    let gamification = await Gamification.findOne({ user: req.user.id });
    if (!gamification) return next();

    let pointsEarned = 0;
    let coinsEarned = 0;

    // Award points for creating budget
    pointsEarned += 10;
    coinsEarned += 5;

    // Check Budget Beginner achievement
    const budgetBeginner = gamification.achievements.find(a => a.title === 'Budget Beginner');
    const Budget = require('../models/Budget');
    const budgets = await Budget.find({ user: req.user.id });
    
    if (budgetBeginner && !budgetBeginner.isUnlocked && budgets.length === 1) {
      budgetBeginner.isUnlocked = true;
      budgetBeginner.unlockedDate = new Date();
      pointsEarned += budgetBeginner.points || 15;
      coinsEarned += 15;
      console.log(`🏆 Achievement unlocked: Budget Beginner`);
    }

    if (pointsEarned > 0) {
      gamification.points += pointsEarned;
      gamification.coins = (gamification.coins || 0) + coinsEarned;
      gamification.level = Math.floor(gamification.points / 100) + 1;
      await gamification.save();
      console.log(`+${pointsEarned} XP, +${coinsEarned} coins (Budget created)`);
    }

    next();
  } catch (error) {
    console.error('Gamification middleware error:', error);
    next();
  }
};

// Auto-update gamification after savings goal creation/update
exports.updateAfterSavingsGoal = async (req, res, next) => {
  try {
    if (!req.user || !req.user.id || !req.savingsGoal) {
      return next();
    }

    let gamification = await Gamification.findOne({ user: req.user.id });
    if (!gamification) return next();

    let pointsEarned = 0;
    let coinsEarned = 0;

    // Award points for savings goal action
    pointsEarned += 15;
    coinsEarned += 10;

    // Check Savings Starter achievement
    const savingsStarter = gamification.achievements.find(a => a.title === 'Savings Starter');
    const SavingsGoal = require('../models/SavingsGoal');
    const goals = await SavingsGoal.find({ user: req.user.id });
    
    if (savingsStarter && !savingsStarter.isUnlocked && goals.length === 1) {
      savingsStarter.isUnlocked = true;
      savingsStarter.unlockedDate = new Date();
      pointsEarned += savingsStarter.points || 15;
      coinsEarned += 15;
      console.log(`🏆 Achievement unlocked: Savings Starter`);
    }

    // Check "Save Some Money" challenge
    for (const challenge of gamification.challenges) {
      if (challenge.title === 'Save Some Money' && !challenge.isCompleted) {
        challenge.isCompleted = true;
        challenge.completedDate = new Date();
        pointsEarned += challenge.points || 15;
        coinsEarned += 5;
        console.log(`✅ Challenge completed: Save Some Money`);
        break;
      }
    }

    if (pointsEarned > 0) {
      gamification.points += pointsEarned;
      gamification.coins = (gamification.coins || 0) + coinsEarned;
      gamification.level = Math.floor(gamification.points / 100) + 1;
      await gamification.save();
      console.log(`+${pointsEarned} XP, +${coinsEarned} coins (Savings goal)`);
    }

    next();
  } catch (error) {
    console.error('Gamification middleware error:', error);
    next();
  }
};

// Helper functions
function generateDefaultChallenges() {
  const now = new Date();
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
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

module.exports = exports;
