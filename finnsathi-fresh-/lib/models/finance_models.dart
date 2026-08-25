import 'package:flutter/material.dart';
import 'dart:math';

enum TransactionType { income, expense }
enum TransactionCategory {
  // Income categories
  salary,
  investment,
  gifts,
  business,
  rent,
  other_income,
  
  // Expense categories
  shopping,
  food,
  transport,
  entertainment,
  bills,
  health,
  education,
  travel,
  home,
  groceries,
  other_expense
}

// Extension to get category metadata
extension CategoryMetadata on TransactionCategory {
  String get name {
    return toString().split('.').last.replaceAll('_', ' ');
  }
  
  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
  
  Color get color {
    switch (this) {
      case TransactionCategory.salary: return Colors.green.shade500;
      case TransactionCategory.investment: return Colors.blue.shade500;
      case TransactionCategory.gifts: return Colors.purple.shade400;
      case TransactionCategory.business: return Colors.amber.shade600;
      case TransactionCategory.rent: return Colors.cyan.shade500;
      case TransactionCategory.other_income: return Colors.teal.shade500;
      
      case TransactionCategory.shopping: return Colors.red.shade400;
      case TransactionCategory.food: return Colors.orange.shade500;
      case TransactionCategory.transport: return Colors.indigo.shade400;
      case TransactionCategory.entertainment: return Colors.pink.shade400;
      case TransactionCategory.bills: return Colors.red.shade600;
      case TransactionCategory.health: return Colors.teal.shade500;
      case TransactionCategory.education: return Colors.blue.shade700;
      case TransactionCategory.travel: return Colors.green.shade600;
      case TransactionCategory.home: return Colors.brown.shade500;
      case TransactionCategory.groceries: return Colors.deepOrange.shade500;
      case TransactionCategory.other_expense: return Colors.grey.shade600;
    }
  }
  
  IconData get icon {
    switch (this) {
      case TransactionCategory.salary: return Icons.account_balance_wallet;
      case TransactionCategory.investment: return Icons.trending_up;
      case TransactionCategory.gifts: return Icons.card_giftcard;
      case TransactionCategory.business: return Icons.business;
      case TransactionCategory.rent: return Icons.home_work;
      case TransactionCategory.other_income: return Icons.money;
      
      case TransactionCategory.shopping: return Icons.shopping_bag;
      case TransactionCategory.food: return Icons.restaurant;
      case TransactionCategory.transport: return Icons.directions_car;
      case TransactionCategory.entertainment: return Icons.movie;
      case TransactionCategory.bills: return Icons.receipt_long;
      case TransactionCategory.health: return Icons.healing;
      case TransactionCategory.education: return Icons.school;
      case TransactionCategory.travel: return Icons.flight;
      case TransactionCategory.home: return Icons.home;
      case TransactionCategory.groceries: return Icons.shopping_cart;
      case TransactionCategory.other_expense: return Icons.category;
    }
  }
  
  TransactionType get transactionType {
    switch (this) {
      case TransactionCategory.salary:
      case TransactionCategory.investment:
      case TransactionCategory.gifts:
      case TransactionCategory.business:
      case TransactionCategory.rent:
      case TransactionCategory.other_income:
        return TransactionType.income;
      default:
        return TransactionType.expense;
    }
  }
  
  static List<TransactionCategory> incomeCategories = [
    TransactionCategory.salary,
    TransactionCategory.investment,
    TransactionCategory.gifts,
    TransactionCategory.business,
    TransactionCategory.rent,
    TransactionCategory.other_income,
  ];
  
  static List<TransactionCategory> expenseCategories = [
    TransactionCategory.shopping,
    TransactionCategory.food,
    TransactionCategory.transport,
    TransactionCategory.entertainment,
    TransactionCategory.bills,
    TransactionCategory.health,
    TransactionCategory.education,
    TransactionCategory.travel,
    TransactionCategory.home,
    TransactionCategory.groceries,
    TransactionCategory.other_expense,
  ];
}

class Transaction {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final DateTime date;
  final TransactionCategory category;
  final TransactionType type;
  final String? attachmentPath;
  
  Transaction({
    String? id,
    required this.title,
    this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.attachmentPath,
  }) : id = id ?? _generateId();
  
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(10000).toString();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description ?? '',
      'amount': amount,
      'date': date.toIso8601String(),
      // Use just the name part of the enum (after the dot)
      'category': category.name,
      // Use just the name part of the enum (after the dot)
      'type': type.name,
      // Only include attachmentPath if it's not null
      if (attachmentPath != null) 'attachmentPath': attachmentPath,
    };
  }
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB _id field or regular id field
    final id = json['_id'] ?? json['id'] ?? '';
    
    // Parse amount safely - handle both numeric and string values
    double amount;
    final rawAmount = json['amount'];
    if (rawAmount is double) {
      amount = rawAmount;
    } else if (rawAmount is int) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      amount = double.tryParse(rawAmount) ?? 0.0;
    } else {
      amount = 0.0;
    }
    
    // Parse date safely
    DateTime date;
    try {
      date = DateTime.parse(json['date']);
    } catch (e) {
      date = DateTime.now();
      print('Error parsing date: ${json['date']}');
    }
    
    // Parse category - handle both full enum string and just the name
    TransactionCategory category;
    final categoryValue = json['category'];
    if (categoryValue is String) {
      try {
        // First try to match by name (e.g., 'food', 'salary')
        category = TransactionCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == categoryValue.toLowerCase(),
          orElse: () {
            // Then try to match by full enum string (e.g., 'TransactionCategory.food')
            return TransactionCategory.values.firstWhere(
              (e) => e.toString().toLowerCase() == categoryValue.toLowerCase(),
              orElse: () {
                // Default based on transaction type
                final typeStr = json['type']?.toString().toLowerCase() ?? '';
                return typeStr == 'income' ? 
                  TransactionCategory.other_income : 
                  TransactionCategory.other_expense;
              }
            );
          }
        );
      } catch (e) {
        print('Error parsing category: $categoryValue');
        category = TransactionCategory.other_expense;
      }
    } else {
      category = TransactionCategory.other_expense;
    }
    
    // Parse transaction type - handle both full enum string and just the name
    TransactionType type;
    final typeValue = json['type'];
    if (typeValue is String) {
      final typeStr = typeValue.toLowerCase();
      if (typeStr == 'income') {
        type = TransactionType.income;
      } else if (typeStr == 'expense') {
        type = TransactionType.expense;
      } else {
        try {
          type = TransactionType.values.firstWhere(
            (e) => e.name.toLowerCase() == typeStr || e.toString().toLowerCase() == typeStr,
            orElse: () => TransactionType.expense
          );
        } catch (e) {
          print('Error parsing transaction type: $typeValue');
          type = TransactionType.expense;
        }
      }
    } else {
      type = TransactionType.expense;
    }
    
    return Transaction(
      id: id,
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      amount: amount,
      date: date,
      category: category,
      type: type,
      attachmentPath: json['attachmentPath'],
    );
  }
  
  Transaction copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    DateTime? date,
    TransactionCategory? category,
    TransactionType? type,
    String? attachmentPath,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }
}

class Budget {
  final String id;
  final String title;
  final double limit;
  final DateTime startDate;
  final DateTime endDate;
  final TransactionCategory? category;
  final List<String> transactionIds; // IDs of transactions to track
  final double spent;
  
  Budget({
    String? id,
    required this.title,
    required this.limit,
    required this.startDate,
    required this.endDate,
    this.category,
    List<String>? transactionIds,
    double? spent,
  }) : 
    id = id ?? _generateId(),
    transactionIds = transactionIds ?? [],
    spent = spent ?? 0.0;
    
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(10000).toString();
  }
  
  // Remaining budget amount
  double get remaining => limit - spent;
  
  // Progress percentage (0.0 to 1.0)
  double get progress => spent / limit;
  
  // Determine if budget is exceeded
  bool get isExceeded => spent > limit;
  
  // Determine if budget is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'limit': limit,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'category': category?.toString(),
      'transactionIds': transactionIds,
      'spent': spent,
    };
  }
  
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      title: json['title'],
      limit: json['limit'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      category: json['category'] != null ? 
          TransactionCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
            orElse: () => TransactionCategory.other_expense
          ) : null,
      transactionIds: List<String>.from(json['transactionIds'] ?? []),
      spent: json['spent'] ?? 0.0,
    );
  }
  
  Budget copyWith({
    String? id,
    String? title,
    double? limit,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    List<String>? transactionIds,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      title: title ?? this.title,
      limit: limit ?? this.limit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      transactionIds: transactionIds ?? this.transactionIds,
      spent: spent ?? this.spent,
    );
  }
}

class SavingsGoal {
  final String id;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime createdDate;
  final DateTime? targetDate;
  final Color color;
  final String? iconName;
  
  SavingsGoal({
    String? id,
    required this.title,
    this.description,
    required this.targetAmount,
    double? currentAmount,
    DateTime? createdDate,
    this.targetDate,
    Color? color,
    this.iconName,
  }) : 
    id = id ?? _generateId(),
    currentAmount = currentAmount ?? 0.0,
    createdDate = createdDate ?? DateTime.now(),
    color = color ?? Colors.primaries[Random().nextInt(Colors.primaries.length)];
  
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(10000).toString();
  }
  
  // Progress percentage (0.0 to 1.0)
  double get progress => currentAmount / targetAmount;
  
  // Remaining amount to save
  double get remainingAmount => targetAmount - currentAmount;
  
  // Determine if goal is completed
  bool get isCompleted => currentAmount >= targetAmount;
  
  // Days remaining until target date
  int get daysRemaining {
    if (targetDate == null) return 0;
    final today = DateTime.now();
    return targetDate!.difference(today).inDays;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'createdDate': createdDate.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'color': color.value,
      'iconName': iconName,
    };
  }
  
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targetAmount: json['targetAmount'],
      currentAmount: json['currentAmount'],
      createdDate: DateTime.parse(json['createdDate']),
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      color: Color(json['color']),
      iconName: json['iconName'],
    );
  }
  
  SavingsGoal copyWith({
    String? id,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? createdDate,
    DateTime? targetDate,
    Color? color,
    String? iconName,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      createdDate: createdDate ?? this.createdDate,
      targetDate: targetDate ?? this.targetDate,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
    );
  }
}
