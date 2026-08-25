import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
import '../models/finance_models.dart';
import 'profile_service.dart';
import 'finance_service.dart';

// Challenge model
class Challenge {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? category;
  final String? difficulty;
  final String? icon;
  final int rewardCoins;
  final int rewardPoints;
  final int targetValue;
  int currentValue;
  bool isCompleted;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.category,
    this.difficulty,
    this.icon,
    required this.rewardCoins,
    required this.rewardPoints,
    required this.targetValue,
    required this.currentValue,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'title': title,
      'description': description,
      'type': type,
      'category': category ?? type,
      'difficulty': difficulty,
      'icon': icon ?? 'star',
      'points': rewardPoints,
      'coins': rewardCoins,
      'rewardCoins': rewardCoins,
      'rewardPoints': rewardPoints,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isCompleted': isCompleted,
    };

    // Only include id if it's not empty (to avoid MongoDB ObjectId cast errors)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? 'Challenge',
      description: json['description'] ?? 'Complete this challenge',
      type: json['type'] ?? 'daily',
      category: json['category']?.toString(),
      difficulty: json['difficulty']?.toString(),
      icon: json['icon']?.toString(),
      rewardCoins: json['coins'] ?? json['rewardCoins'] ?? 0,
      rewardPoints: json['points'] ?? json['rewardPoints'] ?? 0,
      targetValue: json['targetValue'] ?? 1,
      currentValue: json['currentValue'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
}

// Quest model (a series of related challenges)
class Quest {
  final String id;
  final String title;
  final String description;
  final List<Challenge> challenges;
  final int rewardCoins;
  final int rewardPoints;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.challenges,
    required this.rewardCoins,
    required this.rewardPoints,
  });

  bool get isCompleted =>
      challenges.every((challenge) => challenge.isCompleted);

  double get progress {
    if (challenges.isEmpty) return 0.0;

    final totalCompleted = challenges.where((c) => c.isCompleted).length;
    return totalCompleted / challenges.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'challenges': challenges.map((c) => c.toJson()).toList(),
      'rewardCoins': rewardCoins,
      'rewardPoints': rewardPoints,
    };
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      challenges:
          (json['challenges'] as List)
              .map((c) => Challenge.fromJson(c))
              .toList(),
      rewardCoins: json['rewardCoins'],
      rewardPoints: json['rewardPoints'],
    );
  }
}

class EnhancedGamificationService extends ChangeNotifier {
  // Keys for SharedPreferences
  static const String _gamificationKey = 'gamification_data';
  static const String _dailyChallengesKey = 'daily_challenges';
  static const String _streakKey = 'activity_streak';
  static const String _lastActivityKey = 'last_activity_date';
  static const String _xpKey = 'gamification_xp';
  static const String _levelKey = 'gamification_level';
  static const String _trophiesKey = 'gamification_trophies';
  static const String _badgesKey = 'user_badges';
  static const String _questsKey = 'gamification_quests';
  static const String _insightsKey = 'financial_insights';
  static const String _tipsKey = 'personalized_tips';

  final ProfileService _profileService;
  final FinanceService _financeService;

  // Challenges
  List<Challenge> _dailyChallenges = [];
  List<Quest> _quests = [];

  // Streaks
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActivityDate;
  // Rewards
  int _financeCoins = 0;

  // XP and Level System
  int _currentXP = 0;
  int _currentLevel = 1;
  List<String> _userBadges = [];

  // Gamification elements
  List<Trophy> _availableTrophies = [];

  // AI Insights
  Map<String, dynamic> _financialInsights = {};
  List<String> _personalizedTips = [];

  // Flag to indicate if initial data has been loaded
  bool _isInitialized = false;

  // Constructor
  EnhancedGamificationService(this._profileService, this._financeService) {
    _initialize();
  }

  // Getters
  List<Challenge> get dailyChallenges => _dailyChallenges;
  // Weekly challenges are not implemented yet
  List<Challenge> get weeklyChallenges => [];
  List<Quest> get activeQuests => _quests;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get financeCoins => _financeCoins;
  int get currentXP => _currentXP;
  int get currentLevel => _currentLevel;
  List<Trophy> get availableTrophies => _availableTrophies;
  List<String> get userBadges => _userBadges;
  Map<String, dynamic> get financialInsights => _financialInsights;
  List<String> get personalizedTips => _personalizedTips;

  // XP required to reach a given level (matches backend: 100 XP per level)
  int getXPForNextLevel(int level) {
    // Level 1 starts at 0 XP, level 2 at 100 XP, level 3 at 200 XP, etc.
    if (level <= 0) return 0;
    return 100 * level;
  }

  // Calculate level progress percentage
  double getLevelProgress() {
    final currentLevelXP = getXPForNextLevel(_currentLevel - 1);
    final nextLevelXP = getXPForNextLevel(_currentLevel);
    final xpForCurrentLevel = _currentXP - currentLevelXP;
    final xpRequiredForNextLevel = nextLevelXP - currentLevelXP;

    return (xpForCurrentLevel / xpRequiredForNextLevel).clamp(0.0, 1.0);
  }

  // Get XP needed for next level
  int getXPNeededForNextLevel() {
    final nextLevelXP = getXPForNextLevel(_currentLevel);
    return nextLevelXP - _currentXP;
  }

  // Show notification (helper method used throughout the service)
  void _showNotification(String title, String message) {
    // This will be implemented to show in-app notifications
    debugPrint('NOTIFICATION: $title - $message');

    // In a real implementation, this would show a proper notification
    // or connect to a notification service
  }

  // Initialize the service
  Future<void> _initialize() async {
    // Reset all data to 0 first
    _resetAllData();

    // Then try to load any saved data
    await _loadGamificationData();

    // Generate initial challenges if none exist
    if (_dailyChallenges.isEmpty) {
      _generateDailyChallenges();
    }

    // Initialize trophies if none exist
    if (_availableTrophies.isEmpty) {
      _initializeDefaultTrophies();
    }

    // Sync with profile service
    _syncWithProfileService();

    // Mark as initialized
    _isInitialized = true;
    notifyListeners();

    // Set up a timer to check for updates every hour
    Timer.periodic(const Duration(hours: 1), (_) async {
      await _checkAndUpdateStreak();
      await _checkAndGenerateDailyChallenges();
      await _checkAchievements();
      await _refreshFinancialInsights();
      notifyListeners();
    });
  }

  // Reset all data to initial values
  void _resetAllData() {
    // Reset streaks
    _currentStreak = 0;
    _longestStreak = 0;
    _lastActivityDate = null;

    // Reset rewards
    _financeCoins = 0;

    // Reset XP and level
    _currentXP = 0;
    _currentLevel = 1;

    // Reset badges
    _userBadges = [];

    // Initialize default trophies
    _initializeDefaultTrophies();

    // Reset challenges
    _dailyChallenges.clear();
    _quests.clear();

    // Reset AI features
    _financialInsights = {};
    _personalizedTips = [];
  }

  // Sync with profile service
  void _syncWithProfileService() {
    final profile = _profileService.currentProfile;

    // Update XP and level in profile
    final updatedProfile = profile.copyWith(
      xp: _currentXP,
      level: _currentLevel,
      levelProgress: getLevelProgress(),
      trophies: _availableTrophies.where((t) => t.isUnlocked).toList(),
      badges: _userBadges,
    );

    _profileService.updateUserProfile(updatedProfile);
  }

  // Check achievements based on app data
  Future<bool> _checkAchievements() async {
    final finances = _financeService;
    bool achievementsUpdated = false;

    // Check savings-related achievements
    final totalSavings = finances.savingsGoals.fold<double>(
      0,
      (sum, goal) => sum + goal.currentAmount,
    );

    // Savings Hero trophy (₹25,000 saved)
    if (totalSavings >= 25000) {
      achievementsUpdated =
          await unlockTrophy('trophy_savings_hero') || achievementsUpdated;
    }

    // Check investment-related achievements
    // Check if user has any investment-related transactions
    bool hasInvestments = false;
    for (final transaction in finances.transactions) {
      if (transaction.category == TransactionCategory.investment) {
        hasInvestments = true;
        break;
      }
    }

    if (hasInvestments) {
      achievementsUpdated =
          await unlockTrophy('trophy_investment_guru') || achievementsUpdated;
    }

    // Check savings goals achievements
    final completedGoals =
        finances.savingsGoals
            .where((goal) => goal.currentAmount >= goal.targetAmount)
            .length;

    if (completedGoals >= 5) {
      achievementsUpdated =
          await unlockTrophy('trophy_financial_planner') || achievementsUpdated;
    }

    // Check streak achievements
    final streakResult = await _checkStreakTrophies();
    achievementsUpdated = streakResult || achievementsUpdated;

    if (achievementsUpdated) {
      _syncWithProfileService();
    }

    return achievementsUpdated;
  }

  // Refresh financial insights based on app data
  Future<void> _refreshFinancialInsights() async {
    final finances = _financeService;

    // Calculate basic financial insights
    // Use the transactions to calculate income and expenses
    double totalIncome = 0;
    double totalExpenses = 0;

    // Calculate from transactions
    for (final transaction in finances.transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount;
      }
    }

    final savingsRate =
        totalIncome > 0 ? (totalIncome - totalExpenses) / totalIncome : 0;

    // Update insights
    _financialInsights = {
      'total_income': totalIncome,
      'total_expenses': totalExpenses,
      'savings_rate': savingsRate,
      'last_updated': DateTime.now().toIso8601String(),
    };

    // Generate personalized tips based on financial data
    _generatePersonalizedTips();

    // Save changes
    await _saveGamificationData();
  }

  // Generate personalized financial tips based on user data
  void _generatePersonalizedTips() {
    final insights = _financialInsights;
    final tips = <String>[];

    // Savings rate tips
    final savingsRate = insights['savings_rate'] as double? ?? 0;
    if (savingsRate < 0.1) {
      tips.add(
        'Try to save at least 10% of your income each month for financial stability.',
      );
      tips.add(
        'Consider creating a budget to track your expenses and identify areas to cut back.',
      );
    } else if (savingsRate >= 0.2) {
      tips.add(
        'Great job saving ${(savingsRate * 100).toStringAsFixed(0)}% of your income! Consider investing some of your savings.',
      );
    }

    // Expense category tips
    // Get top expense categories by analyzing transactions
    final expensesByCategory = <TransactionCategory, double>{};
    for (final transaction in _financeService.transactions) {
      if (transaction.type == TransactionType.expense) {
        final category = transaction.category;
        expensesByCategory[category] =
            (expensesByCategory[category] ?? 0) + transaction.amount;
      }
    }

    if (expensesByCategory.isNotEmpty) {
      // Find the category with the highest expenses
      TransactionCategory topCategory = expensesByCategory.keys.first;
      double maxAmount = expensesByCategory[topCategory] ?? 0;

      for (final entry in expensesByCategory.entries) {
        if (entry.value > maxAmount) {
          topCategory = entry.key;
          maxAmount = entry.value;
        }
      }

      tips.add(
        'Your highest spending category is ${topCategory.displayName}. Consider reviewing these expenses to find potential savings.',
      );
    }

    // Investment tips
    // Check if user has any investment-related transactions
    bool hasInvestments = false;
    for (final transaction in _financeService.transactions) {
      if (transaction.category == TransactionCategory.investment) {
        hasInvestments = true;
        break;
      }
    }

    if (!hasInvestments) {
      tips.add(
        'Consider starting your investment journey with a small amount to build wealth over time.',
      );
    }

    // Update personalized tips
    _personalizedTips = tips;
  }

  // Load gamification data from SharedPreferences
  Future<void> _loadGamificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if data has been initialized before
      final isInitialized =
          prefs.getBool('${_gamificationKey}_initialized') ?? false;
      if (!isInitialized) {
        // First time use, don't load anything
        return;
      }

      // Load streak data
      _currentStreak = prefs.getInt(_streakKey) ?? 0;
      _longestStreak = prefs.getInt('longest_$_streakKey') ?? 0;
      final lastActivityStr = prefs.getString(_lastActivityKey);
      _lastActivityDate =
          lastActivityStr != null ? DateTime.parse(lastActivityStr) : null;

      // Load finance coins
      _financeCoins = prefs.getInt('finance_coins') ?? 0;

      // Load XP and level data
      _currentXP = prefs.getInt(_xpKey) ?? 0;
      _currentLevel = prefs.getInt(_levelKey) ?? 1;

      // Load badges
      final badgesJson = prefs.getStringList(_badgesKey);
      if (badgesJson != null) {
        _userBadges = badgesJson;
      }

      // Load trophies
      final trophiesJson = prefs.getString(_trophiesKey);
      if (trophiesJson != null) {
        final List<dynamic> trophiesList = jsonDecode(trophiesJson);
        _availableTrophies =
            trophiesList
                .map(
                  (item) => Trophy(
                    id: item['id'] ?? '',
                    title: item['title'] ?? '',
                    description: item['description'] ?? '',
                    rarity: _parseTrophyRarity(item['rarity'] ?? 'common'),
                    iconPath: item['iconPath'] ?? '',
                    isUnlocked: item['isUnlocked'] ?? false,
                    dateAwarded:
                        item['dateAwarded'] != null
                            ? DateTime.parse(item['dateAwarded'])
                            : null,
                    xpReward: item['xpReward'] ?? 100,
                  ),
                )
                .toList();
      } else {
        // Initialize with default trophies if none exist
        _initializeDefaultTrophies();
      }

      // Load challenges
      await _loadChallenges();

      // Load financial insights and personalized tips
      final insightsJson = prefs.getString(_insightsKey);
      if (insightsJson != null) {
        _financialInsights = jsonDecode(insightsJson);
      }

      final tipsJson = prefs.getString(_tipsKey);
      if (tipsJson != null) {
        final List<dynamic> tipsList = jsonDecode(tipsJson);
        _personalizedTips = tipsList.cast<String>();
      }
    } catch (e) {
      debugPrint('Error loading gamification data: $e');
      // Reset to defaults on error
      _resetAllData();
    }
  }

  // Save gamification data to SharedPreferences
  Future<void> _saveGamificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save streak data
      await prefs.setInt(_streakKey, _currentStreak);
      await prefs.setInt('longest_$_streakKey', _longestStreak);
      if (_lastActivityDate != null) {
        await prefs.setString(
          _lastActivityKey,
          _lastActivityDate!.toIso8601String(),
        );
      }

      // Save finance coins
      await prefs.setInt('finance_coins', _financeCoins);

      // Save XP and level data
      await prefs.setInt(_xpKey, _currentXP);
      await prefs.setInt(_levelKey, _currentLevel);

      // Save badges
      await prefs.setStringList(_badgesKey, _userBadges);

      // Save trophies
      final trophiesJson = jsonEncode(
        _availableTrophies
            .map(
              (trophy) => {
                'id': trophy.id,
                'title': trophy.title,
                'description': trophy.description,
                'rarity': trophy.rarity.toString().split('.').last,
                'iconPath': trophy.iconPath,
                'isUnlocked': trophy.isUnlocked,
                'dateAwarded': trophy.dateAwarded?.toIso8601String(),
                'xpReward': trophy.xpReward,
              },
            )
            .toList(),
      );
      await prefs.setString(_trophiesKey, trophiesJson);

      // Save challenges
      await _saveChallenges();

      // Save financial insights and personalized tips
      if (_financialInsights.isNotEmpty) {
        await prefs.setString(_insightsKey, jsonEncode(_financialInsights));
      }

      if (_personalizedTips.isNotEmpty) {
        await prefs.setString(_tipsKey, jsonEncode(_personalizedTips));
      }

      // Mark as initialized
      await prefs.setBool('${_gamificationKey}_initialized', true);
    } catch (e) {
      debugPrint('Error saving gamification data: $e');
    }
  }

  // Initialize default trophies
  void _initializeDefaultTrophies() {
    _availableTrophies = [
      Trophy(
        id: 'trophy_budget_master',
        title: 'Budget Master',
        description: 'Stay within budget for 3 consecutive months',
        rarity: TrophyRarity.rare,
        iconPath: 'assets/icons/trophies/budget_master.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_savings_hero',
        title: 'Savings Hero',
        description: 'Save ₹25,000 in total',
        rarity: TrophyRarity.uncommon,
        iconPath: 'assets/icons/trophies/savings_hero.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_investment_guru',
        title: 'Investment Guru',
        description: 'Make your first investment',
        rarity: TrophyRarity.common,
        iconPath: 'assets/icons/trophies/investment_guru.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_expense_tracker',
        title: 'Expense Tracker',
        description: 'Track expenses for 30 consecutive days',
        rarity: TrophyRarity.uncommon,
        iconPath: 'assets/icons/trophies/expense_tracker.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_financial_planner',
        title: 'Financial Planner',
        description: 'Create and complete 5 savings goals',
        rarity: TrophyRarity.epic,
        iconPath: 'assets/icons/trophies/financial_planner.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_debt_free',
        title: 'Debt Free',
        description: 'Pay off all your debts',
        rarity: TrophyRarity.legendary,
        iconPath: 'assets/icons/trophies/debt_free.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_money_saver',
        title: 'Money Saver',
        description: 'Save 20% of your income for 3 consecutive months',
        rarity: TrophyRarity.rare,
        iconPath: 'assets/icons/trophies/money_saver.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_finance_guru',
        title: 'Finance Guru',
        description: 'Reach level 10 in the app',
        rarity: TrophyRarity.epic,
        iconPath: 'assets/icons/trophies/finance_guru.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_streak_master',
        title: 'Streak Master',
        description: 'Maintain a 30-day activity streak',
        rarity: TrophyRarity.rare,
        iconPath: 'assets/icons/trophies/streak_master.png',
        isUnlocked: false,
      ),
      Trophy(
        id: 'trophy_financial_wizard',
        title: 'Financial Wizard',
        description: 'Complete all financial health checkups',
        rarity: TrophyRarity.legendary,
        iconPath: 'assets/icons/trophies/financial_wizard.png',
        isUnlocked: false,
      ),
    ];
  }

  // Helper method to parse trophy rarity from string
  TrophyRarity _parseTrophyRarity(String rarityStr) {
    switch (rarityStr) {
      case 'common':
        return TrophyRarity.common;
      case 'uncommon':
        return TrophyRarity.uncommon;
      case 'rare':
        return TrophyRarity.rare;
      case 'epic':
        return TrophyRarity.epic;
      case 'legendary':
        return TrophyRarity.legendary;
      default:
        return TrophyRarity.common;
    }
  }

  // Add XP to user and check for level up
  Future<void> addXP(int amount, {String? source}) async {
    if (amount <= 0) return;

    final oldLevel = _currentLevel;
    _currentXP += amount;

    // Check if user leveled up
    while (_currentXP >= getXPForNextLevel(_currentLevel)) {
      _currentLevel++;
    }

    // If level changed, show notification and update profile
    if (_currentLevel > oldLevel) {
      _showNotification(
        'Level Up!',
        'Congratulations! You are now level $_currentLevel',
      );

      // Award coins for level up
      _financeCoins += _currentLevel * 50;

      // Check for level-based trophies
      await _checkLevelTrophies();
    }

    // Update profile service with new XP and level
    _syncWithProfileService();

    // Save changes
    await _saveGamificationData();
    notifyListeners();
  }

  // Check for level-based trophies
  Future<void> _checkLevelTrophies() async {
    // Find the finance guru trophy (reach level 10)
    final trophyIndex = _availableTrophies.indexWhere(
      (t) => t.id == 'trophy_finance_guru',
    );
    if (trophyIndex != -1 &&
        !_availableTrophies[trophyIndex].isUnlocked &&
        _currentLevel >= 10) {
      await unlockTrophy('trophy_finance_guru');
    }

    // Add more level-based trophies here
  }

  // Unlock a trophy by ID
  Future<bool> unlockTrophy(String trophyId) async {
    final trophyIndex = _availableTrophies.indexWhere((t) => t.id == trophyId);
    if (trophyIndex == -1) return false;

    final trophy = _availableTrophies[trophyIndex];
    if (trophy.isUnlocked) return false; // Already unlocked

    // Create updated trophy with unlocked status
    final updatedTrophy = Trophy(
      id: trophy.id,
      title: trophy.title,
      description: trophy.description,
      rarity: trophy.rarity,
      iconPath: trophy.iconPath,
      isUnlocked: true,
      dateAwarded: DateTime.now(),
      xpReward: trophy.xpReward,
    );

    // Update trophy in list
    _availableTrophies[trophyIndex] = updatedTrophy;

    // Award XP for trophy
    _currentXP += trophy.xpReward;

    // Check for level up
    final oldLevel = _currentLevel;
    while (_currentXP >= getXPForNextLevel(_currentLevel)) {
      _currentLevel++;
    }

    // If level changed, show notification
    if (_currentLevel > oldLevel) {
      _showNotification(
        'Level Up!',
        'Congratulations! You are now level $_currentLevel',
      );
    }

    // Show trophy notification
    _showNotification('Trophy Unlocked!', 'You earned: ${trophy.title}');

    // Update profile service
    _syncWithProfileService();

    // Save changes
    await _saveGamificationData();
    notifyListeners();

    return true;
  }

  // Award a badge to the user
  Future<void> awardBadge(String badgeId) async {
    if (_userBadges.contains(badgeId)) return; // Already has badge

    _userBadges.add(badgeId);

    // Show notification
    _showNotification('Badge Earned!', 'You earned a new badge: $badgeId');

    // Award XP for badge
    await addXP(50, source: 'Badge: $badgeId');

    // Update profile service
    _syncWithProfileService();

    // Save changes
    await _saveGamificationData();
    notifyListeners();
  }

  // Record user activity and update streak
  Future<void> recordActivity() async {
    if (!_isInitialized) await _initialize();

    await _checkAndUpdateStreak();
    await _checkAndGenerateDailyChallenges();
    await _checkAchievements();

    // Save changes
    await _saveGamificationData();
    notifyListeners();
  }

  // Check and update streak
  Future<void> _checkAndUpdateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastActivityDate == null) {
      // First time using the app
      _currentStreak = 1;
      _longestStreak = 1;
      _lastActivityDate = today;
      return;
    }

    final lastActivity = DateTime(
      _lastActivityDate!.year,
      _lastActivityDate!.month,
      _lastActivityDate!.day,
    );

    final difference = today.difference(lastActivity).inDays;

    if (difference == 0) {
      // Already recorded activity today
      return;
    } else if (difference == 1) {
      // Consecutive day, increment streak
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }

      // Award streak bonus
      await _awardStreakBonus();
    } else {
      // Streak broken
      _currentStreak = 1;
    }

    _lastActivityDate = today;

    // Check for streak trophies
    await _checkStreakTrophies();
  }

  // Award bonus for maintaining streak
  Future<void> _awardStreakBonus() async {
    // Award XP based on current streak
    int xpBonus = 0;

    if (_currentStreak % 30 == 0) {
      // Monthly streak
      xpBonus = 300;
      _financeCoins += 300;
      _showNotification(
        'Amazing Streak!',
        '30-day streak! You earned 300 XP and 300 coins!',
      );
    } else if (_currentStreak % 7 == 0) {
      // Weekly streak
      xpBonus = 100;
      _financeCoins += 100;
      _showNotification(
        'Great Streak!',
        '7-day streak! You earned 100 XP and 100 coins!',
      );
    } else if (_currentStreak >= 3) {
      // 3+ day streak
      xpBonus = 20;
      _financeCoins += 20;
    }

    if (xpBonus > 0) {
      await addXP(xpBonus, source: 'Streak bonus');
    }
  }

  // Check for streak-based trophies
  Future<bool> _checkStreakTrophies() async {
    bool trophyUnlocked = false;

    // Find the streak master trophy (30-day streak)
    final trophyIndex = _availableTrophies.indexWhere(
      (t) => t.id == 'trophy_streak_master',
    );
    if (trophyIndex != -1 &&
        !_availableTrophies[trophyIndex].isUnlocked &&
        _currentStreak >= 30) {
      trophyUnlocked = await unlockTrophy('trophy_streak_master');
    }

    return trophyUnlocked;
  }

  // Check and generate daily challenges
  Future<void> _checkAndGenerateDailyChallenges() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prefs = await SharedPreferences.getInstance();
    final _ = prefs.getString('last_challenge_date');

    // Check if we need to generate new challenges
    bool needsNewChallenges = _dailyChallenges.isEmpty;

    if (!needsNewChallenges && _lastActivityDate != null) {
      final lastActivity = DateTime(
        _lastActivityDate!.year,
        _lastActivityDate!.month,
        _lastActivityDate!.day,
      );

      // Generate new challenges if it's a new day
      needsNewChallenges = today.difference(lastActivity).inDays > 0;
    }

    if (needsNewChallenges) {
      _generateDailyChallenges();
      await prefs.setString('last_challenge_date', now.toIso8601String());
      await _saveGamificationData();
    }

    // Update challenge progress based on user data
    await _updateChallengeProgress();
    notifyListeners();
  }

  // Update challenge progress based on user activity
  Future<void> _updateChallengeProgress() async {
    final finances = _financeService;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    // Check for today's transactions to update challenges
    final todayTransactions =
        finances.transactions
            .where(
              (t) => t.date.isAfter(todayStart) && t.date.isBefore(todayEnd),
            )
            .toList();

    bool challengesUpdated = false;

    // Update expense tracking challenges
    for (final challenge in _dailyChallenges) {
      if (challenge.isCompleted) continue;

      if (challenge.type == 'expense_tracking') {
        // Count today's expense transactions
        final expenseCount =
            todayTransactions
                .where((t) => t.type == TransactionType.expense)
                .length;

        if (expenseCount > 0) {
          challenge.currentValue = expenseCount;
          if (challenge.currentValue >= challenge.targetValue) {
            challenge.isCompleted = true;
            _awardChallengeRewards(challenge);
            challengesUpdated = true;
          }
        }
      } else if (challenge.type == 'savings') {
        // Check for savings transactions or savings goal contributions
        final savingsTransactions =
            todayTransactions
                .where(
                  (t) =>
                      t.type == TransactionType.expense &&
                      t.description != null &&
                      t.description!.toLowerCase().contains('saving'),
                )
                .length;

        if (savingsTransactions > 0) {
          challenge.currentValue = 1;
          challenge.isCompleted = true;
          _awardChallengeRewards(challenge);
          challengesUpdated = true;
        }
      } else if (challenge.type == 'budget_adherence') {
        // Check if user stayed within budget today
        bool withinBudget = true;

        for (final budget in finances.budgets) {
          final budgetTransactions = todayTransactions.where(
            (t) =>
                t.type == TransactionType.expense &&
                (budget.category == null || t.category == budget.category),
          );

          final todaySpent = budgetTransactions.fold<double>(
            0,
            (sum, t) => sum + t.amount,
          );

          // Calculate daily budget limit
          final days = budget.endDate.difference(budget.startDate).inDays + 1;
          final dailyLimit = budget.limit / days;

          if (todaySpent > dailyLimit) {
            withinBudget = false;
            break;
          }
        }

        if (withinBudget && finances.budgets.isNotEmpty) {
          challenge.currentValue = 1;
          challenge.isCompleted = true;
          _awardChallengeRewards(challenge);
          challengesUpdated = true;
        }
      }
    }

    // Check if any quests are completed
    for (final quest in _quests) {
      if (quest.isCompleted) continue;

      if (quest.challenges.every((c) => c.isCompleted)) {
        // Award quest rewards
        _financeCoins += quest.rewardCoins;
        _addXP(quest.rewardPoints);
        _showNotification(
          'Quest Completed!',
          'You completed the "${quest.title}" quest and earned ${quest.rewardCoins} coins and ${quest.rewardPoints} XP!',
        );
        challengesUpdated = true;
      }
    }

    if (challengesUpdated) {
      await _saveGamificationData();
      notifyListeners();
    }
  }

  // Award rewards for completing a challenge
  void _awardChallengeRewards(Challenge challenge) {
    _financeCoins += challenge.rewardCoins;
    _addXP(challenge.rewardPoints);
    _showNotification(
      'Challenge Completed!',
      'You completed "${challenge.title}" and earned ${challenge.rewardCoins} coins and ${challenge.rewardPoints} XP!',
    );
  }

  // Find a challenge by its ID
  Challenge? _findChallengeById(String challengeId) {
    // First check daily challenges
    for (final challenge in _dailyChallenges) {
      if (challenge.id == challengeId) return challenge;
    }

    // Then check challenges in quests
    for (final quest in _quests) {
      for (final challenge in quest.challenges) {
        if (challenge.id == challengeId) return challenge;
      }
    }

    return null;
  }

  // Add XP to the user's profile and check for level up
  void _addXP(int amount) {
    if (amount <= 0) return;

    final oldLevel = _currentLevel;
    _currentXP += amount;

    // Check if user leveled up
    final newLevel = _calculateLevelFromXP(_currentXP);

    if (newLevel > oldLevel) {
      // Level up!
      _currentLevel = newLevel;

      // Show level up notification
      _showNotification(
        'Level Up!',
        'Congratulations! You reached level $_currentLevel!',
      );

      // Add level-based rewards
      final levelReward = _currentLevel * 50; // 50 coins per level
      _financeCoins += levelReward;

      _showNotification(
        'Level Reward',
        'You earned $levelReward coins for reaching level $_currentLevel!',
      );
    }

    // Sync with profile service
    _syncWithProfileService();
  }

  // Calculate level based on XP
  int _calculateLevelFromXP(int xp) {
    // Progressive XP system where each level requires more XP than the previous one
    // Level 1: 0-99 XP
    // Level 2: 100-299 XP
    // Level 3: 300-599 XP
    // And so on...

    if (xp < 100) return 1;

    int level = 1;
    int xpRequired = 100;
    int totalXpRequired = xpRequired;

    while (xp >= totalXpRequired) {
      level++;
      xpRequired +=
          100 + (level - 2) * 100; // Increase XP requirement with each level
      totalXpRequired += xpRequired;
    }

    return level;
  }

  // Generate new daily challenges
  void _generateDailyChallenges() {
    // Clear existing challenges
    _dailyChallenges.clear();

    // Generate challenges based on user's financial data
    final random = math.Random();
    // Create a savings challenge
    _dailyChallenges.add(
      Challenge(
        id: 'challenge_${DateTime.now().millisecondsSinceEpoch}_1',
        title: 'Save Today',
        description: 'Save ₹${(random.nextInt(5) + 1) * 100} today',
        type: 'savings',
        rewardCoins: 50,
        rewardPoints: 25,
        targetValue: 1,
        currentValue: 0,
        isCompleted: false,
      ),
    );

    // Create an expense tracking challenge
    _dailyChallenges.add(
      Challenge(
        id: 'challenge_${DateTime.now().millisecondsSinceEpoch}_2',
        title: 'Track Expenses',
        description: 'Record ${random.nextInt(3) + 1} expenses today',
        type: 'expense_tracking',
        rewardCoins: 30,
        rewardPoints: 15,
        targetValue: random.nextInt(3) + 1,
        currentValue: 0,
        isCompleted: false,
      ),
    );

    // Create an app usage challenge
    _dailyChallenges.add(
      Challenge(
        id: 'challenge_${DateTime.now().millisecondsSinceEpoch}_3',
        title: 'Financial Check-in',
        description: 'Open the app and check your finances',
        type: 'app_usage',
        rewardCoins: 20,
        rewardPoints: 10,
        targetValue: 1,
        currentValue: 1, // Auto-completed when app is opened
        isCompleted: true,
      ),
    );

    // Check if user has any budget categories
    final hasBudgets = _financeService.budgets.isNotEmpty;
    if (hasBudgets) {
      _dailyChallenges.add(
        Challenge(
          id: 'challenge_${DateTime.now().millisecondsSinceEpoch}_4',
          title: 'Budget Master',
          description: 'Stay within your budget today',
          type: 'budget_adherence',
          rewardCoins: 40,
          rewardPoints: 20,
          targetValue: 1,
          currentValue: 0,
          isCompleted: false,
        ),
      );
    }

    // Generate a quest that combines multiple challenges
    _generateQuests();
  }

  // Generate quests based on daily challenges
  // List of challenge types for generating challenges
  final List<String> _challengeTypes = [
    'expense_tracking',
    'savings',
    'budget_review',
    'investment',
    'financial_education',
    'app_usage',
  ];

  void _generateQuests() {
    // Clear old quests
    _quests.clear();

    // Create a quest that combines multiple challenges
    if (_dailyChallenges.length >= 3) {
      _quests.add(
        Quest(
          id: 'quest_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Daily Financial Mastery',
          description: 'Complete all daily financial challenges',
          challenges: _dailyChallenges.take(3).toList(),
          rewardCoins: 100,
          rewardPoints: 50,
        ),
      );
    }

    // Create 3 challenges if needed
    if (_dailyChallenges.isEmpty) {
      for (int i = 0; i < math.min(3, _challengeTypes.length); i++) {
        final challenge = _createChallengeByType(_challengeTypes[i]);
        _dailyChallenges.add(challenge);
      }
    }
  }

  // Create a challenge by type
  Challenge _createChallengeByType(String type) {
    final id = 'challenge_${type}_${DateTime.now().millisecondsSinceEpoch}';

    switch (type) {
      case 'expense_tracking':
        return Challenge(
          id: id,
          title: 'Track Your Expenses',
          description: 'Add 3 expenses to your tracker today',
          type: type,
          rewardCoins: 50,
          rewardPoints: 30,
          targetValue: 3,
          currentValue: 0,
          isCompleted: false,
        );

      case 'savings':
        return Challenge(
          id: id,
          title: 'Save Some Money',
          description: 'Add money to your savings goal',
          type: type,
          rewardCoins: 70,
          rewardPoints: 40,
          targetValue: 1,
          currentValue: 0,
          isCompleted: false,
        );

      case 'budget':
        return Challenge(
          id: id,
          title: 'Budget Review',
          description: 'Review your monthly budget',
          type: type,
          rewardCoins: 40,
          rewardPoints: 25,
          targetValue: 1,
          currentValue: 0,
          isCompleted: false,
        );

      case 'financial_education':
        return Challenge(
          id: id,
          title: 'Financial Learning',
          description: 'Read a financial tip in the app',
          type: type,
          rewardCoins: 30,
          rewardPoints: 20,
          targetValue: 1,
          currentValue: 0,
          isCompleted: false,
        );

      case 'investment':
        return Challenge(
          id: id,
          title: 'Investment Research',
          description: 'Check investment opportunities',
          type: type,
          rewardCoins: 60,
          rewardPoints: 35,
          targetValue: 1,
          currentValue: 0,
          isCompleted: false,
        );

      default:
        return Challenge(
          id: id,
          title: 'App Usage',
          description: 'Use the app for 5 minutes today',
          type: 'app_usage',
          rewardCoins: 20,
          rewardPoints: 15,
          targetValue: 1,
          currentValue: 0,
          isCompleted: false,
        );
    }
  }

  // Challenge helper methods

  // Update challenge progress
  Future<void> updateChallengeProgress(String challengeId, int progress) async {
    // Find the challenge
    Challenge? challenge = _findChallengeById(challengeId);
    if (challenge == null) return;

    // Update progress
    challenge.currentValue += progress;

    // Check if challenge is completed
    if (!challenge.isCompleted &&
        challenge.currentValue >= challenge.targetValue) {
      challenge.isCompleted = true;

      // Award rewards
      _financeCoins += challenge.rewardCoins;
      await addXP(
        challenge.rewardPoints,
        source: 'Challenge: ${challenge.title}',
      );

      // Show notification
      _showNotification(
        'Challenge Completed!',
        'You completed: ${challenge.title} and earned ${challenge.rewardCoins} coins and ${challenge.rewardPoints} XP!',
      );

      // Check achievements
      await _checkAchievements();
    }

    // Save changes
    await _saveChallenges();
    notifyListeners();
  }

  // This notification method is already defined at the top of the class

  // Load challenges from SharedPreferences
  Future<void> _loadChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load daily challenges
      final dailyChallengesJson = prefs.getString(_dailyChallengesKey);
      if (dailyChallengesJson != null) {
        final List<dynamic> challengesList = jsonDecode(dailyChallengesJson);
        _dailyChallenges =
            challengesList.map((item) => Challenge.fromJson(item)).toList();
      }

      // Load quests
      final questsJson = prefs.getString(_questsKey);
      if (questsJson != null) {
        final List<dynamic> questsList = jsonDecode(questsJson);
        _quests = questsList.map((item) => Quest.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      _dailyChallenges.clear();
      _quests.clear();
    }
  }

  // Save challenges to SharedPreferences
  Future<void> _saveChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save daily challenges
      final dailyChallengesJson = jsonEncode(
        _dailyChallenges.map((challenge) => challenge.toJson()).toList(),
      );
      await prefs.setString(_dailyChallengesKey, dailyChallengesJson);

      // Save quests
      final questsJson = jsonEncode(
        _quests.map((quest) => quest.toJson()).toList(),
      );
      await prefs.setString(_questsKey, questsJson);
    } catch (e) {
      debugPrint('Error saving challenges: $e');
    }
  }
}
