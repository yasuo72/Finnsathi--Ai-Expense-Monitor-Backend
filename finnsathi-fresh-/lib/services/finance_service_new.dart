import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_models.dart';
import 'package:flutter/material.dart';

class FinanceService extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  double _balance = 0.0;
  
  // Public getters
  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  double get balance => _balance;
  
  // Dashboard summary metrics
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);
      
  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);
  
  double get savingsRate => totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;
  
  // Initialize with stored data
  Future<void> init() async {
    await _loadData();
    await _calculateBalance();
  }
  
  // Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    await _updateTransactionsStorage();
    await _calculateBalance();
    notifyListeners();
  }
  
  // Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      await _updateTransactionsStorage();
      await _calculateBalance();
      notifyListeners();
    }
  }
  
  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _updateTransactionsStorage();
    await _calculateBalance();
    notifyListeners();
  }
  
  // Get transactions for a specific date range
  List<Transaction> getTransactionsForDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) => 
      t.date.isAfter(start.subtract(const Duration(days: 1))) && 
      t.date.isBefore(end.add(const Duration(days: 1))))
      .toList();
  }
  
  // Get transactions for current month
  List<Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getTransactionsForDateRange(startOfMonth, endOfMonth);
  }
  
  // Add a new budget
  Future<void> addBudget(Budget budget) async {
    _budgets.add(budget);
    await _updateBudgetsStorage();
    notifyListeners();
  }
  
  // Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = budget;
      await _updateBudgetsStorage();
      notifyListeners();
    }
  }
  
  // Delete a budget
  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    await _updateBudgetsStorage();
    notifyListeners();
  }
  
  // Add a new savings goal
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    _savingsGoals.add(goal);
    await _updateSavingsGoalsStorage();
    notifyListeners();
  }
  
  // Update an existing savings goal
  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final index = _savingsGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _savingsGoals[index] = goal;
      await _updateSavingsGoalsStorage();
      notifyListeners();
    }
  }
  
  // Delete a savings goal
  Future<void> deleteSavingsGoal(String id) async {
    _savingsGoals.removeWhere((g) => g.id == id);
    await _updateSavingsGoalsStorage();
    notifyListeners();
  }
  
  // Add money to a savings goal
  Future<void> addToSavingsGoal(String goalId, double amount) async {
    final index = _savingsGoals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final goal = _savingsGoals[index];
      final updatedGoal = goal.copyWith(
        currentAmount: goal.currentAmount + amount
      );
      _savingsGoals[index] = updatedGoal;
      
      // Create a transaction for this savings contribution
      final transaction = Transaction(
        title: "Contribution to ${goal.title}",
        amount: amount,
        date: DateTime.now(),
        category: TransactionCategory.other_expense,
        type: TransactionType.expense,
      );
      await addTransaction(transaction);
      
      await _updateSavingsGoalsStorage();
      notifyListeners();
    }
  }
  
  // Get category-wise spending for a date range
  Map<TransactionCategory, double> getCategorySpending(DateTime start, DateTime end) {
    final transactions = getTransactionsForDateRange(start, end)
        .where((t) => t.type == TransactionType.expense)
        .toList();
    
    final Map<TransactionCategory, double> result = {};
    
    for (final transaction in transactions) {
      result[transaction.category] = (result[transaction.category] ?? 0) + transaction.amount;
    }
    
    return result;
  }
  
  // Get daily transactions data for a date range (for charts)
  List<MapEntry<DateTime, double>> getDailyTransactionData(
    DateTime start, DateTime end, TransactionType type) {
    // Create a map with all days in range initialized to 0
    final Map<DateTime, double> dailyData = {};
    
    // Initialize with all days
    for (var d = start; d.isBefore(end.add(const Duration(days: 1))); 
        d = d.add(const Duration(days: 1))) {
      final normalizedDate = DateTime(d.year, d.month, d.day);
      dailyData[normalizedDate] = 0;
    }
    
    // Add transaction amounts to corresponding days
    final transactions = getTransactionsForDateRange(start, end)
        .where((t) => t.type == type)
        .toList();
    
    for (final transaction in transactions) {
      final normalizedDate = DateTime(
          transaction.date.year, transaction.date.month, transaction.date.day);
      dailyData[normalizedDate] = (dailyData[normalizedDate] ?? 0) + transaction.amount;
    }
    
    // Convert to sorted list of MapEntry
    final result = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return result;
  }
  
  // Load all data from storage
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load transactions
    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      final List<dynamic> decodedList = jsonDecode(transactionsJson);
      _transactions = decodedList
          .map((item) => Transaction.fromJson(item))
          .toList();
    } else {
      // Start with empty transactions
      _transactions = [];
      await _updateTransactionsStorage();
    }
    
    // Load budgets
    final budgetsJson = prefs.getString('budgets');
    if (budgetsJson != null) {
      final List<dynamic> decodedList = jsonDecode(budgetsJson);
      _budgets = decodedList
          .map((item) => Budget.fromJson(item))
          .toList();
    } else {
      // Start with empty budgets
      _budgets = [];
      await _updateBudgetsStorage();
    }
    
    // Load savings goals
    final savingsGoalsJson = prefs.getString('savingsGoals');
    if (savingsGoalsJson != null) {
      final List<dynamic> decodedList = jsonDecode(savingsGoalsJson);
      _savingsGoals = decodedList
          .map((item) => SavingsGoal.fromJson(item))
          .toList();
    } else {
      // Start with empty savings goals
      _savingsGoals = [];
      await _updateSavingsGoalsStorage();
    }
  }
  
  // Calculate current balance
  Future<void> _calculateBalance() async {
    double income = 0;
    double expense = 0;
    
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }
    
    _balance = income - expense;
  }
  
  // Update transactions in storage
  Future<void> _updateTransactionsStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _transactions.map((t) => t.toJson()).toList();
    await prefs.setString('transactions', jsonEncode(jsonList));
  }
  
  // Update budgets in storage
  Future<void> _updateBudgetsStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _budgets.map((b) => b.toJson()).toList();
    await prefs.setString('budgets', jsonEncode(jsonList));
  }
  
  // Update savings goals in storage
  Future<void> _updateSavingsGoalsStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _savingsGoals.map((g) => g.toJson()).toList();
    await prefs.setString('savingsGoals', jsonEncode(jsonList));
  }
}
