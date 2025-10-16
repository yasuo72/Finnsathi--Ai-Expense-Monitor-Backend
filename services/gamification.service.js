const Gamification = require('../models/Gamification');
const Transaction = require('../models/Transaction');
const Budget = require('../models/Budget');
const SavingsGoal = require('../models/SavingsGoal');
const ChallengeAssignmentService = require('./challengeAssignment.service');

/**
 * Gamification Service - Automatically updates XP, levels, challenges, and achievements
 * Call these functions after successful operations to award points
 */

class GamificationService {
  
  // Update gamification after adding a transaction
  async updateAfterTransaction(userId, transaction) {
    try {
      let gamification = await Gamification.findOne({ user: userId });
      
      if (!gamification) {
        gamification = await this.initializeGamification(userId);
      }

      let pointsEarned = 0;
      let coinsEarned = 0;

      // Award base points for transaction
      pointsEarned += 5;
      coinsEarned += 2;

      // Update "Track Your Spending" challenge
      await this.updateTrackingChallenge(gamification, transaction);

      // Check achievements
      const allTransactions = await Transaction.find({ user: userId });
      
      // First Steps achievement
      if (allTransactions.length === 1) {
        const achievement = gamification.achievements.find(a => a.title === 'First Steps');
        if (achievement && !achievement.isUnlocked) {
          achievement.isUnlocked = true;
          achievement.unlockedDate = new Date();
          pointsEarned += achievement.points || 10;
          coinsEarned += 10;
          console.log(`🏆 ${userId}: Achievement unlocked - First Steps`);
        }
      }

      // Expense Tracker achievement (10 expenses)
      const expenseCount = allTransactions.filter(t => t.type === 'expense').length;
      if (expenseCount >= 10) {
        const achievement = gamification.achievements.find(a => a.title === 'Expense Tracker');
        if (achievement && !achievement.isUnlocked) {
          achievement.isUnlocked = true;
          achievement.unlockedDate = new Date();
          pointsEarned += achievement.points || 20;
          coinsEarned += 20;
          console.log(`🏆 ${userId}: Achievement unlocked - Expense Tracker`);
        }
      }

      // Income Tracker achievement (5 incomes)
      const incomeCount = allTransactions.filter(t => t.type === 'income').length;
      if (incomeCount >= 5) {
        const achievement = gamification.achievements.find(a => a.title === 'Income Tracker');
        if (achievement && !achievement.isUnlocked) {
          achievement.isUnlocked = true;
          achievement.unlockedDate = new Date();
          pointsEarned += achievement.points || 20;
          coinsEarned += 20;
          console.log(`🏆 ${userId}: Achievement unlocked - Income Tracker`);
        }
      }

      // Update points, coins, and level
      if (pointsEarned > 0) {
        // Update points if any challenges completed
        if (0 > 0) {
          gamification.points += 0;
          gamification.coins = (gamification.coins || 0) + 0;
          
          // Check level up
          const oldLevel = gamification.level;
          gamification.level = Math.floor(gamification.points / 100) + 1;
          
          if (gamification.level > oldLevel) {
            console.log(`🎉 ${userId}: Level up! ${oldLevel} → ${gamification.level}`);
          }
          
          await gamification.save();
          console.log(`✨ ${userId}: +${pointsEarned} XP, +${coinsEarned} coins`);
        }
        
        // Auto-check challenges for completion
        await ChallengeAssignmentService.autoCheckChallenges(userId, gamification);

        return {
          pointsEarned,
          coinsEarned,
          level: gamification.level,
          leveledUp: gamification.level > (gamification.level - Math.floor(pointsEarned / 100))
        };
      }

      return {
        pointsEarned,
        coinsEarned,
        level: gamification.level,
        leveledUp: gamification.level > (gamification.level - Math.floor(pointsEarned / 100))
      };
    } catch (error) {
      console.error('Gamification service error (transaction):', error);
      return null;
    }
  }

  // Update gamification after creating a budget
  async updateAfterBudget(userId, budget) {
    try {
      let gamification = await Gamification.findOne({ user: userId });
      
      if (!gamification) {
        gamification = await this.initializeGamification(userId);
      }

      let pointsEarned = 10;
      let coinsEarned = 5;

      // Check Budget Beginner achievement
      const budgets = await Budget.find({ user: userId });
      if (budgets.length === 1) {
        const achievement = gamification.achievements.find(a => a.title === 'Budget Beginner');
        if (achievement && !achievement.isUnlocked) {
          achievement.isUnlocked = true;
          achievement.unlockedDate = new Date();
          pointsEarned += achievement.points || 15;
          coinsEarned += 15;
          console.log(`🏆 ${userId}: Achievement unlocked - Budget Beginner`);
        }
      }

      // Update points and level
      const oldLevel = gamification.level;
      gamification.points += pointsEarned;
      gamification.coins = (gamification.coins || 0) + coinsEarned;
      gamification.level = Math.floor(gamification.points / 100) + 1;
      
      if (gamification.level > oldLevel) {
        console.log(`🎉 ${userId}: Level up! ${oldLevel} → ${gamification.level}`);
      }
      
      await gamification.save();
      console.log(`✨ ${userId}: +${pointsEarned} XP, +${coinsEarned} coins (Budget)`);

      return { pointsEarned, coinsEarned, level: gamification.level };
    } catch (error) {
      console.error('Gamification service error (budget):', error);
      return null;
    }
  }

  // Update gamification after savings goal action
  async updateAfterSavingsGoal(userId, savingsGoal) {
    try {
      let gamification = await Gamification.findOne({ user: userId });
      
      if (!gamification) {
        gamification = await this.initializeGamification(userId);
      }

      let pointsEarned = 15;
      let coinsEarned = 10;

      // Check for any savings challenge and update progress
      for (const challenge of gamification.challenges) {
        if (challenge.isCompleted) continue;
        if (challenge.category === 'savings' && !challenge.isCompleted) {
          // Increment progress
          challenge.currentValue = (challenge.currentValue || 0) + 1;
          challenge.targetValue = challenge.targetValue || 1;
          
          // Check if completed
          if (challenge.currentValue >= challenge.targetValue) {
            challenge.isCompleted = true;
            challenge.completedDate = new Date();
            pointsEarned += challenge.points || 15;
            coinsEarned += challenge.coins || 5;
            console.log(`✅ ${userId}: Challenge completed - ${challenge.title}`);
          }
        }
      }

      // Check Savings Starter achievement
      const goals = await SavingsGoal.find({ user: userId });
      if (goals.length === 1) {
        const achievement = gamification.achievements.find(a => a.title === 'Savings Starter');
        if (achievement && !achievement.isUnlocked) {
          achievement.isUnlocked = true;
          achievement.unlockedDate = new Date();
          pointsEarned += achievement.points || 15;
          coinsEarned += 15;
          console.log(`🏆 ${userId}: Achievement unlocked - Savings Starter`);
        }
      }

      // Update points and level
      const oldLevel = gamification.level;
      gamification.points += pointsEarned;
      gamification.coins = (gamification.coins || 0) + coinsEarned;
      gamification.level = Math.floor(gamification.points / 100) + 1;
      
      if (gamification.level > oldLevel) {
        console.log(`🎉 ${userId}: Level up! ${oldLevel} → ${gamification.level}`);
      }
      
      await gamification.save();
      console.log(`✨ ${userId}: +${pointsEarned} XP, +${coinsEarned} coins (Savings)`);

      return { pointsEarned, coinsEarned, level: gamification.level };
    } catch (error) {
      console.error('Gamification service error (savings):', error);
      return null;
    }
  }

  // Helper: Update tracking challenge progress
  async updateTrackingChallenge(gamification, transaction) {
    if (transaction.type !== 'expense') return;

    const challenge = gamification.challenges.find(c => 
      c.title === 'Track Your Spending' && !c.isCompleted
    );
    
    if (challenge) {
      challenge.currentValue = (challenge.currentValue || 0) + 1;
      challenge.targetValue = challenge.targetValue || 3;
      
      if (challenge.currentValue >= challenge.targetValue) {
        challenge.isCompleted = true;
        challenge.completedDate = new Date();
        gamification.points += challenge.points || 10;
        gamification.coins = (gamification.coins || 0) + 5;
        console.log(`✅ Challenge completed - Track Your Spending`);
      }
    }
  }

  // Initialize gamification for new user
  async initializeGamification(userId) {
    return await Gamification.create({
      user: userId,
      points: 0,
      level: 1,
      streak: 0,
      coins: 0,
      longestStreak: 0,
      financialHealthScore: 50,
      challenges: this.generateDefaultChallenges(),
      achievements: this.generateDefaultAchievements()
    });
  }

  // Generate default challenges
  generateDefaultChallenges() {
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
  generateDefaultAchievements() {
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
}

module.exports = new GamificationService();
