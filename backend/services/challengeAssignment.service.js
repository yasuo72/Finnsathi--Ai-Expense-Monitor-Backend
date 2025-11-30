const Gamification = require('../models/Gamification');
const challengePool = require('../data/challengePool');

/**
 * Challenge Assignment Service
 * Assigns 5 random challenges daily to each user
 * Ensures variety and difficulty balance
 */

class ChallengeAssignmentService {
  
  /**
   * Assign 5 random challenges to a user for today
   * @param {String} userId - User ID
   * @param {Object} gamification - User's gamification data
   * @returns {Array} - Array of 5 challenges
   */
  async assignDailyChallenges(userId, gamification) {
    try {
      // Use userId and date as seed for pseudo-random selection
      const today = new Date();
      const dateStr = `${today.getFullYear()}-${today.getMonth()}-${today.getDate()}`;
      const seed = this.hashCode(userId + dateStr);
      
      // Filter available challenges
      const availableChallenges = challengePool.filter(c => 
        c.type === 'daily' || c.type === 'weekend' || c.type === 'weekly'
      );
      
      // Shuffle with seed for consistent randomization per user per day
      const shuffled = this.seededShuffle([...availableChallenges], seed);
      
      // Select 5 challenges with difficulty balance
      // Aim for: 2 easy, 2 medium, 1 hard
      const selected = this.balanceDifficulty(shuffled, 5);
      
      // Convert to challenge format with expiry at 5 AM next day
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(5, 0, 0, 0); // Reset at 5 AM
      
      const challenges = selected.map(challenge => ({
        title: challenge.title,
        description: challenge.description,
        points: challenge.xp,
        coins: challenge.coins,
        difficulty: challenge.difficulty,
        type: challenge.type,
        category: challenge.category,
        icon: challenge.icon,
        isCompleted: false,
        currentValue: 0,
        targetValue: challenge.targetValue,
        expiryDate: tomorrow,
        challengeId: challenge.id // Reference to master challenge
      }));
      
      console.log(`✨ Assigned ${challenges.length} random challenges to user ${userId}`);
      console.log(`Difficulties: ${challenges.map(c => c.difficulty).join(', ')}`);
      
      return challenges;
    } catch (error) {
      console.error('Error assigning challenges:', error);
      return this.getDefaultChallenges();
    }
  }
  
  /**
   * Balance challenge selection by difficulty
   * @param {Array} challenges - Shuffled challenges
   * @param {Number} count - Number to select
   * @returns {Array} - Balanced selection
   */
  balanceDifficulty(challenges, count) {
    const easy = challenges.filter(c => c.difficulty === 'easy');
    const medium = challenges.filter(c => c.difficulty === 'medium');
    const hard = challenges.filter(c => c.difficulty === 'hard');
    
    const selected = [];
    
    // Try to get 2 easy
    selected.push(...easy.slice(0, 2));
    
    // Try to get 2 medium
    selected.push(...medium.slice(0, 2));
    
    // Try to get 1 hard
    selected.push(...hard.slice(0, 1));
    
    // If we don't have enough, fill with remaining
    if (selected.length < count) {
      const remaining = challenges.filter(c => !selected.includes(c));
      selected.push(...remaining.slice(0, count - selected.length));
    }
    
    return selected.slice(0, count);
  }
  
  /**
   * Seeded shuffle for consistent randomization
   * @param {Array} array - Array to shuffle
   * @param {Number} seed - Seed number
   * @returns {Array} - Shuffled array
   */
  seededShuffle(array, seed) {
    const shuffled = [...array];
    let random = this.seededRandom(seed);
    
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    
    return shuffled;
  }
  
  /**
   * Seeded random number generator
   * @param {Number} seed - Seed
   * @returns {Function} - Random function
   */
  seededRandom(seed) {
    let value = seed;
    return () => {
      value = (value * 9301 + 49297) % 233280;
      return value / 233280;
    };
  }
  
  /**
   * Generate hash code from string
   * @param {String} str - String to hash
   * @returns {Number} - Hash code
   */
  hashCode(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
  }
  
  /**
   * Check if user needs new challenges (daily refresh)
   * @param {Object} gamification - User's gamification data
   * @returns {Boolean} - True if needs refresh
   */
  needsChallengeRefresh(gamification) {
    if (!gamification.challenges || gamification.challenges.length === 0) {
      return true;
    }
    
    const now = new Date();
    
    // Check if any challenge has expired
    const hasExpiredChallenges = gamification.challenges.some(c => {
      const expiryDate = new Date(c.expiryDate);
      return expiryDate <= now;
    });
    
    // Refresh if challenges have expired OR if less than 5 challenges
    return hasExpiredChallenges || gamification.challenges.length < 5;
  }
  
  /**
   * Auto-check challenge completion for a user
   * @param {String} userId - User ID
   * @param {Object} gamification - User's gamification data
   * @returns {Object} - Updated stats
   */
  async autoCheckChallenges(userId, gamification) {
    try {
      let totalXP = 0;
      let totalCoins = 0;
      let completedCount = 0;
      
      for (const challenge of gamification.challenges) {
        if (challenge.isCompleted) continue;
        
        // Find challenge in pool
        const masterChallenge = challengePool.find(c => c.id === challenge.challengeId);
        if (!masterChallenge || !masterChallenge.checkCompletion) continue;
        
        // Check completion
        const currentValue = await masterChallenge.checkCompletion(userId, gamification);
        challenge.currentValue = currentValue;
        
        // If completed
        if (currentValue >= challenge.targetValue && !challenge.isCompleted) {
          challenge.isCompleted = true;
          challenge.completedDate = new Date();
          totalXP += challenge.points;
          totalCoins += challenge.coins || 0;
          completedCount++;
          
          console.log(`✅ ${userId}: Challenge completed - ${challenge.title} (+${challenge.points} XP, +${challenge.coins} coins)`);
        }
      }
      
      // Update points if any challenges completed
      if (completedCount > 0) {
        gamification.points += totalXP;
        gamification.coins = (gamification.coins || 0) + totalCoins;
        
        // Check level up
        const oldLevel = gamification.level;
        gamification.level = Math.floor(gamification.points / 100) + 1;
        
        if (gamification.level > oldLevel) {
          console.log(`🎉 ${userId}: Level up! ${oldLevel} → ${gamification.level}`);
        }
        
        await gamification.save();
      }
      
      return {
        completedCount,
        xpEarned: totalXP,
        coinsEarned: totalCoins,
        level: gamification.level
      };
    } catch (error) {
      console.error('Error auto-checking challenges:', error);
      return { completedCount: 0, xpEarned: 0, coinsEarned: 0 };
    }
  }
  
  /**
   * Award XP and coins when user completes a savings goal
   * @param {Object} savingsGoal - Completed savings goal
   * @returns {Object} - XP and coins earned
   */
  calculateGoalReward(savingsGoal) {
    const targetAmount = savingsGoal.targetAmount || 1000;
    
    // Base reward
    let xp = 50;
    let coins = 30;
    
    // Scale based on goal amount
    if (targetAmount >= 10000) {
      xp = 100;
      coins = 75;
    } else if (targetAmount >= 5000) {
      xp = 75;
      coins = 50;
    }
    
    // Bonus for early completion
    if (savingsGoal.targetDate) {
      const daysRemaining = Math.floor(
        (new Date(savingsGoal.targetDate) - new Date()) / (1000 * 60 * 60 * 24)
      );
      if (daysRemaining > 0) {
        xp += Math.min(50, daysRemaining); // Up to 50 bonus XP
        coins += Math.min(25, Math.floor(daysRemaining / 2));
      }
    }
    
    return { xp, coins };
  }
  
  /**
   * Get default challenges (fallback)
   * @returns {Array} - Default challenges
   */
  getDefaultChallenges() {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(5, 0, 0, 0); // Reset at 5 AM
    
    return [
      {
        title: 'Track Your Spending',
        description: 'Add 3 expenses to track your spending',
        points: 10,
        coins: 5,
        difficulty: 'easy',
        type: 'daily',
        category: 'tracking',
        isCompleted: false,
        expiryDate: tomorrow,
        icon: 'receipt',
        currentValue: 0,
        targetValue: 3,
        challengeId: 'track_expenses_3'
      },
      {
        title: 'Daily Saver',
        description: 'Add money to any savings goal',
        points: 15,
        coins: 10,
        difficulty: 'easy',
        type: 'daily',
        category: 'savings',
        isCompleted: false,
        expiryDate: tomorrow,
        icon: 'savings',
        currentValue: 0,
        targetValue: 1,
        challengeId: 'save_daily'
      },
      {
        title: 'Budget Keeper',
        description: 'Stay under budget in all categories today',
        points: 25,
        coins: 15,
        difficulty: 'medium',
        type: 'daily',
        category: 'budgeting',
        isCompleted: false,
        expiryDate: tomorrow,
        icon: 'check_circle',
        currentValue: 0,
        targetValue: 1,
        challengeId: 'stay_under_budget'
      }
    ];
  }
}

module.exports = new ChallengeAssignmentService();
