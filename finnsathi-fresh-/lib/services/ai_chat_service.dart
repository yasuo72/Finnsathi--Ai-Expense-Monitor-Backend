import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/chat_models.dart';
import '../models/finance_models.dart';
import 'finance_service.dart';

class AIChatService extends ChangeNotifier {
  final FinanceService _financeService;
  final String _screenId;
  List<ChatMessage> _messages = [];
  bool _isGenerating = false;

  // Claude API configuration (using Anthropic's API)
  final String _apiEndpoint = 'https://api.anthropic.com/v1/messages';
  String? _apiKey;

  List<ChatMessage> get messages => _messages;
  bool get isGenerating => _isGenerating;

  AIChatService(this._financeService, this._screenId) {
    _loadMessages();
    _loadApiKey();
  }

  // Load API key from environment variables
  Future<void> _loadApiKey() async {
    try {
      // Try to get the API key from environment variables
      _apiKey = dotenv.env['OPENAI_API_KEY'];
      debugPrint(
        'API Key loaded: ${_apiKey != null && _apiKey!.isNotEmpty ? "Found (starts with ${_apiKey!.substring(0, 5)}...)" : "Not found"}',
      );

      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint('Warning: API key not found in environment variables');
      }
    } catch (e) {
      debugPrint('Error loading API key: $e');
    }
  }

  // Load saved messages from SharedPreferences
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('chat_messages_$_screenId');

    if (messagesJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(messagesJson);
        _messages =
            decodedList.map((item) {
              return ChatMessage(
                id: item['id'],
                text: item['text'],
                sender:
                    item['sender'] == 'user'
                        ? MessageSender.user
                        : MessageSender.ai,
                timestamp: DateTime.parse(item['timestamp']),
              );
            }).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading chat messages: $e');
        _messages = [];
      }
    }

    // Add a welcome message if no messages exist
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          text: AIResponseGenerator.getGreeting(),
          sender: MessageSender.ai,
        ),
      );
      _saveMessages();
      notifyListeners();
    }
  }

  // Save messages to SharedPreferences
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        _messages
            .map(
              (m) => {
                'id': m.id,
                'text': m.text,
                'sender': m.sender == MessageSender.user ? 'user' : 'ai',
                'timestamp': m.timestamp.toIso8601String(),
              },
            )
            .toList();

    await prefs.setString('chat_messages_$_screenId', jsonEncode(jsonList));
  }

  // Fetch dynamic prompt suggestions for a screen
  Future<List<String>> fetchDynamicPrompts(String screen) async {
    // Build quick stats snapshot
    final stats = {
      'balance': _financeService.balance,
      'income': _financeService.totalIncome,
      'expense': _financeService.totalExpense,
      'savingsRate': _financeService.savingsRate,
      'budgets': _financeService.budgets.length,
      'savingsGoals': _financeService.savingsGoals.length,
    };

    // Local tailored suggestions first
    final local = AIResponseGenerator.getSampleQuestionsForScreen(screen);

    try {
      final res = await ApiService.post('/gemini/prompts', {
        'screen': screen,
        'stats': stats,
      });
      if (res['prompts'] is List) {
        final remote = List<String>.from(res['prompts']);
        // merge & deduplicate
        final set = {...local, ...remote};
        return set.toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch remote prompts: $e');
    }
    return local;
  }

  // Add a user message and generate a response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    debugPrint(
      'Sending message: "${text.substring(0, text.length > 20 ? 20 : text.length)}..."',
    );

    try {
      // Add user message
      final userMessage = ChatMessage(text: text, sender: MessageSender.user);

      _messages.add(userMessage);
      await _saveMessages();
      notifyListeners();
      debugPrint('User message added');

      // Add a loading message while generating response
      final loadingMessage = ChatMessage.loading();
      _messages.add(loadingMessage);
      _isGenerating = true;
      notifyListeners();
      debugPrint('Loading message added, generating response...');

      // Simulate AI thinking time
      await Future.delayed(const Duration(milliseconds: 800));

      String response;
      try {
        // Generate response with timeout
        response = await _generateResponse(text).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            debugPrint('Response generation timed out after 20 seconds');
            return "I'm sorry, I'm having trouble connecting to my AI service right now. Could you try again in a moment?";
          },
        );
        debugPrint('Response generated successfully');
      } catch (e) {
        debugPrint('Error generating response: $e');
        response =
            "I'm sorry, I encountered an error while processing your request. Please try again later.";
      }

      // Replace loading message with actual response
      final responseIndex = _messages.indexWhere(
        (m) => m.id == loadingMessage.id,
      );
      if (responseIndex != -1) {
        _messages[responseIndex] = ChatMessage(
          text: response,
          sender: MessageSender.ai,
          id: loadingMessage.id,
          timestamp: DateTime.now(),
        );
        debugPrint('Loading message replaced with AI response');
      } else {
        debugPrint('Warning: Could not find loading message to replace');
        // Add response as a new message if loading message can't be found
        _messages.add(
          ChatMessage(
            text: response,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
      }

      _isGenerating = false;
      await _saveMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Critical error in sendMessage: $e');
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Clear all chat messages
  Future<void> clearChat() async {
    // Keep only the welcome message
    _messages = [
      ChatMessage(
        text: AIResponseGenerator.getGreeting(),
        sender: MessageSender.ai,
      ),
    ];

    _saveMessages();
    notifyListeners();
  }

  // Call OpenAI API to get AI-generated response
  Future<String> _callOpenAI(String prompt) async {
    debugPrint(
      'Starting API call for prompt: "${prompt.substring(0, prompt.length > 20 ? 20 : prompt.length)}..."',
    );

    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('OpenAI API key not available. Using fallback responses.');
      return _getFallbackResponse(prompt);
    }

    debugPrint('API Key available: ${_apiKey!.substring(0, 10)}...');

    try {
      debugPrint('Getting financial context...');
      // Get financial data to include in the context
      final financialContext = await _getFinancialContext();
      debugPrint('Financial context retrieved successfully');

      // Prepare system prompt and user message for Claude API
      final systemPrompt =
          'You are a helpful financial assistant. You provide personalized financial advice based on the user\'s data. ' +
          'Always be respectful and professional. Keep responses concise and helpful.';

      final userMessage =
          'Here is my financial information:\n$financialContext\n\nMy question is: $prompt';

      debugPrint('Sending request to Claude API...');
      final requestBody = jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 500,
        'temperature': 0.7,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      });

      debugPrint(
        'Request body: ${requestBody.substring(0, requestBody.length > 100 ? 100 : requestBody.length)}...',
      );

      // Make API request
      final response = await http
          .post(
            Uri.parse(_apiEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': '$_apiKey',
              'anthropic-version': '2023-06-01',
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('API request timed out after 30 seconds');
              throw TimeoutException('API request timed out');
            },
          );

      debugPrint('Response received with status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('Successful response from Claude API');
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];
        debugPrint(
          'Response content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...',
        );
        return content;
      } else {
        debugPrint(
          'OpenAI API Error: ${response.statusCode} - ${response.body}',
        );
        return await _getFallbackResponse(prompt);
      }
    } catch (e) {
      debugPrint('Error calling OpenAI API: $e');
      return await _getFallbackResponse(prompt);
    }
  }

  // Get monthly statistics
  Future<Map<String, double>> _getMonthlyStats(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0); // Last day of month

    final transactions = _financeService.getTransactionsForDateRange(
      startOfMonth,
      endOfMonth,
    );

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = income - expenses;
    final savingsRate = income > 0 ? ((income - expenses) / income) * 100 : 0.0;

    return {
      'income': income,
      'expenses': expenses,
      'balance': balance,
      'savingsRate': savingsRate,
    };
  }

  // Get financial context for the AI
  // Utility to format currency in Indian Rupees
  String _inr(double amount) => '₹${amount.toStringAsFixed(2)}';

  Future<String> _getFinancialContext() async {
    final thisMonth = DateTime.now();
    final lastMonth = DateTime(thisMonth.year, thisMonth.month - 1);

    // Get financial data
    final currentMonthData = await _getMonthlyStats(
      thisMonth.year,
      thisMonth.month,
    );
    final lastMonthData = await _getMonthlyStats(
      lastMonth.year,
      lastMonth.month,
    );

    // Format financial data
    return '''
    Current Month Stats:  
    Income: ${_inr(currentMonthData['income']!)}
    Expenses: ${_inr(currentMonthData['expenses']!)}
    Balance: ${_inr(currentMonthData['balance']!)}
    Savings Rate: ${currentMonthData['savingsRate']!.toStringAsFixed(1)}%
    
    Previous Month Stats:
    Income: ${_inr(lastMonthData['income']!)}
    Expenses: ${_inr(lastMonthData['expenses']!)}
    Balance: ${_inr(lastMonthData['balance']!)}
    Savings Rate: ${lastMonthData['savingsRate']!.toStringAsFixed(1)}%
    ''';
  }

  // Fallback response generator when API is not available
  Future<String> _getFallbackResponse(String query) async {
    final lowercaseQuery = query.toLowerCase();

    // Basic keyword matching for fallback responses
    if (lowercaseQuery.contains('spend') ||
        lowercaseQuery.contains('expense')) {
      return await _getExpenseAnalysis(query);
    } else if (lowercaseQuery.contains('income') ||
        lowercaseQuery.contains('earn')) {
      return await _getIncomeAnalysis(query);
    } else if (lowercaseQuery.contains('save') ||
        lowercaseQuery.contains('saving')) {
      return await _getSavingsAnalysis(query);
    } else if (lowercaseQuery.contains('compare') ||
        lowercaseQuery.contains('difference')) {
      return await _getComparisonAnalysis(query);
    } else if (lowercaseQuery.contains('budget') ||
        lowercaseQuery.contains('plan')) {
      return await _getBudgetAnalysis(query);
    } else {
      return _getFinancialAdvice(query);
    }
  }

  // Generate AI response based on user query
  Future<String> _generateResponse(String query) async {
    try {
      // Combine the user query with a compact snapshot of their finances and category breakdown
      final context = await _getFinancialContext();
      final categoriesText = _getCurrentMonthCategoryBreakdown();
      final enrichedPrompt = '''
You are a personal finance AI assistant. The user asked:
"""
$query
"""

Here is the user's current financial snapshot:
$context

Category-wise spending for the current month:
$categoriesText

Please answer the user's question using the data above. All monetary values should be expressed in Indian Rupees (₹). If some information is still missing, ask specific follow-up questions.
''';

      return await _callGeminiBackend(enrichedPrompt);
    } catch (e) {
      debugPrint('Error generating response via Gemini: $e');
      return await _getFallbackResponse(query);
    }
  }

  // Call backend Gemini proxy
  Future<String> _callGeminiBackend(String prompt) async {
    try {
      final data = await ApiService.post(
        '${AppConfig.apiBaseUrl}/gemini/chat',
        {'prompt': prompt},
      );
      if (data != null && data['message'] != null) {
        return data['message'] as String;
      }
      return 'No response from Gemini.';
    } catch (e) {
      debugPrint('Error calling Gemini backend: $e');
      return _getFallbackResponse(prompt);
    }
  }

  // Legacy OpenAI/Claude caller (unused now)
  // Keeping the original caller for fallback/testing purposes
  /*
  Future<String> _legacyOpenAICall(String query) async {
    try {
      return await _callOpenAI(query);
    } catch (e) {
      debugPrint('Legacy OpenAI call failed: $e');
      return await _getFallbackResponse(query);
    }
  }
  */

  // Analyze user's expense patterns
  Future<String> _getExpenseAnalysis(String query) async {
    // Get current month transactions
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final transactions =
        _financeService
            .getTransactionsForDateRange(startOfMonth, endOfMonth)
            .where((t) => t.type == TransactionType.expense)
            .toList();

    if (transactions.isEmpty) {
      return "I don't see any expenses recorded for this month yet. Would you like to add some transactions to track your spending?";
    }

    // Calculate total expenses
    final totalExpense = transactions.fold(0.0, (sum, t) => sum + t.amount);

    // Get category breakdown
    final categorySpending = _financeService.getCategorySpending(
      startOfMonth,
      endOfMonth,
    );

    // Find top spending categories
    final expenseCategories =
        categorySpending.entries
            .where(
              (e) =>
                  TransactionCategory.values[e.key.index].transactionType ==
                  TransactionType.expense,
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    String topCategoriesText = '';

    if (expenseCategories.isNotEmpty) {
      topCategoriesText = 'Your top spending categories are:\n';

      for (int i = 0; i < expenseCategories.length && i < 3; i++) {
        final category = expenseCategories[i].key;
        final amount = expenseCategories[i].value;
        final percentage = (amount / totalExpense) * 100;

        topCategoriesText +=
            '• ${category.displayName}: \$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)\n';
      }
    }

    // Get daily spending average
    final daysInMonth = endOfMonth.day;
    final averageDaily = totalExpense / daysInMonth;

    return "This month, you've spent a total of \$${totalExpense.toStringAsFixed(2)}.\n\n"
        "$topCategoriesText\n"
        "Your daily average spending is \$${averageDaily.toStringAsFixed(2)}.\n\n"
        "Is there a specific area of your spending you'd like me to analyze further?";
  }

  // Analyze user's income data
  Future<String> _getIncomeAnalysis(String query) async {
    // Get current month transactions
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final transactions =
        _financeService
            .getTransactionsForDateRange(startOfMonth, endOfMonth)
            .where((t) => t.type == TransactionType.income)
            .toList();

    if (transactions.isEmpty) {
      return "I don't see any income recorded for this month yet. Would you like to add some income transactions?";
    }

    // Calculate total income
    final totalIncome = transactions.fold(0.0, (sum, t) => sum + t.amount);

    // Get category breakdown
    final categoryIncome = _financeService.getCategorySpending(
      startOfMonth,
      endOfMonth,
    );

    // Find income categories
    final incomeCategories =
        categoryIncome.entries
            .where(
              (e) =>
                  TransactionCategory.values[e.key.index].transactionType ==
                  TransactionType.income,
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    String incomeCategoriesText = '';

    if (incomeCategories.isNotEmpty) {
      incomeCategoriesText = 'Your income sources are:\n';

      for (int i = 0; i < incomeCategories.length; i++) {
        final category = incomeCategories[i].key;
        final amount = incomeCategories[i].value;
        final percentage = (amount / totalIncome) * 100;

        incomeCategoriesText +=
            '• ${category.displayName}: \$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)\n';
      }
    }

    // Get previous month for comparison
    final startOfPrevMonth = DateTime(now.year, now.month - 1, 1);
    final endOfPrevMonth = DateTime(now.year, now.month, 0);

    final prevMonthTransactions =
        _financeService
            .getTransactionsForDateRange(startOfPrevMonth, endOfPrevMonth)
            .where((t) => t.type == TransactionType.income)
            .toList();

    final prevMonthIncome = prevMonthTransactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    String comparisonText = '';
    if (prevMonthIncome > 0) {
      final difference = totalIncome - prevMonthIncome;
      final percentChange = (difference / prevMonthIncome) * 100;

      if (difference > 0) {
        comparisonText =
            "That's an increase of \$${difference.toStringAsFixed(2)} (${percentChange.toStringAsFixed(1)}%) compared to last month.";
      } else if (difference < 0) {
        comparisonText =
            "That's a decrease of \$${(-difference).toStringAsFixed(2)} (${(-percentChange).toStringAsFixed(1)}%) compared to last month.";
      } else {
        comparisonText = "Your income is the same as last month.";
      }
    }

    return "This month, your total income is \$${totalIncome.toStringAsFixed(2)}.\n\n"
        "$incomeCategoriesText\n"
        "${comparisonText.isNotEmpty ? comparisonText + '\n\n' : ''}"
        "Would you like to know more about how your income relates to your expenses or savings?";
  }

  // Analyze user's savings progress
  Future<String> _getSavingsAnalysis(String query) async {
    final savingsGoals = _financeService.savingsGoals;

    if (savingsGoals.isEmpty) {
      return "You don't have any savings goals set up yet. Would you like to create a savings goal to track your progress?";
    }

    // Get current month's income and expenses
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final transactions = _financeService.getTransactionsForDateRange(
      startOfMonth,
      endOfMonth,
    );
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final monthlySavings = income - expenses;
    final savingsRate = income > 0 ? (monthlySavings / income) * 100 : 0;

    // Generate text about each savings goal
    String goalsText = 'Here are your current savings goals:\n\n';

    for (final goal in savingsGoals) {
      final progressPercent = (goal.currentAmount / goal.targetAmount) * 100;
      String timeRemainingText = '';

      if (goal.targetDate != null) {
        final daysRemaining = goal.daysRemaining;
        if (daysRemaining > 0) {
          timeRemainingText =
              " with $daysRemaining days remaining to reach your target date";
        } else if (daysRemaining == 0) {
          timeRemainingText = " (your target date is today)";
        } else {
          timeRemainingText =
              " (you've passed your target date by ${-daysRemaining} days)";
        }
      }

      goalsText +=
          "**${goal.title}**\n"
          "Progress: ${progressPercent.toStringAsFixed(1)}% (\$${goal.currentAmount.toStringAsFixed(2)} of \$${goal.targetAmount.toStringAsFixed(2)})"
          "$timeRemainingText\n"
          "Remaining: \$${goal.remainingAmount.toStringAsFixed(2)}\n\n";
    }

    // Provide savings recommendation
    String savingsAdvice = '';
    if (savingsRate < 10) {
      savingsAdvice =
          "Your current savings rate is ${savingsRate.toStringAsFixed(1)}%, which is below the recommended 20%. Consider reviewing your expenses to increase your savings rate.";
    } else if (savingsRate < 20) {
      savingsAdvice =
          "Your current savings rate is ${savingsRate.toStringAsFixed(1)}%. That's a good start, but aiming for 20% or more would help you reach your goals faster.";
    } else {
      savingsAdvice =
          "Great job! Your current savings rate is ${savingsRate.toStringAsFixed(1)}%, which exceeds the recommended 20%. You're on track to reach your goals.";
    }

    return "$goalsText$savingsAdvice\n\nWould you like specific advice on how to reach one of your savings goals faster?";
  }

  // Compare income vs expenses
  Future<String> _getComparisonAnalysis(String query) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final transactions = _financeService.getTransactionsForDateRange(
      startOfMonth,
      endOfMonth,
    );
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = income - expenses;
    final savingsRate = income > 0 ? (balance / income) * 100 : 0;

    String result =
        "**Income vs Expenses (This Month)**\n\n"
        "Income: \$${income.toStringAsFixed(2)}\n"
        "Expenses: \$${expenses.toStringAsFixed(2)}\n"
        "Balance: \$${balance.toStringAsFixed(2)}\n"
        "Savings Rate: ${savingsRate.toStringAsFixed(1)}%\n\n";

    // Get previous month for comparison
    final startOfPrevMonth = DateTime(now.year, now.month - 1, 1);
    final endOfPrevMonth = DateTime(now.year, now.month, 0);

    final prevTransactions = _financeService.getTransactionsForDateRange(
      startOfPrevMonth,
      endOfPrevMonth,
    );

    final prevIncome = prevTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final prevExpenses = prevTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final prevBalance = prevIncome - prevExpenses;
    final prevSavingsRate =
        prevIncome > 0 ? (prevBalance / prevIncome) * 100 : 0.0;

    if (prevIncome > 0 || prevExpenses > 0) {
      result +=
          "**Comparison with Last Month**\n\n"
          "Income: ${_getChangeText(income, prevIncome)}\n"
          "Expenses: ${_getChangeText(expenses, prevExpenses)}\n"
          "Balance: ${_getChangeText(balance, prevBalance)}\n"
          "Savings Rate: ${_getChangeText(savingsRate.toDouble(), prevSavingsRate.toDouble(), isPercentage: true)}\n\n";
    }

    // Add advice based on the comparison
    if (balance < 0) {
      result +=
          "⚠️ Your expenses exceed your income this month. Consider cutting back on non-essential spending to bring your budget back into balance.";
    } else if (savingsRate < 10) {
      result +=
          "You're saving ${savingsRate.toStringAsFixed(1)}% of your income, which is below the recommended 20%. Try to identify areas where you could reduce expenses to increase your savings rate.";
    } else if (savingsRate < 20) {
      result +=
          "You're saving ${savingsRate.toStringAsFixed(1)}% of your income, which is decent but below the ideal 20%. With a few adjustments to your spending, you could reach that goal.";
    } else {
      result +=
          "Great job! You're saving ${savingsRate.toStringAsFixed(1)}% of your income, which exceeds the recommended 20%. Keep up the good work!";
    }

    return result;
  }

  // Helper function to generate change text
  String _getChangeText(
    double current,
    double previous, {
    bool isPercentage = false,
  }) {
    if (previous == 0)
      return isPercentage
          ? "${current.toStringAsFixed(1)}% (no previous data)"
          : "\$${current.toStringAsFixed(2)} (no previous data)";

    final difference = current - previous;
    final percentChange = previous != 0 ? (difference / previous) * 100 : 0.0;

    String changeText =
        isPercentage
            ? "${current.toStringAsFixed(1)}%"
            : "\$${current.toStringAsFixed(2)}";

    if (difference > 0) {
      changeText += " (↑ ${percentChange.toStringAsFixed(1)}%)";
    } else if (difference < 0) {
      changeText += " (↓ ${(-percentChange).toStringAsFixed(1)}%)";
    } else {
      changeText += " (no change)";
    }

    return changeText;
  }

  // Analyze budget status
  Future<String> _getBudgetAnalysis(String query) async {
    final budgets = _financeService.budgets;

    if (budgets.isEmpty) {
      return "You don't have any budgets set up yet. Would you like to create a budget to help track and control your spending?";
    }

    String result = "**Budget Analysis**\n\n";

    for (final budget in budgets) {
      final percentUsed =
          budget.limit > 0 ? (budget.spent / budget.limit) * 100 : 0;
      final remaining = budget.limit - budget.spent;

      String statusText;
      if (percentUsed >= 100) {
        statusText = "⚠️ Over budget by \$${(-remaining).toStringAsFixed(2)}";
      } else if (percentUsed >= 80) {
        statusText =
            "⚠️ Approaching limit (${percentUsed.toStringAsFixed(1)}%)";
      } else {
        statusText = "✅ On track (${percentUsed.toStringAsFixed(1)}%)";
      }

      result +=
          "${budget.title}\n"
          "${budget.category != null ? 'Category: ${budget.category!.displayName}\n' : ''}"
          "Limit: \$${budget.limit.toStringAsFixed(2)}\n"
          "Spent: \$${budget.spent.toStringAsFixed(2)}\n"
          "Remaining: \$${remaining.toStringAsFixed(2)}\n"
          "Status: $statusText\n\n";
    }

    // Add overall budget health
    final overBudgetCount = budgets.where((b) => b.spent > b.limit).length;
    final approachingLimitCount =
        budgets
            .where((b) => b.spent <= b.limit && (b.spent / b.limit) >= 0.8)
            .length;

    if (overBudgetCount > 0) {
      result +=
          "You are over budget in $overBudgetCount ${overBudgetCount == 1 ? 'category' : 'categories'}. Consider adjusting your spending or increasing these budget limits if necessary.";
    } else if (approachingLimitCount > 0) {
      result +=
          "You are approaching your budget limit in $approachingLimitCount ${approachingLimitCount == 1 ? 'category' : 'categories'}. Monitor these closely for the rest of the period.";
    } else {
      result += "All your budgets are on track! Keep up the good work.";
    }

    return result;
  }

  // Provide general financial advice
  String _getCurrentMonthCategoryBreakdown() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final breakdown = _financeService.getCategorySpending(start, end);
    if (breakdown.isEmpty) return 'No transactions recorded.';
    final sb = StringBuffer();
    breakdown.forEach((cat, amt) {
      sb.writeln('• ${cat.displayName}: ${_inr(amt)}');
    });
    return sb.toString();
  }

  String _getFinancialAdvice(String query) {
    final lowercaseQuery = query.toLowerCase();

    // Specific advice for budgeting
    if (lowercaseQuery.contains('budget') || lowercaseQuery.contains('plan')) {
      return "**Budgeting Tips:**\n\n"
          "1. **Follow the 50/30/20 rule**: Allocate 50% of your income to needs, 30% to wants, and 20% to savings and debt repayment.\n\n"
          "2. **Track every expense**: Use FinnSathi to record all your transactions to see exactly where your money is going.\n\n"
          "3. **Review and adjust regularly**: Check your budget at least monthly and make adjustments as needed.\n\n"
          "4. **Use specific categories**: Break down your expenses into detailed categories to identify areas for improvement.\n\n"
          "5. **Set realistic goals**: Create budgets that are challenging but achievable to stay motivated.\n\n"
          "Would you like me to help you set up a specific budget category?";
    }
    // Advice for saving money
    else if (lowercaseQuery.contains('save') ||
        lowercaseQuery.contains('saving')) {
      return "**Savings Tips:**\n\n"
          "1. **Automate your savings**: Set up automatic transfers to your savings account on payday.\n\n"
          "2. **Use the 24-hour rule**: For non-essential purchases, wait 24 hours before buying to avoid impulse spending.\n\n"
          "3. **Save windfalls**: Put unexpected money like tax returns or bonuses directly into savings.\n\n"
          "4. **Cut one regular expense**: Identify a subscription or regular purchase you can live without and redirect that money to savings.\n\n"
          "5. **Set specific, achievable goals**: Having clear savings goals increases motivation and success rates.\n\n"
          "Would you like me to help you create a new savings goal?";
    }
    // Advice for reducing expenses
    else if (lowercaseQuery.contains('spend') ||
        lowercaseQuery.contains('expense')) {
      return "**Tips to Reduce Expenses:**\n\n"
          "1. **Review subscriptions**: Cancel unused subscriptions and services you don't regularly use.\n\n"
          "2. **Meal plan and cook at home**: Reducing restaurant meals can significantly cut expenses.\n\n"
          "3. **Use cashback and rewards**: Maximize credit card rewards and cashback apps for purchases you'd make anyway.\n\n"
          "4. **Negotiate bills**: Call service providers to negotiate better rates on bills like internet, phone, and insurance.\n\n"
          "5. **Practice mindful spending**: Before each purchase, ask if it aligns with your financial goals and brings lasting value.\n\n"
          "Would you like me to analyze your current expense categories to suggest where you might cut back?";
    }
    // Advice for increasing income
    else if (lowercaseQuery.contains('income') ||
        lowercaseQuery.contains('earn')) {
      return "**Tips to Increase Income:**\n\n"
          "1. **Develop marketable skills**: Invest in learning skills that are in demand in your field or industry.\n\n"
          "2. **Start a side hustle**: Use your talents to create a secondary income stream in your spare time.\n\n"
          "3. **Negotiate your salary**: Research market rates for your position and prepare to negotiate for raises or promotions.\n\n"
          "4. **Monetize your hobbies**: Turn things you enjoy doing into income opportunities.\n\n"
          "5. **Maximize passive income**: Consider dividend-paying investments or other passive income streams that work for you.\n\n"
          "Would you like me to help you track your income sources more effectively?";
    }
    // General financial health advice
    else {
      return "**General Financial Health Tips:**\n\n"
          "1. **Build an emergency fund**: Aim to save 3-6 months of living expenses for unexpected events.\n\n"
          "2. **Pay down high-interest debt**: Prioritize paying off credit cards and other high-interest loans.\n\n"
          "3. **Save for retirement early**: Take advantage of compound interest by starting retirement savings as soon as possible.\n\n"
          "4. **Protect yourself with insurance**: Ensure you have adequate health, auto, home/rental, and life insurance if needed.\n\n"
          "5. **Create multiple income streams**: Diversify your income sources to increase financial stability.\n\n"
          "6. **Practice mindful spending**: Focus your spending on things that truly bring you value and happiness.\n\n"
          "Is there a specific area of your finances you'd like more detailed advice on?";
    }
  }
}
