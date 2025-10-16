/**
 * Master Challenge Pool - 35 Unique Challenges
 * Difficulty Levels: easy (5-10 XP), medium (15-25 XP), hard (30-50 XP)
 */

const challengePool = [
  // ==================== TRACKING CHALLENGES (10) ====================
  {
    id: 'track_expenses_3',
    title: 'Daily Tracker',
    description: 'Record 3 expenses today',
    difficulty: 'easy',
    xp: 10,
    coins: 5,
    category: 'tracking',
    type: 'daily',
    targetValue: 3,
    icon: 'receipt',
    checkCompletion: async (userId, gamification) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        type: 'expense',
        date: { $gte: today }
      });
      return count;
    }
  },
  {
    id: 'track_expenses_10',
    title: 'Expense Master',
    description: 'Record 10 expenses today',
    difficulty: 'hard',
    xp: 35,
    coins: 20,
    category: 'tracking',
    type: 'daily',
    targetValue: 10,
    icon: 'trending_down',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        type: 'expense',
        date: { $gte: today }
      });
      return count;
    }
  },
  {
    id: 'track_income',
    title: 'Income Recorder',
    description: 'Add 2 income sources today',
    difficulty: 'medium',
    xp: 20,
    coins: 10,
    category: 'tracking',
    type: 'daily',
    targetValue: 2,
    icon: 'trending_up',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        type: 'income',
        date: { $gte: today }
      });
      return count;
    }
  },
  {
    id: 'categorize_expenses',
    title: 'Category Champion',
    description: 'Add expenses in 3 different categories today',
    difficulty: 'medium',
    xp: 20,
    coins: 12,
    category: 'tracking',
    type: 'daily',
    targetValue: 3,
    icon: 'category',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const categories = await Transaction.distinct('category', {
        user: userId,
        type: 'expense',
        date: { $gte: today }
      });
      return categories.length;
    }
  },
  {
    id: 'morning_tracker',
    title: 'Early Bird',
    description: 'Record an expense before 9 AM',
    difficulty: 'medium',
    xp: 15,
    coins: 8,
    category: 'tracking',
    type: 'daily',
    targetValue: 1,
    icon: 'wb_sunny',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const morning = new Date(today);
      morning.setHours(9, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        type: 'expense',
        date: { $gte: today, $lt: morning }
      });
      return count > 0 ? 1 : 0;
    }
  },
  {
    id: 'add_notes',
    title: 'Detail Master',
    description: 'Add descriptions to 5 transactions',
    difficulty: 'medium',
    xp: 18,
    coins: 10,
    category: 'tracking',
    type: 'daily',
    targetValue: 5,
    icon: 'notes',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        date: { $gte: today },
        description: { $exists: true, $ne: '' }
      });
      return count;
    }
  },
  {
    id: 'zero_expense_day',
    title: 'No Spend Day',
    description: 'Don\'t record any expenses today',
    difficulty: 'hard',
    xp: 40,
    coins: 25,
    category: 'tracking',
    type: 'daily',
    targetValue: 1,
    icon: 'money_off',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      const count = await Transaction.countDocuments({
        user: userId,
        type: 'expense',
        date: { $gte: today, $lt: tomorrow }
      });
      return count === 0 ? 1 : 0;
    }
  },
  {
    id: 'small_expense_tracker',
    title: 'Penny Pincher',
    description: 'Track 5 expenses under ₹100',
    difficulty: 'easy',
    xp: 12,
    coins: 6,
    category: 'tracking',
    type: 'daily',
    targetValue: 5,
    icon: 'attach_money',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        type: 'expense',
        amount: { $lt: 100 },
        date: { $gte: today }
      });
      return count;
    }
  },
  {
    id: 'receipt_warrior',
    title: 'Receipt Warrior',
    description: 'Add receipts/attachments to 3 transactions',
    difficulty: 'medium',
    xp: 22,
    coins: 15,
    category: 'tracking',
    type: 'daily',
    targetValue: 3,
    icon: 'receipt_long',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        date: { $gte: today },
        attachment: { $exists: true, $ne: null }
      });
      return count;
    }
  },
  {
    id: 'weekly_review',
    title: 'Weekly Reviewer',
    description: 'Review all transactions from past 7 days',
    difficulty: 'medium',
    xp: 25,
    coins: 15,
    category: 'tracking',
    type: 'weekly',
    targetValue: 1,
    icon: 'event_note',
    checkCompletion: async () => 0 // Manual completion
  },

  // ==================== SAVINGS CHALLENGES (8) ====================
  {
    id: 'save_daily',
    title: 'Daily Saver',
    description: 'Add money to any savings goal',
    difficulty: 'easy',
    xp: 15,
    coins: 10,
    category: 'savings',
    type: 'daily',
    targetValue: 1,
    icon: 'savings',
    checkCompletion: async (userId) => {
      const SavingsGoal = require('../models/SavingsGoal');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const goals = await SavingsGoal.find({ user: userId });
      let totalContributions = 0;
      goals.forEach(goal => {
        const todayContributions = goal.contributions.filter(c => 
          new Date(c.date) >= today
        );
        totalContributions += todayContributions.length;
      });
      return totalContributions > 0 ? 1 : 0;
    }
  },
  {
    id: 'save_100',
    title: 'Century Saver',
    description: 'Save ₹100 or more in one transaction',
    difficulty: 'medium',
    xp: 20,
    coins: 12,
    category: 'savings',
    type: 'daily',
    targetValue: 1,
    icon: 'account_balance',
    checkCompletion: async (userId) => {
      const SavingsGoal = require('../models/SavingsGoal');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const goals = await SavingsGoal.find({ user: userId });
      let hasLargeContribution = false;
      goals.forEach(goal => {
        const todayContributions = goal.contributions.filter(c => 
          new Date(c.date) >= today && c.amount >= 100
        );
        if (todayContributions.length > 0) hasLargeContribution = true;
      });
      return hasLargeContribution ? 1 : 0;
    }
  },
  {
    id: 'save_500',
    title: 'Power Saver',
    description: 'Save ₹500 or more in one day',
    difficulty: 'hard',
    xp: 45,
    coins: 30,
    category: 'savings',
    type: 'daily',
    targetValue: 1,
    icon: 'stars',
    checkCompletion: async (userId) => {
      const SavingsGoal = require('../models/SavingsGoal');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const goals = await SavingsGoal.find({ user: userId });
      let totalSaved = 0;
      goals.forEach(goal => {
        const todayContributions = goal.contributions.filter(c => 
          new Date(c.date) >= today
        );
        todayContributions.forEach(c => totalSaved += c.amount);
      });
      return totalSaved >= 500 ? 1 : 0;
    }
  },
  {
    id: 'create_goal',
    title: 'Goal Setter',
    description: 'Create a new savings goal',
    difficulty: 'easy',
    xp: 10,
    coins: 8,
    category: 'savings',
    type: 'daily',
    targetValue: 1,
    icon: 'flag',
    checkCompletion: async (userId) => {
      const SavingsGoal = require('../models/SavingsGoal');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await SavingsGoal.countDocuments({
        user: userId,
        createdAt: { $gte: today }
      });
      return count;
    }
  },
  {
    id: 'save_3_goals',
    title: 'Multi-Goal Champion',
    description: 'Contribute to 3 different savings goals',
    difficulty: 'hard',
    xp: 50,
    coins: 35,
    category: 'savings',
    type: 'daily',
    targetValue: 3,
    icon: 'workspaces',
    checkCompletion: async (userId) => {
      const SavingsGoal = require('../models/SavingsGoal');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const goals = await SavingsGoal.find({ user: userId });
      let goalsContributedTo = 0;
      goals.forEach(goal => {
        const todayContributions = goal.contributions.filter(c => 
          new Date(c.date) >= today
        );
        if (todayContributions.length > 0) goalsContributedTo++;
      });
      return goalsContributedTo;
    }
  },
  {
    id: 'goal_25_percent',
    title: 'Quarter Master',
    description: 'Reach 25% of any savings goal',
    difficulty: 'medium',
    xp: 25,
    coins: 15,
    category: 'savings',
    type: 'milestone',
    targetValue: 1,
    icon: 'show_chart',
    checkCompletion: async (userId) => {
      const SavingsGoal = require('../models/SavingsGoal');
      const goals = await SavingsGoal.find({ user: userId });
      const has25Percent = goals.some(g => 
        (g.currentAmount / g.targetAmount) >= 0.25
      );
      return has25Percent ? 1 : 0;
    }
  },
  {
    id: 'goal_50_percent',
    title: 'Halfway Hero',
    description: 'Reach 50% of any savings goal',
    difficulty: 'hard',
    xp: 40,
    coins: 25,
    category: 'savings',
    type: 'milestone',
    targetValue: 1,
    icon: 'timeline',
    checkCompletion: async (userId) => {
      const SavingsGoal = require('../models/SavingsGoal');
      const goals = await SavingsGoal.find({ user: userId });
      const has50Percent = goals.some(g => 
        (g.currentAmount / g.targetAmount) >= 0.50
      );
      return has50Percent ? 1 : 0;
    }
  },
  {
    id: 'complete_goal',
    title: 'Goal Crusher',
    description: 'Complete a savings goal',
    difficulty: 'hard',
    xp: 100,
    coins: 75,
    category: 'savings',
    type: 'milestone',
    targetValue: 1,
    icon: 'emoji_events',
    checkCompletion: async (userId) => {
      const SavingsGoal = require('../models/SavingsGoal');
      const count = await SavingsGoal.countDocuments({
        user: userId,
        currentAmount: { $gte: { $expr: '$targetAmount' } },
        completedDate: { $exists: true }
      });
      return count > 0 ? 1 : 0;
    }
  },

  // ==================== BUDGETING CHALLENGES (9) ====================
  {
    id: 'create_budget',
    title: 'Budget Planner',
    description: 'Create a new budget category',
    difficulty: 'easy',
    xp: 10,
    coins: 7,
    category: 'budgeting',
    type: 'daily',
    targetValue: 1,
    icon: 'account_balance_wallet',
    checkCompletion: async (userId) => {
      const Budget = require('../models/Budget');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Budget.countDocuments({
        user: userId,
        createdAt: { $gte: today }
      });
      return count;
    }
  },
  {
    id: 'stay_under_budget',
    title: 'Budget Keeper',
    description: 'Stay under budget in all categories today',
    difficulty: 'medium',
    xp: 25,
    coins: 15,
    category: 'budgeting',
    type: 'daily',
    targetValue: 1,
    icon: 'check_circle',
    checkCompletion: async (userId) => {
      const Budget = require('../models/Budget');
      const budgets = await Budget.find({ user: userId });
      if (budgets.length === 0) return 0;
      const allUnderBudget = budgets.every(b => b.spent <= b.limit);
      return allUnderBudget ? 1 : 0;
    }
  },
  {
    id: 'budget_50_percent',
    title: 'Halfway Safe',
    description: 'Keep all budgets under 50% usage',
    difficulty: 'hard',
    xp: 35,
    coins: 20,
    category: 'budgeting',
    type: 'daily',
    targetValue: 1,
    icon: 'trending_down',
    checkCompletion: async (userId) => {
      const Budget = require('../models/Budget');
      const budgets = await Budget.find({ user: userId });
      if (budgets.length === 0) return 0;
      const allUnder50 = budgets.every(b => (b.spent / b.limit) <= 0.50);
      return allUnder50 ? 1 : 0;
    }
  },
  {
    id: 'create_3_budgets',
    title: 'Budget Master',
    description: 'Have 3 active budget categories',
    difficulty: 'medium',
    xp: 20,
    coins: 12,
    category: 'budgeting',
    type: 'milestone',
    targetValue: 1,
    icon: 'playlist_add_check',
    checkCompletion: async (userId) => {
      const Budget = require('../models/Budget');
      const count = await Budget.countDocuments({ user: userId });
      return count >= 3 ? 1 : 0;
    }
  },
  {
    id: 'update_budget',
    title: 'Budget Optimizer',
    description: 'Update a budget limit today',
    difficulty: 'easy',
    xp: 8,
    coins: 5,
    category: 'budgeting',
    type: 'daily',
    targetValue: 1,
    icon: 'tune',
    checkCompletion: async () => 0 // Track via manual completion
  },
  {
    id: 'zero_overspend',
    title: 'Perfect Balance',
    description: 'End the week with no budget overspending',
    difficulty: 'hard',
    xp: 50,
    coins: 30,
    category: 'budgeting',
    type: 'weekly',
    targetValue: 1,
    icon: 'balance',
    checkCompletion: async (userId) => {
      const Budget = require('../models/Budget');
      const budgets = await Budget.find({ user: userId });
      const noOverspend = budgets.every(b => b.spent <= b.limit);
      return noOverspend ? 1 : 0;
    }
  },
  {
    id: 'reduce_budget',
    title: 'Thrifty Planner',
    description: 'Reduce a budget limit by at least 10%',
    difficulty: 'medium',
    xp: 22,
    coins: 13,
    category: 'budgeting',
    type: 'daily',
    targetValue: 1,
    icon: 'arrow_downward',
    checkCompletion: async () => 0 // Manual tracking
  },
  {
    id: 'budget_food_under',
    title: 'Food Budget Pro',
    description: 'Stay under food/dining budget today',
    difficulty: 'medium',
    xp: 18,
    coins: 10,
    category: 'budgeting',
    type: 'daily',
    targetValue: 1,
    icon: 'restaurant',
    checkCompletion: async (userId) => {
      const Budget = require('../models/Budget');
      const Transaction = require('../models/Transaction');
      
      const foodBudget = await Budget.findOne({
        user: userId,
        category: { $in: ['Food', 'Dining', 'Groceries'] }
      });
      
      if (!foodBudget) return 0;
      
      return foodBudget.spent <= foodBudget.limit ? 1 : 0;
    }
  },
  {
    id: 'monthly_budget_review',
    title: 'Monthly Reviewer',
    description: 'Review and adjust all budgets this month',
    difficulty: 'easy',
    xp: 15,
    coins: 10,
    category: 'budgeting',
    type: 'monthly',
    targetValue: 1,
    icon: 'event',
    checkCompletion: async () => 0 // Manual
  },

  // ==================== SPENDING CONTROL CHALLENGES (8) ====================
  {
    id: 'spend_under_200',
    title: 'Frugal Day',
    description: 'Keep total daily spending under ₹200',
    difficulty: 'medium',
    xp: 20,
    coins: 12,
    category: 'spending',
    type: 'daily',
    targetValue: 1,
    icon: 'wallet',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const expenses = await Transaction.find({
        user: userId,
        type: 'expense',
        date: { $gte: today }
      });
      const total = expenses.reduce((sum, t) => sum + t.amount, 0);
      return total <= 200 ? 1 : 0;
    }
  },
  {
    id: 'no_impulse_buy',
    title: 'Impulse Breaker',
    description: 'No purchases over ₹500 today',
    difficulty: 'medium',
    xp: 25,
    coins: 15,
    category: 'spending',
    type: 'daily',
    targetValue: 1,
    icon: 'block',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        type: 'expense',
        amount: { $gt: 500 },
        date: { $gte: today }
      });
      return count === 0 ? 1 : 0;
    }
  },
  {
    id: 'cash_only',
    title: 'Cash Master',
    description: 'Use only cash payment method today',
    difficulty: 'hard',
    xp: 30,
    coins: 18,
    category: 'spending',
    type: 'daily',
    targetValue: 1,
    icon: 'payments',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const transactions = await Transaction.find({
        user: userId,
        type: 'expense',
        date: { $gte: today }
      });
      if (transactions.length === 0) return 0;
      const allCash = transactions.every(t => 
        t.paymentMethod && t.paymentMethod.toLowerCase() === 'cash'
      );
      return allCash ? 1 : 0;
    }
  },
  {
    id: 'no_food_delivery',
    title: 'Home Chef',
    description: 'No food delivery expenses today',
    difficulty: 'medium',
    xp: 22,
    coins: 14,
    category: 'spending',
    type: 'daily',
    targetValue: 1,
    icon: 'home',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const count = await Transaction.countDocuments({
        user: userId,
        type: 'expense',
        category: { $in: ['Food Delivery', 'Dining', 'Food'] },
        date: { $gte: today }
      });
      return count === 0 ? 1 : 0;
    }
  },
  {
    id: 'reduce_daily_spending',
    title: 'Spending Reducer',
    description: 'Spend 20% less than yesterday',
    difficulty: 'hard',
    xp: 40,
    coins: 25,
    category: 'spending',
    type: 'daily',
    targetValue: 1,
    icon: 'trending_down',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      
      const todayExpenses = await Transaction.find({
        user: userId,
        type: 'expense',
        date: { $gte: today }
      });
      const yesterdayExpenses = await Transaction.find({
        user: userId,
        type: 'expense',
        date: { $gte: yesterday, $lt: today }
      });
      
      const todayTotal = todayExpenses.reduce((sum, t) => sum + t.amount, 0);
      const yesterdayTotal = yesterdayExpenses.reduce((sum, t) => sum + t.amount, 0);
      
      if (yesterdayTotal === 0) return 0;
      return todayTotal <= (yesterdayTotal * 0.8) ? 1 : 0;
    }
  },
  {
    id: 'weekend_saver',
    title: 'Weekend Warrior',
    description: 'Spend less than ₹500 this weekend',
    difficulty: 'hard',
    xp: 45,
    coins: 28,
    category: 'spending',
    type: 'weekend',
    targetValue: 1,
    icon: 'weekend',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const now = new Date();
      const dayOfWeek = now.getDay();
      
      // Only check if it's Sunday evening
      if (dayOfWeek !== 0) return 0;
      
      const saturday = new Date(now);
      saturday.setDate(saturday.getDate() - 1);
      saturday.setHours(0, 0, 0, 0);
      
      const expenses = await Transaction.find({
        user: userId,
        type: 'expense',
        date: { $gte: saturday }
      });
      
      const total = expenses.reduce((sum, t) => sum + t.amount, 0);
      return total <= 500 ? 1 : 0;
    }
  },
  {
    id: 'essential_only',
    title: 'Essentials Only',
    description: 'Only spend on essential categories today',
    difficulty: 'hard',
    xp: 35,
    coins: 20,
    category: 'spending',
    type: 'daily',
    targetValue: 1,
    icon: 'shopping_basket',
    checkCompletion: async (userId) => {
      const Transaction = require('../models/Transaction');
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const essentialCategories = ['Groceries', 'Healthcare', 'Transport', 'Utilities'];
      
      const transactions = await Transaction.find({
        user: userId,
        type: 'expense',
        date: { $gte: today }
      });
      
      if (transactions.length === 0) return 0;
      
      const allEssential = transactions.every(t => 
        essentialCategories.includes(t.category)
      );
      return allEssential ? 1 : 0;
    }
  },
  {
    id: 'compare_prices',
    title: 'Price Comparer',
    description: 'Add comparison notes to 3 purchases',
    difficulty: 'medium',
    xp: 18,
    coins: 11,
    category: 'spending',
    type: 'daily',
    targetValue: 3,
    icon: 'compare',
    checkCompletion: async () => 0 // Manual tracking
  }
];

module.exports = challengePool;
