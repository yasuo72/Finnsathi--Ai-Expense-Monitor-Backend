import 'dart:convert';
import '../models/finance_models.dart';
import 'api_service.dart';
import '../app_config.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionService {
  static const String _endpoint = '/transactions';

  // Get all transactions for the current user
  static Future<List<Transaction>> getAllTransactions() async {
    try {
      print('Fetching transactions from: ${ApiConfig.transactions}');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return [];
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      final data = await ApiService.get(ApiConfig.transactions);

      if (data != null && data['success'] == true && data['data'] != null) {
        final List<dynamic> transactionsJson = data['data'];
        print('✅ Successfully fetched ${transactionsJson.length} transactions');
        
        // Count income and expense transactions for debugging
        int incomeCount = 0;
        int expenseCount = 0;
        
        for (var json in transactionsJson) {
          if (json['type'].toString().toLowerCase() == 'income') {
            incomeCount++;
          } else {
            expenseCount++;
          }
        }
        
        print('📊 Transaction breakdown - Income: $incomeCount, Expense: $expenseCount');
        
        // Convert and return transactions
        final transactions = transactionsJson.map((json) {
          final transaction = _convertBackendTransaction(json);
          print('🔄 Converted transaction: ${transaction.title}, Type: ${transaction.type.name}, Amount: ${transaction.amount}');
          return transaction;
        }).toList();
        
        return transactions;
      } else {
        print('❌ API response format issue: ${data?.toString() ?? 'null response'}');
      }

      print('No transactions found or invalid response format');
      return [];
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      return [];
    }
  }

  // Get a single transaction by ID
  static Future<Transaction?> getTransactionById(String id) async {
    try {
      final data = await ApiService.get(
        '${AppConfig.apiBaseUrl}$_endpoint/$id',
      );

      if (data != null && data['success'] == true && data['data'] != null) {
        return _convertBackendTransaction(data['data']);
      }

      return null;
    } catch (e) {
      print('Error fetching transaction: $e');
      return null;
    }
  }

  // Create a new transaction
  static Future<Transaction?> createTransaction(Transaction transaction) async {
    try {
      print('📊 TRANSACTION DEBUG: Starting transaction creation');
      print('📊 API Endpoint: ${ApiConfig.transactions}');
      
      // Convert transaction to backend format
      final transactionData = _convertToBackendFormat(transaction);
      print('📊 Transaction data to send: ${transactionData.toString()}');
      print('📊 Transaction JSON: ${jsonEncode(transactionData)}');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      
      // Make a single API call to create the transaction
      print('📊 Making API request to create transaction');
      final data = await ApiService.post(
        ApiConfig.transactions,
        transactionData,
      );

      if (data != null && data['success'] == true && data['data'] != null) {
        print('✅ Transaction created successfully with ID: ${data['data']['_id'] ?? data['data']['id']}');
        return _convertBackendTransaction(data['data']);
      }

      print('❌ Failed to create transaction: ${data?['message'] ?? 'Unknown error'}');
      if (data != null) {
        print('📊 Full response data: $data');
      }
      return null;
    } catch (e) {
      print('❌ Error creating transaction: $e');
      return null;
    }
  }

  // Update an existing transaction
  static Future<Transaction?> updateTransaction(Transaction transaction) async {
    try {
      print('Updating transaction at: ${ApiConfig.getTransactionById(transaction.id)}');
      print('Transaction data: ${_convertToBackendFormat(transaction)}');
      
      final data = await ApiService.put(
        ApiConfig.getTransactionById(transaction.id),
        _convertToBackendFormat(transaction),
      );

      if (data != null && data['success'] == true && data['data'] != null) {
        print('Transaction updated successfully with ID: ${data['data']['_id'] ?? data['data']['id']}');
        return _convertBackendTransaction(data['data']);
      }

      print('Failed to update transaction: ${data?['message'] ?? 'Unknown error'}');
      return null;
    } catch (e) {
      print('Error updating transaction: $e');
      return null;
    }
  }

  // Delete a transaction
  static Future<bool> deleteTransaction(String id) async {
    try {
      print('Deleting transaction at: ${ApiConfig.getTransactionById(id)}');
      
      final data = await ApiService.delete(
        ApiConfig.getTransactionById(id),
      );

      if (data != null && data['success'] == true) {
        print('Transaction deleted successfully');
        return true;
      }
      
      print('Failed to delete transaction: ${data?['message'] ?? 'Unknown error'}');
      return false;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // Get transactions for a specific date range
  static Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final url = _addQueryParameters(ApiConfig.transactions, {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });

      print('Fetching transactions by date range from: $url');
      final data = await ApiService.get(url);

      if (data != null && data['success'] == true && data['data'] != null) {
        final List<dynamic> transactionsJson = data['data'];
        print('Successfully fetched ${transactionsJson.length} transactions for date range');
        return transactionsJson
            .map((json) => _convertBackendTransaction(json))
            .toList();
      }

      print('No transactions found for date range or invalid response format');
      return [];
    } catch (e) {
      print('Error fetching transactions by date range: $e');
      return [];
    }
  }

  // Get transactions by category
  static Future<List<Transaction>> getTransactionsByCategory(
    TransactionCategory category,
  ) async {
    try {
      final url = _addQueryParameters(ApiConfig.transactions, {
        'category': category.name,
      });
      
      print('Fetching transactions by category from: $url');
      final data = await ApiService.get(url);

      if (data != null && data['success'] == true && data['data'] != null) {
        final List<dynamic> transactionsJson = data['data'];
        print('Successfully fetched ${transactionsJson.length} transactions for category ${category.name}');
        return transactionsJson
            .map((json) => _convertBackendTransaction(json))
            .toList();
      }

      print('No transactions found for category ${category.name} or invalid response format');
      return [];
    } catch (e) {
      print('Error fetching transactions by category: $e');
      return [];
    }
  }

  // Helper method to convert backend transaction format to frontend Transaction model
  static Transaction _convertBackendTransaction(Map<String, dynamic> json) {
    // Convert category string to TransactionCategory enum
    TransactionCategory category;
    try {
      final categoryStr = json['category'] as String;
      final typeStr = (json['type'] as String).toLowerCase();
      
      // First try to find an exact category match
      try {
        category = TransactionCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == categoryStr.toLowerCase(),
        );
      } catch (_) {
        // If no exact match, assign a default based on transaction type
        if (typeStr == 'income') {
          category = TransactionCategory.other_income;
        } else {
          category = TransactionCategory.other_expense;
        }
      }
    } catch (_) {
      // Fallback if any error occurs
      category = TransactionCategory.other_expense;
    }

    // Convert type string to TransactionType enum
    TransactionType type;
    try {
      final typeStr = json['type'] as String;
      // Check if the type is income or expense directly from the string
      if (typeStr.toLowerCase() == 'income') {
        type = TransactionType.income;
      } else {
        type = TransactionType.values.firstWhere(
          (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
          orElse: () => TransactionType.expense,
        );
      }
    } catch (_) {
      // Default to expense if there's an error
      type = TransactionType.expense;
    }

    return Transaction(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      category: category,
      type: type,
      attachmentPath: json['attachmentPath'],
    );
  }

  // Helper method to convert frontend Transaction model to backend format
  static Map<String, dynamic> _convertToBackendFormat(Transaction transaction) {
    // Simplify to the absolute minimum required fields in the exact format expected by the backend
    final Map<String, dynamic> data = {
      'title': transaction.title,
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'type': transaction.type == TransactionType.income ? 'income' : 'expense',
    };
    
    // Only add optional fields if they have values
    if (transaction.description != null && transaction.description!.isNotEmpty) {
      data['description'] = transaction.description;
    }
    
    // Add category - use the enum name without spaces for backend compatibility
    // The backend expects enum values like 'other_expense' not 'other expense'
    data['category'] = transaction.category.toString().split('.').last;
    
    // Only add attachmentPath if it exists and isn't empty
    if (transaction.attachmentPath != null && transaction.attachmentPath!.isNotEmpty) {
      data['attachmentPath'] = transaction.attachmentPath;
    }
    
    return data;
  }
}

// Helper method to add query parameters to URL
String _addQueryParameters(String url, Map<String, dynamic>? queryParameters) {
  if (queryParameters != null && queryParameters.isNotEmpty) {
    final queryString =
        Uri(
          queryParameters: queryParameters.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        ).query;
    return '$url?$queryString';
  }
  return url;
}
