const Notification = require('../models/Notification');
const User = require('../models/User');
const { createSystemNotification } = require('../controllers/notification.controller');

/**
 * Service for handling notifications across the application
 */
class NotificationService {
  /**
   * Send a budget alert notification
   * @param {string} userId - User ID
   * @param {Object} budget - Budget object
   * @param {number} percentUsed - Percentage of budget used
   */
  static async sendBudgetAlert(userId, budget, percentUsed) {
    try {
      // Check if user has budget reminders enabled
      const user = await User.findById(userId);
      if (!user || (user.preferences && user.preferences.budgetReminders === false)) {
        return null;
      }
      
      let title, message, type;
      
      if (percentUsed >= 100) {
        title = 'Budget Exceeded';
        message = `Your ${budget.category} budget of ${budget.limit} has been exceeded.`;
        type = 'error';
      } else if (percentUsed >= 90) {
        title = 'Budget Almost Depleted';
        message = `You've used ${percentUsed.toFixed(0)}% of your ${budget.category} budget.`;
        type = 'warning';
      } else if (percentUsed >= 75) {
        title = 'Budget Reminder';
        message = `You've used ${percentUsed.toFixed(0)}% of your ${budget.category} budget.`;
        type = 'warning';
      }
      
      if (title && message) {
        return await createSystemNotification(userId, title, message, {
          type: 'budget',
          icon: 'budget',
          color: percentUsed >= 100 ? '#FF4D4F' : '#FAAD14',
          relatedItemId: budget._id,
          relatedItemType: 'budget',
          actionLink: `/budgets/${budget._id}`
        });
      }
      
      return null;
    } catch (error) {
      console.error('Error sending budget alert:', error);
      return null;
    }
  }
  
  /**
   * Send a savings goal notification
   * @param {string} userId - User ID
   * @param {Object} goal - Savings goal object
   * @param {string} eventType - Type of event ('achieved', 'near_completion', 'deadline_approaching')
   */
  static async sendSavingsGoalNotification(userId, goal, eventType) {
    try {
      // Check if user has savings reminders enabled
      const user = await User.findById(userId);
      if (!user || (user.preferences && user.preferences.savingsReminders === false)) {
        return null;
      }
      
      let title, message, type, icon, color;
      
      switch (eventType) {
        case 'achieved':
          title = 'Goal Achieved!';
          message = `Congratulations! You've reached your savings goal: ${goal.name}.`;
          type = 'success';
          icon = 'trophy';
          color = '#52C41A';
          break;
        case 'near_completion':
          const percentComplete = (goal.currentAmount / goal.targetAmount) * 100;
          title = 'Almost There!';
          message = `You're ${percentComplete.toFixed(0)}% of the way to your ${goal.name} goal.`;
          type = 'info';
          icon = 'target';
          color = '#4A6CF7';
          break;
        case 'deadline_approaching':
          const daysLeft = Math.ceil((new Date(goal.targetDate) - new Date()) / (1000 * 60 * 60 * 24));
          title = 'Goal Deadline Approaching';
          message = `Your ${goal.name} goal deadline is in ${daysLeft} days.`;
          type = 'warning';
          icon = 'clock';
          color = '#FAAD14';
          break;
        default:
          return null;
      }
      
      return await createSystemNotification(userId, title, message, {
        type: 'goal',
        icon,
        color,
        relatedItemId: goal._id,
        relatedItemType: 'savingsGoal',
        actionLink: `/savings-goals/${goal._id}`
      });
    } catch (error) {
      console.error('Error sending savings goal notification:', error);
      return null;
    }
  }
  
  /**
   * Send a transaction notification
   * @param {string} userId - User ID
   * @param {Object} transaction - Transaction object
   * @param {string} eventType - Type of event ('created', 'large_expense', 'recurring')
   */
  static async sendTransactionNotification(userId, transaction, eventType) {
    try {
      // Check if user has transaction alerts enabled
      const user = await User.findById(userId);
      if (!user || (user.preferences && user.preferences.transactionAlerts === false)) {
        return null;
      }
      
      let title, message, type, icon, color;
      
      switch (eventType) {
        case 'created':
          title = `New ${transaction.type.charAt(0).toUpperCase() + transaction.type.slice(1)} Recorded`;
          message = `A ${transaction.type} of ${transaction.amount} for ${transaction.category} has been recorded.`;
          type = transaction.type === 'income' ? 'success' : 'info';
          icon = transaction.type === 'income' ? 'income' : 'expense';
          color = transaction.type === 'income' ? '#52C41A' : '#4A6CF7';
          break;
        case 'large_expense':
          title = 'Large Expense Detected';
          message = `You've made a large expense of ${transaction.amount} for ${transaction.category}.`;
          type = 'warning';
          icon = 'alert';
          color = '#FAAD14';
          break;
        case 'recurring':
          title = 'Recurring Transaction';
          message = `Your recurring ${transaction.type} of ${transaction.amount} for ${transaction.category} has been recorded.`;
          type = 'info';
          icon = 'repeat';
          color = '#4A6CF7';
          break;
        default:
          return null;
      }
      
      return await createSystemNotification(userId, title, message, {
        type: 'transaction',
        icon,
        color,
        relatedItemId: transaction._id,
        relatedItemType: 'transaction',
        actionLink: `/transactions/${transaction._id}`
      });
    } catch (error) {
      console.error('Error sending transaction notification:', error);
      return null;
    }
  }
  
  /**
   * Send a weekly financial summary notification
   * @param {string} userId - User ID
   * @param {Object} summary - Financial summary data
   */
  static async sendWeeklySummary(userId, summary) {
    try {
      // Check if user has weekly reports enabled
      const user = await User.findById(userId);
      if (!user || (user.preferences && user.preferences.weeklyReports === false)) {
        return null;
      }
      
      const { income, expenses, savings, topExpenseCategory } = summary;
      const savingsRate = income > 0 ? ((income - expenses) / income * 100).toFixed(1) : 0;
      
      const title = 'Your Weekly Financial Summary';
      const message = `Income: ${income}, Expenses: ${expenses}, Savings: ${savings} (${savingsRate}%). Top expense category: ${topExpenseCategory}.`;
      
      return await createSystemNotification(userId, title, message, {
        type: 'info',
        icon: 'chart',
        color: '#4A6CF7',
        relatedItemType: 'system',
        actionLink: '/statistics'
      });
    } catch (error) {
      console.error('Error sending weekly summary:', error);
      return null;
    }
  }
  
  /**
   * Send a security notification
   * @param {string} userId - User ID
   * @param {string} eventType - Type of event ('login', 'password_change', 'profile_update')
   * @param {Object} details - Additional details
   */
  static async sendSecurityNotification(userId, eventType, details = {}) {
    try {
      // Check if user has login notifications enabled for login events
      if (eventType === 'login') {
        const user = await User.findById(userId);
        if (!user || (user.security && user.security.loginNotifications === false)) {
          return null;
        }
      }
      
      let title, message, icon, color;
      
      switch (eventType) {
        case 'login':
          const device = details.device || 'Unknown device';
          const location = details.location || 'Unknown location';
          title = 'New Login Detected';
          message = `Your account was accessed from ${device} in ${location} at ${new Date().toLocaleString()}.`;
          icon = 'login';
          color = '#4A6CF7';
          break;
        case 'password_change':
          title = 'Password Changed';
          message = `Your password was changed at ${new Date().toLocaleString()}.`;
          icon = 'lock';
          color = '#52C41A';
          break;
        case 'profile_update':
          title = 'Profile Updated';
          message = `Your profile information was updated at ${new Date().toLocaleString()}.`;
          icon = 'user';
          color = '#4A6CF7';
          break;
        default:
          return null;
      }
      
      return await createSystemNotification(userId, title, message, {
        type: 'system',
        icon,
        color,
        relatedItemType: 'user',
        actionLink: '/profile/security'
      });
    } catch (error) {
      console.error('Error sending security notification:', error);
      return null;
    }
  }
  
  /**
   * Clean up old notifications
   * This can be run as a scheduled job
   */
  static async cleanupOldNotifications() {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const result = await Notification.deleteMany({
        isRead: true,
        createdAt: { $lt: thirtyDaysAgo }
      });
      
      console.log(`Cleaned up ${result.deletedCount} old notifications`);
      return result.deletedCount;
    } catch (error) {
      console.error('Error cleaning up old notifications:', error);
      return 0;
    }
  }
}

module.exports = NotificationService;
