import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_models.dart';
import 'package:flutter/material.dart';
import 'transaction_service.dart';
import 'budget_service.dart';
import 'savings_goal_service.dart';
import '../app_config.dart';

class FinanceService extends ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];
  double _balance = 0.0;

  // Reference to wallet service (will be set by wallet service)
  // This avoids circular dependency
  double _walletCashAmount = 0.0;
  double _walletCardsAmount = 0.0;

  // Public getters
  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get savingsGoals => _savingsGoals;

  // Balance calculation
  // This returns the transaction-based balance (income - expenses)
  double get transactionBalance => _balance;

  // This includes both transaction balance and wallet amounts
  double get balance => _balance + _walletCashAmount + _walletCardsAmount;

  // Wallet-specific balances
  double get walletCashAmount => _walletCashAmount;
  double get walletCardsAmount => _walletCardsAmount;

  // Dashboard summary metrics
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get savingsRate =>
      totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;

  // Initialize with stored data
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final loginSuccessful = prefs.getBool('login_successful') ?? false;
    final loginTimestamp = prefs.getInt('login_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // If login was successful in the last 10 seconds, force refresh data
    if (loginSuccessful && (now - loginTimestamp < 10000)) {
      print('🔄 Recent login detected, forcing data refresh');
      await _loadData(forceRefresh: true);
      // Reset the login flag
      await prefs.setBool('login_successful', false);
    } else {
      await _loadData();
    }

    await _calculateBalance();
  }

  // Force refresh data from backend - call this after login
  Future<void> forceRefreshData() async {
    print('🔄 Force refreshing finance data from backend');

    // Clear the force_data_refresh flag if it was set
    final prefs = await SharedPreferences.getInstance();
    final shouldForceRefresh = prefs.getBool('force_data_refresh') ?? false;

    if (shouldForceRefresh) {
      print('⚠️ Force refresh flag detected - ensuring complete data refresh');
      // Clear local savings goals to force a complete refresh from backend
      await prefs.remove('savingsGoals');

      // Clear the flag after processing
      await prefs.setBool('force_data_refresh', false);
    }

    // Load all data with forced refresh
    await _loadData(forceRefresh: true);
    await _calculateBalance();

    // Double-check savings goals specifically
    print('🔍 Double-checking savings goals data');
    try {
      final backendSavingsGoals = await SavingsGoalService.getAllSavingsGoals();
      if (backendSavingsGoals.isNotEmpty) {
        print(
          '✅ Verified ${backendSavingsGoals.length} savings goals from backend',
        );

        // Keep only local goals that aren't on the backend yet
        final localOnlySavingsGoals =
            _savingsGoals.where((g) => g.id.startsWith('local_')).toList();

        // Replace all savings goals with backend ones + local-only ones
        _savingsGoals = [...backendSavingsGoals, ...localOnlySavingsGoals];

        // Update local storage with the merged list
        await _updateSavingsGoalsStorage();
      }
    } catch (e) {
      print('❌ Error double-checking savings goals: $e');
    }

    notifyListeners();
  }

  // Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Generate a temporary ID if needed
      if (transaction.id.isEmpty) {
        transaction = transaction.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Add to local storage first for immediate UI update
      _transactions.add(transaction);
      await _updateTransactionsStorage();
      await _calculateBalance();
      notifyListeners();

      // Then save to backend
      if (!AppConfig.useMockData) {
        print('Saving transaction to backend: ${transaction.title}');
        final savedTransaction = await TransactionService.createTransaction(
          transaction,
        );

        if (savedTransaction != null) {
          // Replace the local transaction with the one from the server (which has a proper ID)
          final index = _transactions.indexWhere((t) => t.id == transaction.id);
          if (index != -1) {
            _transactions[index] = savedTransaction;
            await _updateTransactionsStorage();
            notifyListeners();
          }
          print(
            'Transaction saved to backend successfully with ID: ${savedTransaction.id}',
          );

          // Backend auto-checks gamification challenges - frontend will refresh on next load
          print('💡 Gamification challenges will auto-update on backend');
        } else {
          print('Failed to save transaction to backend, but kept locally');
        }
      }
    } catch (e) {
      print('Error adding transaction: $e');
      // Keep the transaction locally even if backend save fails
    }
  }

  // Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        // Update locally first for immediate UI update
        _transactions[index] = transaction;
        await _updateTransactionsStorage();
        await _calculateBalance();
        notifyListeners();

        // Then update on backend if it's not a local-only transaction
        if (!AppConfig.useMockData && !transaction.id.startsWith('local_')) {
          print('Updating transaction on backend: ${transaction.title}');
          final updatedTransaction = await TransactionService.updateTransaction(
            transaction,
          );

          if (updatedTransaction != null) {
            // Replace with the updated version from server
            _transactions[index] = updatedTransaction;
            await _updateTransactionsStorage();
            notifyListeners();
            print('Transaction updated on backend successfully');
          } else {
            print('Failed to update transaction on backend, but kept locally');
          }
        }
      }
    } catch (e) {
      print('Error updating transaction: $e');
      // Keep the local update even if backend update fails
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    try {
      // Check if this is a local-only transaction
      final isLocalTransaction = id.startsWith('local_');

      // Delete locally first for immediate UI update
      _transactions.removeWhere((t) => t.id == id);
      await _updateTransactionsStorage();
      await _calculateBalance();
      notifyListeners();

      // Then delete from backend if it's not a local-only transaction
      if (!AppConfig.useMockData && !isLocalTransaction) {
        print('Deleting transaction from backend: $id');
        final success = await TransactionService.deleteTransaction(id);

        if (success) {
          print('Transaction deleted from backend successfully');
        } else {
          print(
            'Failed to delete transaction from backend, but removed locally',
          );
        }
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      // Transaction is still removed locally even if backend deletion fails
    }
  }

  // Get transactions for a specific date range
  List<Transaction> getTransactionsForDateRange(DateTime start, DateTime end) {
    return _transactions
        .where(
          (t) =>
              t.date.isAfter(start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(end.add(const Duration(days: 1))),
        )
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
    try {
      // Generate a temporary ID if needed
      if (budget.id.isEmpty) {
        budget = budget.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Add to local storage first for immediate UI update
      _budgets.add(budget);
      await _updateBudgetsStorage();
      notifyListeners();

      // Then save to backend
      if (!AppConfig.useMockData) {
        print('💰 Saving budget to backend: ${budget.title}');

        // Make sure we have a valid auth token before trying to save to backend
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token == null || token.isEmpty) {
          print('⚠️ No auth token found. Budget will only be saved locally.');
          return;
        }

        final savedBudget = await BudgetService.createBudget(budget);

        if (savedBudget != null) {
          // Replace the local budget with the one from the server (which has a proper ID)
          final index = _budgets.indexWhere((b) => b.id == budget.id);
          if (index != -1) {
            _budgets[index] = savedBudget;
            await _updateBudgetsStorage();
            notifyListeners();
          }
          print(
            '✅ Budget saved to backend successfully with ID: ${savedBudget.id}',
          );
        } else {
          print('❌ Failed to save budget to backend, but kept locally');
        }
      }
    } catch (e) {
      print('❌ Error adding budget: $e');
      // Keep the budget locally even if backend save fails
    }
  }

  // Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    try {
      // Find the index of the budget to update
      final index = _budgets.indexWhere((b) => b.id == budget.id);

      if (index != -1) {
        // Update in local storage first for immediate UI update
        _budgets[index] = budget;
        await _updateBudgetsStorage();
        notifyListeners();

        // Then update in backend
        if (!AppConfig.useMockData && !budget.id.startsWith('local_')) {
          print('💰 Updating budget in backend: ${budget.title}');

          // Make sure we have a valid auth token before trying to update in backend
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token == null || token.isEmpty) {
            print(
              '⚠️ No auth token found. Budget will only be updated locally.',
            );
            return;
          }

          final updatedBudget = await BudgetService.updateBudget(budget);

          if (updatedBudget != null) {
            // Replace with the updated version from the server
            _budgets[index] = updatedBudget;
            await _updateBudgetsStorage();
            notifyListeners();
            print(
              '✅ Budget updated in backend successfully: ${updatedBudget.id}',
            );
          } else {
            print(
              '❌ Failed to update budget in backend, but kept local changes',
            );
          }
        }
      } else {
        print('⚠️ Budget not found in local storage: ${budget.id}');
      }
    } catch (e) {
      print('❌ Error updating budget: $e');
      // Keep the local changes even if backend update fails
    }
  }

  // Delete a budget
  Future<void> deleteBudget(String id) async {
    try {
      print('🗑️ Deleting budget with ID: $id');

      // Remove from local storage first for immediate UI update
      _budgets.removeWhere((b) => b.id == id);
      await _updateBudgetsStorage();
      notifyListeners();

      // Then delete from backend if it's not a local-only budget
      if (!AppConfig.useMockData && !id.startsWith('local_')) {
        // Make sure we have a valid auth token before trying to delete from backend
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token == null || token.isEmpty) {
          print('⚠️ No auth token found. Budget will only be deleted locally.');
          return;
        }

        final success = await BudgetService.deleteBudget(id);
        if (success) {
          print('✅ Budget deleted from backend successfully: $id');
        } else {
          print('❌ Failed to delete budget from backend, but removed locally');
        }
      }
    } catch (e) {
      print('❌ Error deleting budget: $e');
    }
  }

  // Add a new savings goal
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    try {
      // Generate a temporary ID if needed
      if (goal.id.isEmpty) {
        goal = goal.copyWith(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Add to local storage first for immediate UI update
      _savingsGoals.add(goal);
      await _updateSavingsGoalsStorage();
      notifyListeners();

      // Then save to backend
      if (!AppConfig.useMockData) {
        print('💰 Saving savings goal to backend: ${goal.title}');

        // Make sure we have a valid auth token before trying to save to backend
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token == null || token.isEmpty) {
          print(
            '⚠️ No auth token found. Savings goal will only be saved locally.',
          );
          return;
        }

        final savedGoal = await SavingsGoalService.createSavingsGoal(goal);

        if (savedGoal != null) {
          // Replace the local goal with the one from the server (which has a proper ID)
          final index = _savingsGoals.indexWhere((g) => g.id == goal.id);
          if (index != -1) {
            _savingsGoals[index] = savedGoal;
            await _updateSavingsGoalsStorage();
            notifyListeners();
          }
          print(
            '✅ Savings goal saved to backend successfully with ID: ${savedGoal.id}',
          );
        } else {
          print('❌ Failed to save savings goal to backend, but kept locally');
        }
      }
    } catch (e) {
      print('❌ Error adding savings goal: $e');
      // Keep the goal locally even if backend save fails
    }
  }

  // Update an existing savings goal
  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    try {
      // Find the index of the savings goal to update
      final index = _savingsGoals.indexWhere((g) => g.id == goal.id);

      if (index != -1) {
        // Update in local storage first for immediate UI update
        _savingsGoals[index] = goal;
        await _updateSavingsGoalsStorage();
        notifyListeners();

        // Then update in backend if it's not a local-only goal
        if (!AppConfig.useMockData && !goal.id.startsWith('local_')) {
          print('💰 Updating savings goal in backend: ${goal.title}');

          // Make sure we have a valid auth token before trying to update in backend
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token == null || token.isEmpty) {
            print(
              '⚠️ No auth token found. Savings goal will only be updated locally.',
            );
            return;
          }

          final updatedGoal = await SavingsGoalService.updateSavingsGoal(goal);

          if (updatedGoal != null) {
            // Replace with the updated version from the server
            _savingsGoals[index] = updatedGoal;
            await _updateSavingsGoalsStorage();
            notifyListeners();
            print(
              '✅ Savings goal updated in backend successfully: ${updatedGoal.id}',
            );
          } else {
            print(
              '❌ Failed to update savings goal in backend, but kept local changes',
            );
          }
        }
      } else {
        print('⚠️ Savings goal not found in local storage: ${goal.id}');
      }
    } catch (e) {
      print('❌ Error updating savings goal: $e');
      // Keep the local changes even if backend update fails
    }
  }

  // Delete a savings goal
  Future<void> deleteSavingsGoal(String id) async {
    try {
      print('🗑️ Deleting savings goal with ID: $id');

      // Remove from local storage first for immediate UI update
      _savingsGoals.removeWhere((g) => g.id == id);
      await _updateSavingsGoalsStorage();
      notifyListeners();

      // Then delete from backend if it's not a local-only goal
      if (!AppConfig.useMockData && !id.startsWith('local_')) {
        // Make sure we have a valid auth token before trying to delete from backend
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token == null || token.isEmpty) {
          print(
            '⚠️ No auth token found. Savings goal will only be deleted locally.',
          );
          return;
        }

        final success = await SavingsGoalService.deleteSavingsGoal(id);
        if (success) {
          print('✅ Savings goal deleted from backend successfully: $id');
        } else {
          print(
            '❌ Failed to delete savings goal from backend, but removed locally',
          );
        }
      }
    } catch (e) {
      print('❌ Error deleting savings goal: $e');
    }
  }

  // Add money to a savings goal
  Future<void> addToSavingsGoal(String goalId, double amount) async {
    print(
      '\n\n🚀🚀🚀 ADDTOSAVINGSGOAL CALLED WITH goalId=$goalId, amount=$amount 🚀🚀🚀',
    );

    // Find the goal
    final index = _savingsGoals.indexWhere((g) => g.id == goalId);
    print('🔍 Goal index found: $index out of ${_savingsGoals.length} goals');

    if (index == -1) {
      print('⚠️ Savings goal not found in local storage: $goalId');
      print(
        '📋 Available goals: ${_savingsGoals.map((g) => '${g.id}:${g.title}').toList()}',
      );
      return;
    }

    final goal = _savingsGoals[index];
    print(
      '📌 Found goal: ${goal.title}, current: ${goal.currentAmount}, target: ${goal.targetAmount}',
    );

    // IMMEDIATELY fetch the updated goal from backend to ensure we have the latest data
    print('🔄 IMMEDIATELY fetching updated goal from backend...');
    try {
      final fetchedGoal = await SavingsGoalService.getSavingsGoalById(goalId);
      if (fetchedGoal != null) {
        print('✅ Fetched goal from backend: ${fetchedGoal.currentAmount}');
        // Update locally with the fetched goal first
        _savingsGoals[index] = fetchedGoal;
        print('📝 After update: _savingsGoals[$index].currentAmount = ${_savingsGoals[index].currentAmount}');
        await _updateSavingsGoalsStorage();
        notifyListeners();
        print('🔔 notifyListeners() called after fetching from backend');
        print('📋 All goals after update: ${_savingsGoals.map((g) => '${g.title}:${g.currentAmount}').toList()}');
      } else {
        print('❌ Failed to fetch goal from backend');
      }
    } catch (e) {
      print('❌ Error fetching goal from backend: $e');
    }

    // Now add the money
    print('💰 Now adding $amount to the goal...');

    // Update on backend FIRST (before transaction)
    try {
      print('🔍 Checking backend update conditions:');
      print('  - useMockData: ${AppConfig.useMockData}');
      print('  - goalId: $goalId');
      print('  - starts with local_: ${goalId.startsWith('local_')}');

      if (!AppConfig.useMockData && !goalId.startsWith('local_')) {
        print('✅ Conditions met, updating backend...');

        // Make sure we have a valid auth token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token == null || token.isEmpty) {
          print(
            '⚠️ No auth token found. Contribution will only be saved locally.',
          );
        } else {
          print(
            '💰 Calling SavingsGoalService.addMoneyToSavingsGoal($goalId, $amount)',
          );
          print('💰 Adding $amount to savings goal in backend: ${goal.title}');

          final resultGoal = await SavingsGoalService.addMoneyToSavingsGoal(
            goalId,
            amount,
          );

          if (resultGoal != null) {
            // Replace with the updated version from the server
            _savingsGoals[index] = resultGoal;
            await _updateSavingsGoalsStorage();
            notifyListeners();
            print(
              '✅ Money added to savings goal in backend successfully: ${resultGoal.id}',
            );
            print(
              '💰 Backend returned amount: ${resultGoal.currentAmount} / ${resultGoal.targetAmount}',
            );
          } else {
            print(
              '❌ Failed to add money to savings goal in backend, but kept local changes',
            );
            // Fetch the updated goal from backend to ensure UI shows correct amount
            print('🔄 Fetching updated goal from backend...');
            final fetchedGoal = await SavingsGoalService.getSavingsGoalById(
              goalId,
            );
            if (fetchedGoal != null) {
              _savingsGoals[index] = fetchedGoal;
              await _updateSavingsGoalsStorage();
              notifyListeners();
              print(
                '✅ Fetched updated goal from backend: ${fetchedGoal.currentAmount}',
              );
            }
          }
        }
      } else {
        print('❌ Backend update skipped - conditions not met');
      }
    } catch (e, stackTrace) {
      print('❌ Error updating backend: $e');
      print('📜 Stack trace: $stackTrace');
      // Fetch the updated goal from backend as fallback
      print('🔄 Fetching updated goal from backend as fallback...');
      try {
        final fetchedGoal = await SavingsGoalService.getSavingsGoalById(goalId);
        if (fetchedGoal != null) {
          _savingsGoals[index] = fetchedGoal;
          await _updateSavingsGoalsStorage();
          notifyListeners();
          print(
            '✅ Fetched updated goal from backend (fallback): ${fetchedGoal.currentAmount}',
          );
        }
      } catch (e2) {
        print('❌ Fallback fetch also failed: $e2');
      }
      // Continue to create transaction even if backend update fails
    }

    // Create a transaction for this savings contribution
    try {
      final transaction = Transaction(
        title: "Contribution to ${goal.title}",
        amount: amount,
        date: DateTime.now(),
        category: TransactionCategory.other_expense,
        type: TransactionType.expense,
      );
      await addTransaction(transaction);
      print('✅ Transaction created for savings contribution');
    } catch (e) {
      print('❌ Error creating transaction: $e');
      // Don't fail the whole operation if transaction creation fails
    }

    print('🏁🏁🏁 ADDTOSAVINGSGOAL METHOD COMPLETED 🏁🏁🏁');
  }

  // Get category-wise spending for a date range
  Map<TransactionCategory, double> getCategorySpending(
    DateTime start,
    DateTime end,
  ) {
    final transactions =
        getTransactionsForDateRange(
          start,
          end,
        ).where((t) => t.type == TransactionType.expense).toList();

    final Map<TransactionCategory, double> result = {};

    for (final transaction in transactions) {
      result[transaction.category] =
          (result[transaction.category] ?? 0) + transaction.amount;
    }

    return result;
  }

  // Get daily transactions data for a date range (for charts)
  List<MapEntry<DateTime, double>> getDailyTransactionData(
    DateTime start,
    DateTime end,
    TransactionType type,
  ) {
    // Create a map with all days in range initialized to 0
    final Map<DateTime, double> dailyData = {};

    // Initialize with all days
    for (
      var d = start;
      d.isBefore(end.add(const Duration(days: 1)));
      d = d.add(const Duration(days: 1))
    ) {
      final normalizedDate = DateTime(d.year, d.month, d.day);
      dailyData[normalizedDate] = 0;
    }

    // Add transaction amounts to corresponding days
    final transactions =
        getTransactionsForDateRange(
          start,
          end,
        ).where((t) => t.type == type).toList();

    for (final transaction in transactions) {
      final normalizedDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyData[normalizedDate] =
          (dailyData[normalizedDate] ?? 0) + transaction.amount;
    }

    // Convert to sorted list of MapEntry
    final result =
        dailyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return result;
  }

  // Load data from storage and backend - always use real data
  Future<void> _loadData({bool forceRefresh = true}) async {
    final prefs = await SharedPreferences.getInstance();

    // Load transactions from local storage first
    final transactionsJson = prefs.getString('transactions');
    if (transactionsJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(transactionsJson);
        _transactions =
            decodedList.map((item) => Transaction.fromJson(item)).toList();

        // Count income and expense transactions for debugging
        int localIncomeCount =
            _transactions.where((t) => t.type == TransactionType.income).length;
        int localExpenseCount =
            _transactions
                .where((t) => t.type == TransactionType.expense)
                .length;

        print(
          '📱 Loaded ${_transactions.length} transactions from local storage',
        );
        print(
          '📊 Local transaction breakdown - Income: $localIncomeCount, Expense: $localExpenseCount',
        );
      } catch (e) {
        print('❌ Error parsing local transactions: $e');
        _transactions = [];
      }
    } else {
      _transactions = [];
    }

    // Then try to fetch from backend if not using mock data or if force refresh is requested
    if (!AppConfig.useMockData || forceRefresh) {
      print(
        '🔄 Fetching transactions from backend (forceRefresh: $forceRefresh)',
      );
      try {
        // Get auth token from AuthStateService for consistency
        final token = await SharedPreferences.getInstance().then(
          (prefs) => prefs.getString('auth_token'),
        );
        if (token == null || token.isEmpty) {
          print('⚠️ No auth token found. User may not be logged in properly.');
          return;
        }

        print('🌐 Fetching transactions from backend...');
        print(
          '🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
        );

        final backendTransactions =
            await TransactionService.getAllTransactions();

        if (backendTransactions.isNotEmpty) {
          // Count income and expense transactions from backend for debugging
          int backendIncomeCount =
              backendTransactions
                  .where((t) => t.type == TransactionType.income)
                  .length;
          int backendExpenseCount =
              backendTransactions
                  .where((t) => t.type == TransactionType.expense)
                  .length;
          print(
            '📊 Backend transaction breakdown - Income: $backendIncomeCount, Expense: $backendExpenseCount',
          );

          // Merge backend transactions with local ones
          // Keep local transactions that aren't on the backend yet
          final localOnlyTransactions =
              _transactions.where((t) => t.id.startsWith('local_')).toList();

          print(
            '💾 Found ${localOnlyTransactions.length} local-only transactions to preserve',
          );

          // Replace all transactions with backend ones + local-only ones
          _transactions = [...backendTransactions, ...localOnlyTransactions];

          // Final count after merging
          int finalIncomeCount =
              _transactions
                  .where((t) => t.type == TransactionType.income)
                  .length;
          int finalExpenseCount =
              _transactions
                  .where((t) => t.type == TransactionType.expense)
                  .length;
          print(
            '📊 Final transaction breakdown - Income: $finalIncomeCount, Expense: $finalExpenseCount',
          );

          // Update local storage with the merged list
          await _updateTransactionsStorage();
          await _calculateBalance();
          notifyListeners();

          print(
            '✅ Loaded ${backendTransactions.length} transactions from backend',
          );
        } else {
          print('⚠️ No transactions found on backend');
        }
      } catch (e) {
        print('❌ Error fetching transactions from backend: $e');
        // Continue with local transactions if backend fetch fails
      }
    }

    // Load budgets from local storage first
    final budgetsJson = prefs.getString('budgets');
    if (budgetsJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(budgetsJson);
        _budgets = decodedList.map((item) => Budget.fromJson(item)).toList();
        print('📱 Loaded ${_budgets.length} budgets from local storage');
      } catch (e) {
        print('❌ Error parsing local budgets: $e');
        _budgets = [];
      }
    } else {
      // Start with empty budgets
      _budgets = [];
    }

    // Then try to fetch budgets from backend if not using mock data or if force refresh is requested
    if (!AppConfig.useMockData || forceRefresh) {
      print('🔄 Fetching budgets from backend (forceRefresh: $forceRefresh)');
      try {
        final backendBudgets = await BudgetService.getAllBudgets();

        if (backendBudgets.isNotEmpty) {
          // Merge backend budgets with local ones
          // Keep local budgets that aren't on the backend yet
          final localOnlyBudgets =
              _budgets.where((b) => b.id.startsWith('local_')).toList();

          print(
            '💾 Found ${localOnlyBudgets.length} local-only budgets to preserve',
          );

          // Replace all budgets with backend ones + local-only ones
          _budgets = [...backendBudgets, ...localOnlyBudgets];

          // Update local storage with the merged list
          await _updateBudgetsStorage();
          notifyListeners();

          print('✅ Loaded ${backendBudgets.length} budgets from backend');
        } else {
          print('⚠️ No budgets found on backend');
        }
      } catch (e) {
        print('❌ Error fetching budgets from backend: $e');
        // Continue with local budgets if backend fetch fails
      }
    }

    // Load savings goals from local storage first
    final savingsGoalsJson = prefs.getString('savingsGoals');
    if (savingsGoalsJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(savingsGoalsJson);
        _savingsGoals =
            decodedList.map((item) => SavingsGoal.fromJson(item)).toList();
        print(
          '📱 Loaded ${_savingsGoals.length} savings goals from local storage',
        );
      } catch (e) {
        print('❌ Error parsing local savings goals: $e');
        _savingsGoals = [];
      }
    } else {
      // Start with empty savings goals
      _savingsGoals = [];
    }

    // Then try to fetch savings goals from backend if not using mock data or if force refresh is requested
    if (!AppConfig.useMockData || forceRefresh) {
      print(
        '🔄 Fetching savings goals from backend (forceRefresh: $forceRefresh)',
      );
      try {
        final backendSavingsGoals =
            await SavingsGoalService.getAllSavingsGoals();

        if (backendSavingsGoals.isNotEmpty) {
          // Merge backend savings goals with local ones
          // Keep local savings goals that aren't on the backend yet
          final localOnlySavingsGoals =
              _savingsGoals.where((g) => g.id.startsWith('local_')).toList();

          print(
            '💾 Found ${localOnlySavingsGoals.length} local-only savings goals to preserve',
          );

          // Replace all savings goals with backend ones + local-only ones
          _savingsGoals = [...backendSavingsGoals, ...localOnlySavingsGoals];

          // Update local storage with the merged list
          await _updateSavingsGoalsStorage();
          notifyListeners();

          print(
            '✅ Loaded ${backendSavingsGoals.length} savings goals from backend',
          );
        } else {
          print('⚠️ No savings goals found on backend');
        }
      } catch (e) {
        print('❌ Error fetching savings goals from backend: $e');
        // Continue with local savings goals if backend fetch fails
      }
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

    // Notify listeners when balance changes
    notifyListeners();
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

  // Update wallet balances from wallet service
  void updateWalletBalances(double cashAmount, double cardsAmount) {
    // Only notify if values actually changed to prevent unnecessary updates
    if (_walletCashAmount != cashAmount || _walletCardsAmount != cardsAmount) {
      _walletCashAmount = cashAmount;
      _walletCardsAmount = cardsAmount;

      // Use microtask to prevent build-phase notifications
      Future.microtask(() {
        notifyListeners();
      });
    }
  }
}
