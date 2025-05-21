const Transaction = require('../models/Transaction');
const Budget = require('../models/Budget');
const SavingsGoal = require('../models/SavingsGoal');
const Wallet = require('../models/Wallet');
const User = require('../models/User');
const mongoose = require('mongoose');

// @desc    Get comprehensive financial statistics
// @route   GET /api/statistics/overview
// @access  Private
exports.getFinancialOverview = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get date range from query params or default to current month
    let startDate, endDate;
    
    if (req.query.startDate && req.query.endDate) {
      startDate = new Date(req.query.startDate);
      endDate = new Date(req.query.endDate);
      
      // Validate dates
      if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
        return res.status(400).json({
          success: false,
          message: 'Invalid date format. Please use YYYY-MM-DD format.'
        });
      }
    } else {
      const now = new Date();
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    }
    
    // Ensure endDate is at the end of the day for inclusive queries
    endDate.setHours(23, 59, 59, 999);
    
    // Get transactions for the period
    const transactions = await Transaction.find({
      user: userId,
      date: { $gte: startDate, $lte: endDate }
    }).sort({ date: 1 });
    
    // Get all transactions for overall statistics
    const allTransactions = await Transaction.find({ user: userId });
    
    // Get budgets
    const budgets = await Budget.find({ user: userId });
    
    // Get savings goals
    const savingsGoals = await SavingsGoal.find({ user: userId });
    
    // Get wallet
    const wallet = await Wallet.findOne({ user: userId });
    
    // Handle case where no data exists yet
    if (transactions.length === 0 && budgets.length === 0 && savingsGoals.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          isEmpty: true,
          message: 'No financial data available yet',
          dateRange: {
            startDate: startDate.toISOString(),
            endDate: endDate.toISOString()
          }
        }
      });
    }
    
    // Calculate income and expense totals for the period
    const incomeTransactions = transactions.filter(t => t.type === 'income');
    const expenseTransactions = transactions.filter(t => t.type === 'expense');
    
    const periodIncome = incomeTransactions.reduce((sum, t) => sum + t.amount, 0);
    const periodExpense = expenseTransactions.reduce((sum, t) => sum + t.amount, 0);
    const periodBalance = periodIncome - periodExpense;
    const periodSavingsRate = periodIncome > 0 ? ((periodIncome - periodExpense) / periodIncome) * 100 : 0;
    
    // Calculate all-time totals
    const totalIncome = allTransactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const totalExpense = allTransactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const totalBalance = totalIncome - totalExpense;
    const overallSavingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;
    
    // Generate category breakdown
    const categoryMap = {};
    transactions.forEach(transaction => {
      const key = `${transaction.type}:${transaction.category}`;
      if (!categoryMap[key]) {
        categoryMap[key] = {
          type: transaction.type,
          category: transaction.category,
          total: 0,
          count: 0,
          percentage: 0
        };
      }
      categoryMap[key].total += transaction.amount;
      categoryMap[key].count += 1;
    });
    
    // Calculate percentages for categories
    Object.values(categoryMap).forEach(category => {
      if (category.type === 'income') {
        category.percentage = periodIncome > 0 ? (category.total / periodIncome) * 100 : 0;
      } else {
        category.percentage = periodExpense > 0 ? (category.total / periodExpense) * 100 : 0;
      }
    });
    
    const categoryBreakdown = Object.values(categoryMap).sort((a, b) => b.total - a.total);
    
    // Generate daily data
    const dailyMap = {};
    const dateFormat = new Intl.DateTimeFormat('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' });
    
    transactions.forEach(transaction => {
      const dateStr = dateFormat.format(new Date(transaction.date));
      if (!dailyMap[dateStr]) {
        dailyMap[dateStr] = { date: dateStr, income: 0, expense: 0, balance: 0 };
      }
      if (transaction.type === 'income') {
        dailyMap[dateStr].income += transaction.amount;
      } else {
        dailyMap[dateStr].expense += transaction.amount;
      }
      dailyMap[dateStr].balance = dailyMap[dateStr].income - dailyMap[dateStr].expense;
    });
    
    // Fill in missing dates with zeros for continuous chart
    const dailyData = [];
    let currentDate = new Date(startDate);
    while (currentDate <= endDate) {
      const dateStr = dateFormat.format(currentDate);
      if (dailyMap[dateStr]) {
        dailyData.push(dailyMap[dateStr]);
      } else {
        dailyData.push({ date: dateStr, income: 0, expense: 0, balance: 0 });
      }
      currentDate.setDate(currentDate.getDate() + 1);
    }
    
    // Budget performance
    const budgetPerformance = budgets.map(budget => {
      const spent = budget.spent || 0;
      const remaining = Math.max(0, budget.limit - spent);
      const percentUsed = budget.limit > 0 ? (spent / budget.limit) * 100 : 0;
      
      return {
        id: budget._id,
        name: budget.name,
        category: budget.category,
        limit: budget.limit,
        spent,
        remaining,
        percentUsed,
        isExceeded: spent > budget.limit
      };
    });
    
    // Savings goals progress
    const savingsProgress = savingsGoals.map(goal => {
      const progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) * 100 : 0;
      const remaining = Math.max(0, goal.targetAmount - goal.currentAmount);
      
      return {
        id: goal._id,
        name: goal.name,
        category: goal.category,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        progress,
        remaining,
        isCompleted: goal.currentAmount >= goal.targetAmount,
        targetDate: goal.targetDate
      };
    });
    
    // Wallet summary
    const walletSummary = wallet ? {
      cashAmount: wallet.cashAmount,
      cardsTotalAmount: wallet.cardsTotalAmount,
      totalBalance: wallet.totalBalance,
      cardCount: wallet.cards.length
    } : {
      cashAmount: 0,
      cardsTotalAmount: 0,
      totalBalance: 0,
      cardCount: 0
    };
    
    // Calculate payment method breakdown
    const paymentMethodMap = {};
    transactions.forEach(transaction => {
      const method = transaction.paymentMethod || 'other';
      if (!paymentMethodMap[method]) {
        paymentMethodMap[method] = { method, total: 0, count: 0 };
      }
      paymentMethodMap[method].total += transaction.amount;
      paymentMethodMap[method].count += 1;
    });
    
    const paymentMethodBreakdown = Object.values(paymentMethodMap);
    
    res.status(200).json({
      success: true,
      data: {
        dateRange: {
          startDate: startDate.toISOString(),
          endDate: endDate.toISOString()
        },
        periodSummary: {
          income: periodIncome,
          expense: periodExpense,
          balance: periodBalance,
          savingsRate: periodSavingsRate,
          transactionCount: transactions.length
        },
        overallSummary: {
          income: totalIncome,
          expense: totalExpense,
          balance: totalBalance,
          savingsRate: overallSavingsRate,
          transactionCount: allTransactions.length
        },
        categoryBreakdown,
        dailyData,
        budgetPerformance,
        savingsProgress,
        walletSummary,
        paymentMethodBreakdown,
        isEmpty: false
      }
    });
  } catch (error) {
    console.error('Error in getFinancialOverview:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get monthly comparison statistics
// @route   GET /api/statistics/monthly-comparison
// @access  Private
exports.getMonthlyComparison = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get transactions for the last 12 months
    const twelveMonthsAgo = new Date();
    twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 12);
    twelveMonthsAgo.setDate(1); // Start from the 1st day of the month
    twelveMonthsAgo.setHours(0, 0, 0, 0);
    
    const transactions = await Transaction.find({
      user: userId,
      date: { $gte: twelveMonthsAgo }
    }).sort({ date: 1 });
    
    // Handle no transactions case
    if (transactions.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          monthlyData: [],
          isEmpty: true
        }
      });
    }
    
    // Generate monthly data
    const monthlyMap = {};
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Initialize all months in the range with zero values
    let currentDate = new Date(twelveMonthsAgo);
    const now = new Date();
    while (currentDate <= now) {
      const year = currentDate.getFullYear();
      const month = currentDate.getMonth();
      const monthKey = `${year}-${month + 1}`;
      const monthLabel = `${monthNames[month]} ${year}`;
      
      monthlyMap[monthKey] = {
        month: monthKey,
        label: monthLabel,
        income: 0,
        expense: 0,
        balance: 0,
        savingsRate: 0,
        transactionCount: 0,
        date: new Date(year, month, 1)
      };
      
      currentDate.setMonth(currentDate.getMonth() + 1);
    }
    
    // Fill in actual transaction data
    transactions.forEach(transaction => {
      const date = new Date(transaction.date);
      const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
      
      if (monthlyMap[monthKey]) {
        if (transaction.type === 'income') {
          monthlyMap[monthKey].income += transaction.amount;
        } else {
          monthlyMap[monthKey].expense += transaction.amount;
        }
        monthlyMap[monthKey].transactionCount += 1;
      }
    });
    
    // Calculate balance and savings rate for each month
    Object.values(monthlyMap).forEach(month => {
      month.balance = month.income - month.expense;
      month.savingsRate = month.income > 0 ? (month.balance / month.income) * 100 : 0;
    });
    
    const monthlyData = Object.values(monthlyMap).sort((a, b) => a.date - b.date);
    
    // Calculate month-over-month changes
    for (let i = 1; i < monthlyData.length; i++) {
      const current = monthlyData[i];
      const previous = monthlyData[i - 1];
      
      current.incomeChange = previous.income > 0 
        ? ((current.income - previous.income) / previous.income) * 100 
        : current.income > 0 ? 100 : 0;
        
      current.expenseChange = previous.expense > 0 
        ? ((current.expense - previous.expense) / previous.expense) * 100 
        : current.expense > 0 ? 100 : 0;
        
      current.balanceChange = previous.balance !== 0 
        ? ((current.balance - previous.balance) / Math.abs(previous.balance)) * 100 
        : current.balance !== 0 ? 100 : 0;
    }
    
    // Calculate category trends by month
    const categoryTrends = {};
    
    transactions.forEach(transaction => {
      const date = new Date(transaction.date);
      const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
      const category = transaction.category;
      const type = transaction.type;
      
      if (!categoryTrends[`${type}:${category}`]) {
        categoryTrends[`${type}:${category}`] = {
          category,
          type,
          months: {}
        };
      }
      
      if (!categoryTrends[`${type}:${category}`].months[monthKey]) {
        categoryTrends[`${type}:${category}`].months[monthKey] = 0;
      }
      
      categoryTrends[`${type}:${category}`].months[monthKey] += transaction.amount;
    });
    
    // Format category trends for response
    const formattedCategoryTrends = [];
    
    for (const key in categoryTrends) {
      const trend = categoryTrends[key];
      const monthlyTrend = [];
      
      for (const month of monthlyData) {
        monthlyTrend.push({
          month: month.label,
          amount: trend.months[month.month] || 0
        });
      }
      
      // Calculate total and average
      const total = monthlyTrend.reduce((sum, m) => sum + m.amount, 0);
      const nonZeroMonths = monthlyTrend.filter(m => m.amount > 0).length;
      const average = nonZeroMonths > 0 ? total / nonZeroMonths : 0;
      
      formattedCategoryTrends.push({
        category: trend.category,
        type: trend.type,
        total,
        average,
        monthlyData: monthlyTrend
      });
    }
    
    // Sort by total amount
    formattedCategoryTrends.sort((a, b) => b.total - a.total);
    
    res.status(200).json({
      success: true,
      data: {
        monthlyData,
        categoryTrends: formattedCategoryTrends,
        isEmpty: false
      }
    });
  } catch (error) {
    console.error('Error in getMonthlyComparison:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get financial insights and predictions
// @route   GET /api/statistics/insights
// @access  Private
exports.getFinancialInsights = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get all transactions
    const transactions = await Transaction.find({ user: userId }).sort({ date: 1 });
    
    // Get budgets
    const budgets = await Budget.find({ user: userId });
    
    // Get savings goals
    const savingsGoals = await SavingsGoal.find({ user: userId });
    
    // Handle no data case
    if (transactions.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          insights: [
            {
              type: 'info',
              title: 'No transaction data yet',
              description: 'Start adding your income and expenses to get personalized financial insights.'
            }
          ],
          isEmpty: true
        }
      });
    }
    
    const insights = [];
    
    // Calculate average monthly income and expenses
    const monthlyData = {};
    
    transactions.forEach(transaction => {
      const date = new Date(transaction.date);
      const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
      
      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = { income: 0, expense: 0 };
      }
      
      if (transaction.type === 'income') {
        monthlyData[monthKey].income += transaction.amount;
      } else {
        monthlyData[monthKey].expense += transaction.amount;
      }
    });
    
    const months = Object.values(monthlyData);
    const monthCount = months.length;
    
    if (monthCount > 0) {
      const totalIncome = months.reduce((sum, month) => sum + month.income, 0);
      const totalExpense = months.reduce((sum, month) => sum + month.expense, 0);
      
      const avgMonthlyIncome = totalIncome / monthCount;
      const avgMonthlyExpense = totalExpense / monthCount;
      const avgMonthlySavings = avgMonthlyIncome - avgMonthlyExpense;
      
      // Add income vs expense insight
      if (avgMonthlyIncome > 0) {
        const savingsRate = (avgMonthlySavings / avgMonthlyIncome) * 100;
        
        if (savingsRate < 0) {
          insights.push({
            type: 'warning',
            title: 'Spending Exceeds Income',
            description: `On average, you're spending ${Math.abs(savingsRate).toFixed(1)}% more than your income each month. Consider reducing expenses or increasing income.`
          });
        } else if (savingsRate < 10) {
          insights.push({
            type: 'warning',
            title: 'Low Savings Rate',
            description: `Your savings rate is ${savingsRate.toFixed(1)}%. Financial experts recommend saving at least 20% of your income.`
          });
        } else if (savingsRate >= 20) {
          insights.push({
            type: 'success',
            title: 'Healthy Savings Rate',
            description: `Great job! You're saving ${savingsRate.toFixed(1)}% of your income, which is above the recommended 20%.`
          });
        }
      }
      
      // Check for budget insights
      if (budgets.length > 0) {
        const exceededBudgets = budgets.filter(budget => budget.spent > budget.limit);
        const nearLimitBudgets = budgets.filter(budget => 
          budget.spent <= budget.limit && 
          budget.spent >= budget.limit * 0.9
        );
        
        if (exceededBudgets.length > 0) {
          insights.push({
            type: 'warning',
            title: 'Budget Exceeded',
            description: `You've exceeded your budget in ${exceededBudgets.length} ${exceededBudgets.length === 1 ? 'category' : 'categories'}: ${exceededBudgets.map(b => b.name).join(', ')}.`
          });
        }
        
        if (nearLimitBudgets.length > 0) {
          insights.push({
            type: 'info',
            title: 'Approaching Budget Limit',
            description: `You're close to your budget limit in ${nearLimitBudgets.length} ${nearLimitBudgets.length === 1 ? 'category' : 'categories'}: ${nearLimitBudgets.map(b => b.name).join(', ')}.`
          });
        }
      }
      
      // Check for savings goals insights
      if (savingsGoals.length > 0) {
        const completedGoals = savingsGoals.filter(goal => goal.currentAmount >= goal.targetAmount);
        const nearCompletionGoals = savingsGoals.filter(goal => 
          goal.currentAmount < goal.targetAmount && 
          goal.currentAmount >= goal.targetAmount * 0.9
        );
        
        if (completedGoals.length > 0) {
          insights.push({
            type: 'success',
            title: 'Savings Goals Achieved',
            description: `Congratulations! You've completed ${completedGoals.length} savings ${completedGoals.length === 1 ? 'goal' : 'goals'}: ${completedGoals.map(g => g.name).join(', ')}.`
          });
        }
        
        if (nearCompletionGoals.length > 0) {
          insights.push({
            type: 'info',
            title: 'Almost There!',
            description: `You're close to completing ${nearCompletionGoals.length} savings ${nearCompletionGoals.length === 1 ? 'goal' : 'goals'}: ${nearCompletionGoals.map(g => g.name).join(', ')}.`
          });
        }
        
        // Check for goals with upcoming deadlines
        const now = new Date();
        const upcomingDeadlineGoals = savingsGoals.filter(goal => 
          goal.targetDate && 
          goal.currentAmount < goal.targetAmount &&
          new Date(goal.targetDate) > now &&
          new Date(goal.targetDate) <= new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000) // Within 30 days
        );
        
        if (upcomingDeadlineGoals.length > 0) {
          insights.push({
            type: 'warning',
            title: 'Upcoming Goal Deadlines',
            description: `You have ${upcomingDeadlineGoals.length} savings ${upcomingDeadlineGoals.length === 1 ? 'goal' : 'goals'} with deadlines in the next 30 days: ${upcomingDeadlineGoals.map(g => g.name).join(', ')}.`
          });
        }
      }
      
      // Check for spending patterns
      if (months.length >= 3) {
        const recentMonths = Object.entries(monthlyData)
          .sort((a, b) => new Date(b[0]) - new Date(a[0]))
          .slice(0, 3)
          .map(([_, data]) => data);
        
        const avgRecentExpense = recentMonths.reduce((sum, month) => sum + month.expense, 0) / recentMonths.length;
        const avgPreviousExpense = (totalExpense - recentMonths.reduce((sum, month) => sum + month.expense, 0)) / (monthCount - recentMonths.length);
        
        const expenseChangePercent = ((avgRecentExpense - avgPreviousExpense) / avgPreviousExpense) * 100;
        
        if (expenseChangePercent > 20) {
          insights.push({
            type: 'warning',
            title: 'Increasing Expenses',
            description: `Your expenses have increased by ${expenseChangePercent.toFixed(1)}% in the last 3 months compared to your previous average.`
          });
        } else if (expenseChangePercent < -10) {
          insights.push({
            type: 'success',
            title: 'Decreasing Expenses',
            description: `Great job! Your expenses have decreased by ${Math.abs(expenseChangePercent).toFixed(1)}% in the last 3 months compared to your previous average.`
          });
        }
      }
      
      // Add prediction for future savings
      if (avgMonthlySavings > 0 && months.length >= 2) {
        const sixMonthSavings = avgMonthlySavings * 6;
        const oneYearSavings = avgMonthlySavings * 12;
        
        insights.push({
          type: 'info',
          title: 'Savings Projection',
          description: `At your current rate, you'll save approximately ${sixMonthSavings.toFixed(2)} in the next 6 months and ${oneYearSavings.toFixed(2)} in the next year.`
        });
      }
    }
    
    // Add general insights if we don't have many specific ones
    if (insights.length < 3) {
      // Check for category diversification
      const expenseCategories = {};
      transactions
        .filter(t => t.type === 'expense')
        .forEach(t => {
          if (!expenseCategories[t.category]) {
            expenseCategories[t.category] = 0;
          }
          expenseCategories[t.category] += t.amount;
        });
      
      const totalExpense = Object.values(expenseCategories).reduce((sum, amount) => sum + amount, 0);
      
      // Check if any category is more than 50% of total expenses
      for (const [category, amount] of Object.entries(expenseCategories)) {
        const percentage = (amount / totalExpense) * 100;
        if (percentage > 50) {
          insights.push({
            type: 'info',
            title: 'High Spending Category',
            description: `${category} makes up ${percentage.toFixed(1)}% of your total expenses. Consider if this aligns with your financial priorities.`
          });
          break;
        }
      }
      
      // Add general advice if still not enough insights
      if (insights.length < 3) {
        insights.push({
          type: 'info',
          title: 'Financial Health Tip',
          description: 'Consider setting up an emergency fund that covers 3-6 months of expenses for financial security.'
        });
      }
    }
    
    res.status(200).json({
      success: true,
      data: {
        insights,
        isEmpty: false
      }
    });
  } catch (error) {
    console.error('Error in getFinancialInsights:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// @desc    Get consolidated statistics data for dashboard
// @route   GET /api/statistics/dashboard
// @access  Private
  exports.getDashboardStatistics = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get current date and month boundaries
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    
    // Get previous month boundaries
    const startOfPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfPrevMonth = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
    
    // Initialize response object with safe defaults
    const response = {
      success: true,
      data: {
        summary: {
          currentBalance: 0,
          monthlyIncome: 0,
          monthlyExpense: 0,
          monthlySavings: 0,
          savingsRate: 0
        },
        trends: {
          income: [],
          expense: [],
          balance: []
        },
        budgets: {
          total: 0,
          used: 0,
          remaining: 0,
          categories: []
        },
        savingsGoals: {
          total: 0,
          current: 0,
          goals: []
        },
        recentTransactions: [],
        isEmpty: true
      }
    };
    
    // Get user data in parallel to improve performance
    const [
      currentMonthTransactions,
      previousMonthTransactions,
      allTransactions,
      wallet,
      budgets,
      savingsGoals,
      user
    ] = await Promise.all([
      Transaction.find({
        user: userId,
        date: { $gte: startOfMonth, $lte: endOfMonth }
      }).sort({ date: -1 }),
      Transaction.find({
        user: userId,
        date: { $gte: startOfPrevMonth, $lte: endOfPrevMonth }
      }),
      Transaction.find({ user: userId }).sort({ date: -1 }).limit(100),
      Wallet.findOne({ user: userId }),
      Budget.find({ user: userId }),
      SavingsGoal.find({ user: userId }),
      User.findById(userId).select('preferences')
    ]);
    
    // Check if we have any data at all
    const hasData = currentMonthTransactions.length > 0 || 
                   previousMonthTransactions.length > 0 || 
                   wallet || 
                   budgets.length > 0 || 
                   savingsGoals.length > 0;
    
    if (!hasData) {
      return res.status(200).json(response); // Return safe defaults
    }
    
    // Update isEmpty flag
    response.data.isEmpty = !hasData;
    
    // Get user's preferred currency
    const currency = user?.preferences?.currency || 'USD';
    
    // Calculate summary data
    if (wallet) {
      response.data.summary.currentBalance = wallet.totalBalance || 0;
    }
    
    const currentMonthIncome = currentMonthTransactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + (t.amount || 0), 0);
      
    const currentMonthExpense = currentMonthTransactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + (t.amount || 0), 0);
    
    response.data.summary.monthlyIncome = currentMonthIncome;
    response.data.summary.monthlyExpense = currentMonthExpense;
    response.data.summary.monthlySavings = currentMonthIncome - currentMonthExpense;
    response.data.summary.savingsRate = currentMonthIncome > 0 
      ? ((currentMonthIncome - currentMonthExpense) / currentMonthIncome * 100).toFixed(1) 
      : 0;
    
    // Calculate trends (last 6 months)
    const last6Months = [];
    for (let i = 5; i >= 0; i--) {
      const month = new Date(now.getFullYear(), now.getMonth() - i, 1);
      last6Months.push({
        month: month.toISOString().substring(0, 7), // YYYY-MM format
        label: month.toLocaleString('default', { month: 'short' })
      });
    }
    
    // Initialize trend data with safe defaults
    const trends = last6Months.map(m => ({
      month: m.month,
      label: m.label,
      income: 0,
      expense: 0,
      balance: 0
    }));
    
    // Populate trend data from transactions
    if (allTransactions.length > 0) {
      // Group transactions by month
      const transactionsByMonth = {};
      
      allTransactions.forEach(transaction => {
        const monthKey = transaction.date.toISOString().substring(0, 7); // YYYY-MM
        if (!transactionsByMonth[monthKey]) {
          transactionsByMonth[monthKey] = {
            income: 0,
            expense: 0
          };
        }
        
        if (transaction.type === 'income') {
          transactionsByMonth[monthKey].income += transaction.amount || 0;
        } else if (transaction.type === 'expense') {
          transactionsByMonth[monthKey].expense += transaction.amount || 0;
        }
      });
      
      // Update trend data
      trends.forEach(trend => {
        if (transactionsByMonth[trend.month]) {
          trend.income = transactionsByMonth[trend.month].income;
          trend.expense = transactionsByMonth[trend.month].expense;
          trend.balance = trend.income - trend.expense;
        }
      });
    }
    
    response.data.trends.income = trends.map(t => ({ label: t.label, value: t.income }));
    response.data.trends.expense = trends.map(t => ({ label: t.label, value: t.expense }));
    response.data.trends.balance = trends.map(t => ({ label: t.label, value: t.balance }));
    
    // Process budget data
    if (budgets.length > 0) {
      const currentMonthBudgets = budgets.filter(budget => {
        const budgetMonth = budget.month || now.getMonth() + 1;
        const budgetYear = budget.year || now.getFullYear();
        return budgetMonth === (now.getMonth() + 1) && budgetYear === now.getFullYear();
      });
      
      let totalBudget = 0;
      let totalUsed = 0;
      const budgetCategories = [];
      
      currentMonthBudgets.forEach(budget => {
        const amount = budget.amount || 0;
        const used = budget.spent || 0;
        
        totalBudget += amount;
        totalUsed += used;
        
        budgetCategories.push({
          id: budget._id,
          category: budget.category,
          amount: amount,
          used: used,
          remaining: amount - used,
          percentage: amount > 0 ? Math.min(100, (used / amount * 100).toFixed(1)) : 0
        });
      });
      
      response.data.budgets.total = totalBudget;
      response.data.budgets.used = totalUsed;
      response.data.budgets.remaining = totalBudget - totalUsed;
      response.data.budgets.categories = budgetCategories;
    }
    
    // Process savings goals
    if (savingsGoals.length > 0) {
      let totalTarget = 0;
      let totalCurrent = 0;
      const goals = [];
      
      savingsGoals.forEach(goal => {
        const targetAmount = goal.targetAmount || 0;
        const currentAmount = goal.currentAmount || 0;
        
        totalTarget += targetAmount;
        totalCurrent += currentAmount;
        
        goals.push({
          id: goal._id,
          name: goal.name,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          deadline: goal.deadline,
          progress: targetAmount > 0 ? Math.min(100, (currentAmount / targetAmount * 100).toFixed(1)) : 0
        });
      });
      
      response.data.savingsGoals.total = totalTarget;
      response.data.savingsGoals.current = totalCurrent;
      response.data.savingsGoals.goals = goals;
    }
    
    // Add recent transactions
    response.data.recentTransactions = currentMonthTransactions
      .slice(0, 5)
      .map(transaction => ({
        id: transaction._id,
        date: transaction.date,
        description: transaction.description,
        amount: transaction.amount,
        type: transaction.type,
        category: transaction.category
      }));
    
    // Add currency info
    response.data.currency = currency;
    
    res.status(200).json(response);
  } catch (error) {
    console.error('Error in getDashboardStatistics:', error);
    // Return a safe response even on error
    res.status(500).json({
      success: false,
      message: 'Error retrieving dashboard statistics',
      error: error.message,
      data: {
        summary: {
          currentBalance: 0,
          monthlyIncome: 0,
          monthlyExpense: 0,
          monthlySavings: 0,
          savingsRate: 0
        },
        trends: {
          income: [],
          expense: [],
          balance: []
        },
        budgets: {
          total: 0,
          used: 0,
          remaining: 0,
          categories: []
        },
        savingsGoals: {
          total: 0,
          current: 0,
          goals: []
        },
        recentTransactions: [],
        isEmpty: true,
        isError: true
      }
    });
  }
};

// @desc    Get category statistics
// @route   GET /api/statistics/categories
// @access  Private
exports.getCategoryStatistics = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get date range from query params or default to current month
    let startDate, endDate;
    
    if (req.query.startDate && req.query.endDate) {
      startDate = new Date(req.query.startDate);
      endDate = new Date(req.query.endDate);
      
      // Validate dates
      if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
        return res.status(400).json({
          success: false,
          message: 'Invalid date format. Please use YYYY-MM-DD format.',
          data: { categories: [], isEmpty: true }
        });
      }
    } else {
      const now = new Date();
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    }
    
    // Get transactions for the period
    const transactions = await Transaction.find({
      user: userId,
      date: { $gte: startDate, $lte: endDate }
    });
    
    // Handle case where no data exists
    if (transactions.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          income: [],
          expense: [],
          isEmpty: true,
          dateRange: {
            startDate: startDate.toISOString(),
            endDate: endDate.toISOString()
          }
        }
      });
    }
    
    // Separate income and expense transactions
    const incomeTransactions = transactions.filter(t => t.type === 'income');
    const expenseTransactions = transactions.filter(t => t.type === 'expense');
    
    // Calculate totals
    const totalIncome = incomeTransactions.reduce((sum, t) => sum + (t.amount || 0), 0);
    const totalExpense = expenseTransactions.reduce((sum, t) => sum + (t.amount || 0), 0);
    
    // Group by category
    const incomeCategories = {};
    const expenseCategories = {};
    
    // Process income categories
    incomeTransactions.forEach(transaction => {
      const category = transaction.category || 'Other';
      if (!incomeCategories[category]) {
        incomeCategories[category] = {
          category,
          amount: 0,
          count: 0,
          percentage: 0
        };
      }
      incomeCategories[category].amount += transaction.amount || 0;
      incomeCategories[category].count += 1;
    });
    
    // Process expense categories
    expenseTransactions.forEach(transaction => {
      const category = transaction.category || 'Other';
      if (!expenseCategories[category]) {
        expenseCategories[category] = {
          category,
          amount: 0,
          count: 0,
          percentage: 0
        };
      }
      expenseCategories[category].amount += transaction.amount || 0;
      expenseCategories[category].count += 1;
    });
    
    // Calculate percentages
    Object.values(incomeCategories).forEach(item => {
      item.percentage = totalIncome > 0 ? (item.amount / totalIncome * 100).toFixed(1) : 0;
    });
    
    Object.values(expenseCategories).forEach(item => {
      item.percentage = totalExpense > 0 ? (item.amount / totalExpense * 100).toFixed(1) : 0;
    });
    
    // Convert to arrays and sort by amount
    const incomeArray = Object.values(incomeCategories).sort((a, b) => b.amount - a.amount);
    const expenseArray = Object.values(expenseCategories).sort((a, b) => b.amount - a.amount);
    
    res.status(200).json({
      success: true,
      data: {
        income: incomeArray,
        expense: expenseArray,
        totalIncome,
        totalExpense,
        isEmpty: false,
        dateRange: {
          startDate: startDate.toISOString(),
          endDate: endDate.toISOString()
        }
      }
    });
  } catch (error) {
    console.error('Error in getCategoryStatistics:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
      data: {
        income: [],
        expense: [],
        isEmpty: true,
        isError: true
      }
    });
  }
};
