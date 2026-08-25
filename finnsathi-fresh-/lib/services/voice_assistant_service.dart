import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'finance_service.dart';
import '../models/finance_models.dart';

class VoiceAssistantService extends ChangeNotifier {
  final FinanceService _financeService;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _statusMessage = '';

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get recognizedText => _recognizedText;
  String get statusMessage => _statusMessage;

  VoiceAssistantService(this._financeService) {
    _tts.setLanguage('en-IN');
    _tts.setSpeechRate(0.6);
    _tts.setPitch(1.0);
  }

  Future<void> startListening() async {
    if (_isListening) return;

    _statusMessage = '';
    _recognizedText = '';
    notifyListeners();

    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      _statusMessage = 'Microphone permission is required.';
      notifyListeners();
      await _speak(_statusMessage);
      return;
    }

    final available = await _speechToText.initialize(
      onError: (error) {
        _statusMessage = error.errorMsg;
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );

    if (!available) {
      _statusMessage = 'Speech recognition is not available on this device.';
      notifyListeners();
      await _speak(_statusMessage);
      return;
    }

    _isListening = true;
    _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_IN',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
    );
    notifyListeners();
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _recognizedText = result.recognizedWords;
    notifyListeners();

    if (result.finalResult && _recognizedText.trim().isNotEmpty) {
      _handleCommand(_recognizedText);
    }
  }

  Future<void> _handleCommand(String text) async {
    _isProcessing = true;
    _statusMessage = '';
    notifyListeners();

    final command = _normalizeCommand(text);

    // First handle commands that don't require an amount
    if (_isRecentTransactionsCommand(command)) {
      await _readLastTransactions();
      _isProcessing = false;
      notifyListeners();
      return;
    }

    if (_isBalanceQuery(command)) {
      await _speakBalanceSummary();
      _isProcessing = false;
      notifyListeners();
      return;
    }

    final amount = _extractAmount(command);

    if (amount == null || amount <= 0) {
      _statusMessage =
          'I could not detect a valid amount. For example, say "add expense 500 food".';
      _isProcessing = false;
      notifyListeners();
      await _speak(_statusMessage);
      return;
    }

    try {
      if (_isAddToExistingGoalCommand(command)) {
        await _addToExistingSavingsGoal(command, amount);
      } else if (_isGoalCreationCommand(command)) {
        await _createSavingsGoal(command, amount);
      } else if (_isBudgetCommand(command)) {
        await _setMonthlyBudget(command, amount);
      } else if (_isIncomeCommand(command)) {
        await _createIncome(command, amount);
      } else {
        await _createExpense(command, amount);
      }
    } catch (e) {
      _statusMessage = 'Something went wrong while processing your command.';
      if (kDebugMode) {
        _statusMessage = '${_statusMessage} ($e)';
      }
      await _speak(_statusMessage);
    }

    _isProcessing = false;
    notifyListeners();
  }

  double? _extractAmount(String text) {
    var cleaned = text.replaceAll(',', ' ');
    cleaned = cleaned.replaceAll('rs.', ' ');
    cleaned = cleaned.replaceAll('rs', ' ');
    cleaned = cleaned.replaceAll('rupees', ' ');
    cleaned = cleaned.replaceAll('₹', ' ');

    final match = RegExp(r"(\d+(?:\.\d+)?)").firstMatch(cleaned);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    // Fallback: try to parse basic spoken numbers like "five hundred" or
    // "two thousand five hundred".
    final spoken = _parseSpokenNumber(text);
    if (spoken != null && spoken > 0) {
      return spoken.toDouble();
    }
    return null;
  }

  String _normalizeCommand(String text) {
    var cmd = text.toLowerCase().trim();

    // Fix common recognition variants / typos
    cmd = cmd.replaceAll('expanse', 'expense');
    cmd = cmd.replaceAll('expenses', 'expense');
    cmd = cmd.replaceAll('expensive', 'expense');
    cmd = cmd.replaceAll('in come', 'income');
    cmd = cmd.replaceAll('earning', 'income');
    cmd = cmd.replaceAll('earnings', 'income');
    cmd = cmd.replaceAll('savings', 'saving');
    cmd = cmd.replaceAll('goals', 'goal');

    // Normalise whitespace
    cmd = cmd.replaceAll(RegExp(r"\s+"), ' ');
    return cmd;
  }

  int? _parseSpokenNumber(String text) {
    final wordToNumber = <String, int>{
      'zero': 0,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'seventy': 70,
      'eighty': 80,
      'ninety': 90,
      'hundred': 100,
      'thousand': 1000,
    };

    final tokens =
        text
            .toLowerCase()
            .replaceAll(RegExp(r"[^a-z\s]"), ' ')
            .split(RegExp(r"\s+"))
            .where((t) => t.isNotEmpty)
            .toList();

    if (tokens.isEmpty) return null;

    int total = 0;
    int current = 0;
    bool foundAny = false;

    for (final word in tokens) {
      final value = wordToNumber[word];
      if (value == null) {
        continue;
      }
      foundAny = true;

      if (value == 100) {
        if (current == 0) current = 1;
        current *= 100;
      } else if (value == 1000) {
        if (current == 0) current = 1;
        total += current * 1000;
        current = 0;
      } else {
        current += value;
      }
    }

    if (!foundAny) return null;
    total += current;
    return total == 0 ? null : total;
  }

  bool _isGoalCommand(String text) {
    return text.contains('goal') ||
        text.contains('saving') ||
        text.contains('savings');
  }

  bool _isIncomeCommand(String text) {
    if (text.contains('income') ||
        text.contains('salary') ||
        text.contains('earned') ||
        text.contains('received')) {
      return true;
    }
    return false;
  }

  bool _isBudgetCommand(String text) {
    return text.contains('budget');
  }

  bool _isAddToExistingGoalCommand(String text) {
    final hasGoalWord =
        text.contains('goal') ||
        text.contains('saving') ||
        text.contains('savings');
    final hasAddVerb =
        text.contains('add') ||
        text.contains('contribute') ||
        text.contains('put') ||
        text.contains('deposit');
    final hasToWord =
        text.contains(' to ') ||
        text.contains(' into ') ||
        text.contains(' in ');
    final hasCreateVerb =
        text.contains('set') || text.contains('create') || text.contains('new');

    return hasGoalWord && hasAddVerb && hasToWord && !hasCreateVerb;
  }

  bool _isGoalCreationCommand(String text) {
    if (!_isGoalCommand(text)) return false;
    if (text.contains('set') ||
        text.contains('create') ||
        text.contains('new')) {
      return true;
    }
    return !_isAddToExistingGoalCommand(text);
  }

  bool _isRecentTransactionsCommand(String text) {
    if (text.contains('last 5 transactions') ||
        text.contains('last five transactions') ||
        text.contains('recent transactions')) {
      return true;
    }
    if (text.contains('last transactions') && text.contains('transaction')) {
      return true;
    }
    if (text.contains('recent spending') || text.contains('recent expenses')) {
      return true;
    }
    return false;
  }

  bool _isBalanceQuery(String text) {
    if (text.contains('balance')) return true;
    if (text.contains('how much money') ||
        text.contains('how much do i have') ||
        text.contains('total savings') ||
        text.contains('total amount')) {
      return true;
    }
    return false;
  }

  Future<void> _createExpense(String text, double amount) async {
    final category = _detectExpenseCategory(text);
    final title = _buildTitle(text, fallback: 'Voice expense');

    final transaction = Transaction(
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
      type: TransactionType.expense,
    );

    await _financeService.addTransaction(transaction);
    _statusMessage =
        'Added expense of ₹${amount.toStringAsFixed(2)} for $title.';
    await _speak(_statusMessage);
  }

  Future<void> _createIncome(String text, double amount) async {
    final category = _detectIncomeCategory(text);
    final title = _buildTitle(text, fallback: 'Voice income');

    final transaction = Transaction(
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
      type: TransactionType.income,
    );

    await _financeService.addTransaction(transaction);
    _statusMessage =
        'Added income of ₹${amount.toStringAsFixed(2)} for $title.';
    await _speak(_statusMessage);
  }

  Future<void> _createSavingsGoal(String text, double amount) async {
    final title = _buildTitle(text, fallback: 'Voice savings goal');

    final goal = SavingsGoal(title: title, targetAmount: amount);

    await _financeService.addSavingsGoal(goal);
    _statusMessage =
        'Created savings goal "$title" of ₹${amount.toStringAsFixed(2)}.';
    await _speak(_statusMessage);
  }

  Future<void> _addToExistingSavingsGoal(String text, double amount) async {
    final goals = _financeService.savingsGoals;
    if (goals.isEmpty) {
      _statusMessage = 'You do not have any savings goals yet.';
      await _speak(_statusMessage);
      return;
    }

    final command = text.toLowerCase();
    SavingsGoal? matchedGoal;

    // Try to match by goal title appearing in the command
    for (final goal in goals) {
      final title = goal.title.toLowerCase();
      if (command.contains(title)) {
        matchedGoal = goal;
        break;
      }
    }

    // Fallback: use text after the word "goal" or "saving" as fuzzy name
    if (matchedGoal == null) {
      var startIndex = command.indexOf('goal');
      if (startIndex == -1) {
        final savingIndex = command.indexOf('saving');
        if (savingIndex != -1) {
          startIndex = savingIndex + 'saving'.length;
        }
      } else {
        startIndex += 'goal'.length;
      }

      if (startIndex != -1 && startIndex < command.length) {
        final tail = command.substring(startIndex).trim();
        if (tail.isNotEmpty) {
          for (final goal in goals) {
            final title = goal.title.toLowerCase();
            if (tail.contains(title) || title.contains(tail)) {
              matchedGoal = goal;
              break;
            }
          }
        }
      }
    }

    // If only one goal exists, assume that one
    if (matchedGoal == null && goals.length == 1) {
      matchedGoal = goals.first;
    }

    if (matchedGoal == null) {
      _statusMessage =
          'I could not figure out which savings goal you meant. Please mention the goal name, for example: "add 500 to laptop goal".';
      await _speak(_statusMessage);
      return;
    }

    final goalId = matchedGoal.id;
    await _financeService.addToSavingsGoal(goalId, amount);

    final updatedGoal = _financeService.savingsGoals.firstWhere(
      (g) => g.id == goalId,
      orElse: () => matchedGoal!,
    );

    _statusMessage =
        'Added ₹${amount.toStringAsFixed(2)} to your ${updatedGoal.title} goal. You have saved ₹${updatedGoal.currentAmount.toStringAsFixed(2)} out of ₹${updatedGoal.targetAmount.toStringAsFixed(2)}.';
    await _speak(_statusMessage);
  }

  Future<void> _setMonthlyBudget(String text, double amount) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final category = _detectExpenseCategory(text);
    final budgets = _financeService.budgets;

    Budget? existing;
    for (final b in budgets) {
      final sameMonth =
          b.startDate.year == startOfMonth.year &&
          b.startDate.month == startOfMonth.month;
      final sameCategory = b.category == category;
      if (sameMonth && sameCategory) {
        existing = b;
        break;
      }
    }

    if (existing != null) {
      final updated = existing.copyWith(
        limit: amount,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      await _financeService.updateBudget(updated);
      _statusMessage =
          'Updated your ${category.displayName.toLowerCase()} budget for this month to ₹${amount.toStringAsFixed(2)}.';
    } else {
      final title = '${category.displayName} budget';
      final budget = Budget(
        title: title,
        limit: amount,
        startDate: startOfMonth,
        endDate: endOfMonth,
        category: category,
      );
      await _financeService.addBudget(budget);
      _statusMessage =
          'Set a ${category.displayName.toLowerCase()} budget of ₹${amount.toStringAsFixed(2)} for this month.';
    }

    await _speak(_statusMessage);
  }

  TransactionCategory _detectExpenseCategory(String text) {
    if (text.contains('food') ||
        text.contains('lunch') ||
        text.contains('dinner') ||
        text.contains('breakfast') ||
        text.contains('restaurant') ||
        text.contains('coffee')) {
      return TransactionCategory.food;
    }
    if (text.contains('grocery') ||
        text.contains('groceries') ||
        text.contains('supermarket')) {
      return TransactionCategory.groceries;
    }
    if (text.contains('shopping') ||
        text.contains('clothes') ||
        text.contains('dress') ||
        text.contains('online')) {
      return TransactionCategory.shopping;
    }
    if (text.contains('travel') ||
        text.contains('trip') ||
        text.contains('flight') ||
        text.contains('hotel')) {
      return TransactionCategory.travel;
    }
    if (text.contains('bus') ||
        text.contains('train') ||
        text.contains('cab') ||
        text.contains('taxi') ||
        text.contains('uber') ||
        text.contains('ola') ||
        text.contains('auto')) {
      return TransactionCategory.transport;
    }
    if (text.contains('rent') ||
        text.contains('house') ||
        text.contains('home')) {
      return TransactionCategory.home;
    }
    if (text.contains('bill') ||
        text.contains('electricity') ||
        text.contains('water') ||
        text.contains('mobile') ||
        text.contains('recharge') ||
        text.contains('wifi') ||
        text.contains('internet')) {
      return TransactionCategory.bills;
    }
    if (text.contains('doctor') ||
        text.contains('hospital') ||
        text.contains('medicine') ||
        text.contains('medical') ||
        text.contains('health')) {
      return TransactionCategory.health;
    }
    if (text.contains('school') ||
        text.contains('college') ||
        text.contains('tuition') ||
        text.contains('course')) {
      return TransactionCategory.education;
    }
    if (text.contains('movie') ||
        text.contains('netflix') ||
        text.contains('ott') ||
        text.contains('entertainment')) {
      return TransactionCategory.entertainment;
    }
    return TransactionCategory.other_expense;
  }

  TransactionCategory _detectIncomeCategory(String text) {
    if (text.contains('salary') || text.contains('job')) {
      return TransactionCategory.salary;
    }
    if (text.contains('rent')) {
      return TransactionCategory.rent;
    }
    if (text.contains('bonus') ||
        text.contains('gift') ||
        text.contains('gifts')) {
      return TransactionCategory.gifts;
    }
    if (text.contains('stock') ||
        text.contains('mutual fund') ||
        text.contains('dividend') ||
        text.contains('interest') ||
        text.contains('investment')) {
      return TransactionCategory.investment;
    }
    if (text.contains('business') ||
        text.contains('freelance') ||
        text.contains('side hustle')) {
      return TransactionCategory.business;
    }
    return TransactionCategory.other_income;
  }

  Future<void> _readLastTransactions() async {
    final all = List<Transaction>.from(_financeService.transactions);
    if (all.isEmpty) {
      _statusMessage = 'You have no transactions yet.';
      await _speak(_statusMessage);
      return;
    }

    all.sort((a, b) => b.date.compareTo(a.date));
    final count = all.length < 5 ? all.length : 5;
    final recent = all.take(count).toList();

    final now = DateTime.now();
    final List<String> descriptions = [];

    for (var i = 0; i < recent.length; i++) {
      final t = recent[i];
      final diffDays = now.difference(t.date).inDays;
      String when;
      if (diffDays == 0) {
        when = 'today';
      } else if (diffDays == 1) {
        when = 'yesterday';
      } else {
        when = '$diffDays days ago';
      }

      final typeStr = t.type == TransactionType.income ? 'income' : 'expense';
      descriptions.add(
        '${i + 1}) ${t.title}, $typeStr of ₹${t.amount.toStringAsFixed(0)} $when',
      );
    }

    _statusMessage = 'Last $count transactions:\n${descriptions.join('\n')}';
    await _speak(
      'Here are your last $count transactions. ${descriptions.join('. ')}.',
    );
  }

  Future<void> _speakBalanceSummary() async {
    final balance = _financeService.balance;
    final income = _financeService.totalIncome;
    final expense = _financeService.totalExpense;

    _statusMessage =
        'Your current balance is ₹${balance.toStringAsFixed(2)}. Total income is ₹${income.toStringAsFixed(2)} and total expenses are ₹${expense.toStringAsFixed(2)}.';
    await _speak(_statusMessage);
  }

  String _buildTitle(String text, {required String fallback}) {
    var cleaned = text;
    cleaned = cleaned.replaceAll('add', '');
    cleaned = cleaned.replaceAll('income', '');
    cleaned = cleaned.replaceAll('expense', '');
    cleaned = cleaned.replaceAll('set', '');
    cleaned = cleaned.replaceAll('goal', '');
    cleaned = cleaned.replaceAll(RegExp(r"(\d+(?:\.\d+)?)"), '');
    cleaned = cleaned.replaceAll(RegExp(r"\s+"), ' ').trim();

    if (cleaned.length < 3) {
      return fallback;
    }
    return cleaned;
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  void dispose() {
    // Ensure any active speech recognition and TTS are stopped
    _speechToText.stop();
    _tts.stop();
    super.dispose();
  }
}
