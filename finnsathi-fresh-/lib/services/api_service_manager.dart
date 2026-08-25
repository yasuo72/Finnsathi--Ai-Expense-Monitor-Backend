import 'package:flutter/material.dart';
import '../models/finance_models.dart';
import '../app_config.dart';
import 'transaction_service.dart';
import 'budget_service.dart';
import 'savings_goal_service.dart';
import 'wallet_api_service.dart';
import 'statistics_service.dart';
import 'chatbot_api_service.dart';
import 'notification_api_service.dart';
import 'prediction_api_service.dart';

/// A service manager that integrates all API services and provides methods
/// to interact with the backend. This class follows the ChangeNotifier pattern
/// to allow widgets to rebuild when data changes.
class ApiServiceManager extends ChangeNotifier {
  // Singleton instance
  static final ApiServiceManager _instance = ApiServiceManager._internal();

  // Factory constructor
  factory ApiServiceManager() => _instance;

  // Private constructor
  ApiServiceManager._internal();

  // API configuration
  bool _useMockData = AppConfig.useMockData;
  String _apiBaseUrl = AppConfig.apiBaseUrl;

  // Data storage
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  Map<String, dynamic> _walletData = {};
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotificationsCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get useMockData => _useMockData;
  String get apiBaseUrl => _apiBaseUrl;
  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  Map<String, dynamic> get walletData => _walletData;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Update API settings
  Future<void> updateSettings({
    required bool useMockData,
    required String apiBaseUrl,
  }) async {
    _useMockData = useMockData;
    _apiBaseUrl = apiBaseUrl;

    // Update AppConfig
    AppConfig.useMockData = useMockData;
    AppConfig.apiBaseUrl = apiBaseUrl;

    // Save settings to persistent storage
    await AppConfig.saveSettings();

    // Notify listeners to rebuild widgets
    notifyListeners();

    // Reinitialize data with new settings
    await initializeData();
  }

  // Initialize data
  Future<void> initializeData() async {
    _setLoading(true);
    _setError(null);

    try {
      // Load all data in parallel
      await Future.wait([
        _loadTransactions(),
        _loadBudgets(),
        _loadSavingsGoals(),
        _loadWalletData(),
        _loadNotifications(),
      ]);
    } catch (e) {
      _setError('Failed to initialize data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh only notifications (used by notification screens and badges)
  Future<void> refreshNotificationsOnly() async {
    await _loadNotifications();
  }

  // TRANSACTION METHODS

  Future<void> _loadTransactions() async {
    try {
      _transactions = await TransactionService.getAllTransactions();
      notifyListeners();
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<bool> addTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      final newTransaction = await TransactionService.createTransaction(
        transaction,
      );
      if (newTransaction != null) {
        _transactions.add(newTransaction);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to add transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      final updatedTransaction = await TransactionService.updateTransaction(
        transaction,
      );
      if (updatedTransaction != null) {
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index] = updatedTransaction;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _setError('Failed to update transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTransaction(String id) async {
    _setLoading(true);
    try {
      final success = await TransactionService.deleteTransaction(id);
      if (success) {
        _transactions.removeWhere((t) => t.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // BUDGET METHODS

  Future<void> _loadBudgets() async {
    try {
      _budgets = await BudgetService.getAllBudgets();
      notifyListeners();
    } catch (e) {
      print('Error loading budgets: $e');
    }
  }

  Future<bool> addBudget(Budget budget) async {
    _setLoading(true);
    try {
      final newBudget = await BudgetService.createBudget(budget);
      if (newBudget != null) {
        _budgets.add(newBudget);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to add budget: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    _setLoading(true);
    try {
      final updatedBudget = await BudgetService.updateBudget(budget);
      if (updatedBudget != null) {
        final index = _budgets.indexWhere((b) => b.id == budget.id);
        if (index != -1) {
          _budgets[index] = updatedBudget;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _setError('Failed to update budget: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteBudget(String id) async {
    _setLoading(true);
    try {
      final success = await BudgetService.deleteBudget(id);
      if (success) {
        _budgets.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete budget: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // SAVINGS GOAL METHODS

  Future<void> _loadSavingsGoals() async {
    try {
      _savingsGoals = await SavingsGoalService.getAllSavingsGoals();
      notifyListeners();
    } catch (e) {
      print('Error loading savings goals: $e');
    }
  }

  Future<bool> addSavingsGoal(SavingsGoal savingsGoal) async {
    _setLoading(true);
    try {
      final newSavingsGoal = await SavingsGoalService.createSavingsGoal(
        savingsGoal,
      );
      if (newSavingsGoal != null) {
        _savingsGoals.add(newSavingsGoal);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to add savings goal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateSavingsGoal(SavingsGoal savingsGoal) async {
    _setLoading(true);
    try {
      final updatedSavingsGoal = await SavingsGoalService.updateSavingsGoal(
        savingsGoal,
      );
      if (updatedSavingsGoal != null) {
        final index = _savingsGoals.indexWhere((g) => g.id == savingsGoal.id);
        if (index != -1) {
          _savingsGoals[index] = updatedSavingsGoal;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _setError('Failed to update savings goal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSavingsGoal(String id) async {
    _setLoading(true);
    try {
      final success = await SavingsGoalService.deleteSavingsGoal(id);
      if (success) {
        _savingsGoals.removeWhere((g) => g.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete savings goal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMoneyToSavingsGoal(String id, double amount) async {
    _setLoading(true);
    try {
      final updatedGoal = await SavingsGoalService.addMoneyToSavingsGoal(
        id,
        amount,
      );
      if (updatedGoal != null) {
        final index = _savingsGoals.indexWhere((g) => g.id == id);
        if (index != -1) {
          _savingsGoals[index] = updatedGoal;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _setError('Failed to add money to savings goal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // WALLET METHODS

  Future<void> _loadWalletData() async {
    try {
      final walletBalance = await WalletApiService.getWalletBalance();
      if (walletBalance != null) {
        _walletData = walletBalance;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading wallet data: $e');
    }
  }

  Future<bool> addMoneyToWallet(double amount, String source) async {
    _setLoading(true);
    try {
      final success = await WalletApiService.addMoneyToWallet(amount, source);
      if (success) {
        await _loadWalletData(); // Reload wallet data
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to add money to wallet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> withdrawFromWallet(double amount, String destination) async {
    _setLoading(true);
    try {
      final success = await WalletApiService.withdrawFromWallet(
        amount,
        destination,
      );
      if (success) {
        await _loadWalletData(); // Reload wallet data
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to withdraw from wallet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> transferMoney(
    String recipientId,
    double amount,
    String note,
  ) async {
    _setLoading(true);
    try {
      final success = await WalletApiService.transferMoney(
        recipientId,
        amount,
        note,
      );
      if (success) {
        await _loadWalletData(); // Reload wallet data
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to transfer money: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NOTIFICATION METHODS

  Future<void> _loadNotifications() async {
    try {
      _notifications = await NotificationApiService.getAllNotifications();
      _unreadNotificationsCount = await NotificationApiService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<bool> markNotificationAsRead(String id) async {
    try {
      final success = await NotificationApiService.markAsRead(id);
      if (success) {
        await _loadNotifications(); // Reload notifications
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final success = await NotificationApiService.markAllAsRead();
      if (success) {
        await _loadNotifications(); // Reload notifications
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // CHATBOT METHODS

  Future<Map<String, dynamic>> sendChatbotMessage(String message) async {
    try {
      return await ChatbotApiService.sendMessage(message);
    } catch (e) {
      print('Error sending chatbot message: $e');
      return {
        'intent': 'error',
        'score': 0.0,
        'answer': 'An error occurred while communicating with the chatbot.',
        'entities': [],
      };
    }
  }

  // Gemini expense analysis
  Future<String> analyzeExpenses(List<Map<String, dynamic>> expenses) async {
    try {
      return await ChatbotApiService.analyzeExpenses(expenses);
    } catch (e) {
      print('Error analyzing expenses via Gemini: $e');
      return 'Analysis failed.';
    }
  }

  // STATISTICS METHODS

  Future<Map<String, dynamic>> getSpendingByCategory({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await StatisticsService.getSpendingByCategory(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error getting spending by category: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getIncomeVsExpenses({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await StatisticsService.getIncomeVsExpenses(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error getting income vs expenses: $e');
      return {};
    }
  }

  // PREDICTION METHODS

  Future<Map<String, dynamic>> getSpendingPrediction() async {
    try {
      return await PredictionApiService.getSpendingPrediction();
    } catch (e) {
      print('Error getting spending prediction: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getSavingsGoalPrediction(String goalId) async {
    try {
      return await PredictionApiService.getSavingsGoalPrediction(goalId);
    } catch (e) {
      print('Error getting savings goal prediction: $e');
      return {};
    }
  }

  // Helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await initializeData();
  }
}
