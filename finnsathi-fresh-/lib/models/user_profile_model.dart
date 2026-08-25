import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String membershipLevel;
  final double levelProgress;
  final String nextLevel;
  final int xp;
  final int level;
  final int points;
  final int rank;
  final int completedTransactions;
  final List<Achievement> achievements;
  final List<Trophy> trophies;
  final Map<String, dynamic> preferences;
  final List<String> badges;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.membershipLevel,
    required this.levelProgress,
    required this.nextLevel,
    required this.xp,
    required this.level,
    required this.points,
    required this.rank,
    required this.completedTransactions,
    required this.achievements,
    required this.trophies,
    required this.preferences,
    required this.badges,
  });

  // Create a mock user profile for development
  factory UserProfile.mock() {
    return UserProfile(
      id: 'usr_12345',
      name: 'Rohit Sharma',
      email: 'rohit.sharma@example.com',
      phone: '+91 98765 43210',
      avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      membershipLevel: 'Gold',
      levelProgress: 0.75,
      nextLevel: 'Platinum',
      xp: 1250,
      level: 5,
      points: 1250,
      rank: 42,
      completedTransactions: 87,
      badges: ['early_adopter', 'budget_master', 'saver_novice'],
      achievements: [
        Achievement(
          id: 'ach_001',
          title: 'First Transaction',
          description: 'Completed your first transaction',
          icon: 'trophy',
          isUnlocked: true,
        ),
        Achievement(
          id: 'ach_002',
          title: 'Savings Master',
          description: 'Saved more than ₹10,000 in a month',
          icon: 'piggy_bank',
          isUnlocked: true,
        ),
        Achievement(
          id: 'ach_003',
          title: 'Budget Pro',
          description: 'Stayed within budget for 3 consecutive months',
          icon: 'chart',
          isUnlocked: false,
        ),
        Achievement(
          id: 'ach_004',
          title: 'Investment Guru',
          description: 'Made your first investment',
          icon: 'trending_up',
          isUnlocked: false,
        ),
      ],
      trophies: [
        Trophy(
          id: 'trophy_001',
          title: 'Savings Champion',
          description: 'Saved ₹50,000 in total',
          rarity: TrophyRarity.rare,
          iconPath: 'assets/icons/trophies/savings_champion.png',
          dateAwarded: DateTime.now().subtract(const Duration(days: 15)),
          isUnlocked: true,
        ),
        Trophy(
          id: 'trophy_002',
          title: 'Budget Master',
          description: 'Stayed within budget for 5 consecutive months',
          rarity: TrophyRarity.epic,
          iconPath: 'assets/icons/trophies/budget_master.png',
          dateAwarded: null,
          isUnlocked: false,
        ),
        Trophy(
          id: 'trophy_003',
          title: 'First Investment',
          description: 'Made your first investment',
          rarity: TrophyRarity.common,
          iconPath: 'assets/icons/trophies/first_investment.png',
          dateAwarded: DateTime.now().subtract(const Duration(days: 45)),
          isUnlocked: true,
        ),
      ],
      preferences: {
        'notifications': true,
        'darkMode': true,
        'biometricAuth': true,
        'language': 'English',
        'currency': 'INR',
      },
    );
  }

  // Copy with method for updating profile
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? membershipLevel,
    double? levelProgress,
    String? nextLevel,
    int? xp,
    int? level,
    int? points,
    int? rank,
    int? completedTransactions,
    List<Achievement>? achievements,
    List<Trophy>? trophies,
    Map<String, dynamic>? preferences,
    List<String>? badges,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      membershipLevel: membershipLevel ?? this.membershipLevel,
      levelProgress: levelProgress ?? this.levelProgress,
      nextLevel: nextLevel ?? this.nextLevel,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      completedTransactions: completedTransactions ?? this.completedTransactions,
      achievements: achievements ?? this.achievements,
      trophies: trophies ?? this.trophies,
      preferences: preferences ?? this.preferences,
      badges: badges ?? this.badges,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? dateUnlocked;
  final int xpReward;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.dateUnlocked,
    this.xpReward = 50,
  });
}

enum TrophyRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary
}

class Trophy {
  final String id;
  final String title;
  final String description;
  final TrophyRarity rarity;
  final String iconPath;
  final DateTime? dateAwarded;
  final bool isUnlocked;
  final int xpReward;

  Trophy({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.iconPath,
    required this.isUnlocked,
    this.dateAwarded,
    this.xpReward = 100,
  });
  
  String get rarityName {
    switch (rarity) {
      case TrophyRarity.common:
        return 'Common';
      case TrophyRarity.uncommon:
        return 'Uncommon';
      case TrophyRarity.rare:
        return 'Rare';
      case TrophyRarity.epic:
        return 'Epic';
      case TrophyRarity.legendary:
        return 'Legendary';
    }
  }
  
  Color get rarityColor {
    switch (rarity) {
      case TrophyRarity.common:
        return Colors.grey.shade400;
      case TrophyRarity.uncommon:
        return Colors.green.shade400;
      case TrophyRarity.rare:
        return Colors.blue.shade400;
      case TrophyRarity.epic:
        return Colors.purple.shade400;
      case TrophyRarity.legendary:
        return Colors.orange.shade400;
    }
  }
}
