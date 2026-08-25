import '../models/finance_models.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetService {
  
  // Get all budgets for the current user
  static Future<List<Budget>> getAllBudgets() async {
    try {
      print('Fetching budgets from: ${ApiConfig.budgets}');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return [];
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      final data = await ApiService.get(ApiConfig.budgets);

      if (data != null && data['success'] == true && data['data'] != null) {
        final List<dynamic> budgetsJson = data['data'];
        print('✅ Successfully fetched ${budgetsJson.length} budgets');
        return budgetsJson.map((json) => _convertBackendBudget(json)).toList();
      } else {
        print('❌ API response format issue: ${data?.toString() ?? 'null response'}');
      }
      
      print('No budgets found or invalid response format');
      return [];
    } catch (e) {
      print('❌ Error fetching budgets: $e');
      return [];
    }
  }
  
  // Get a single budget by ID
  static Future<Budget?> getBudgetById(String id) async {
    try {
      print('Fetching budget with ID: $id from: ${ApiConfig.budgets}/$id');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      final data = await ApiService.get('${ApiConfig.budgets}/$id');

      if (data != null && data['success'] == true && data['data'] != null) {
        print('✅ Successfully fetched budget with ID: $id');
        return _convertBackendBudget(data['data']);
      } else {
        print('❌ API response format issue: ${data?.toString() ?? 'null response'}');
      }
      
      print('Budget not found or invalid response format');
      return null;
    } catch (e) {
      print('❌ Error fetching budget: $e');
      return null;
    }
  }
  
  // Create a new budget
  static Future<Budget?> createBudget(Budget budget) async {
    try {
      print('Creating budget at: ${ApiConfig.budgets}');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }
      
      // Convert budget to backend format
      final budgetData = _convertToBackendFormat(budget);
      print('📦 Budget data prepared for API: $budgetData');
      
      // Add detailed logging for the request
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      print('🌐 Sending POST request to: ${ApiConfig.budgets}');
      
      // Make the API request
      final data = await ApiService.post(
        ApiConfig.budgets,
        budgetData
      );
      
      // Handle the response
      if (data != null) {
        print('📡 Received response: $data');
        
        // Handle real API response
        if (data['success'] == true) {
          // Check if data is an object or an array
          if (data['data'] is Map) {
            // Single object response
            print('✅ Budget created successfully with ID: ${data['data']['_id'] ?? data['data']['id']}');
            return _convertBackendBudget(data['data']);
          } else if (data['data'] is List && data['data'].isNotEmpty) {
            // Array response (likely mock data)
            print('✅ Using mock data response');
            // Create a new budget with the mock data ID but our content
            final mockBudget = budget.copyWith(
              id: data['data'][0]['id'].toString(),
            );
            return mockBudget;
          }
        } else {
          print('❌ API returned error: ${data['message'] ?? 'Unknown error'}');
          print('❌ Error details: ${data['error'] ?? 'No details provided'}');
          return null;
        }
      }
      
      print('❌ Failed to create budget: No response data');
      return null;
    } catch (e, stackTrace) {
      print('❌ Error creating budget: $e');
      print('📜 Stack trace: $stackTrace');
      
      // Return the original budget as fallback
      // This ensures the local UI still works even if API fails
      return budget;
    }
  }
  
  // Update an existing budget
  static Future<Budget?> updateBudget(Budget budget) async {
    try {
      print('Updating budget with ID: ${budget.id} at: ${ApiConfig.budgets}/${budget.id}');
      print('Budget data: ${_convertToBackendFormat(budget)}');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      final data = await ApiService.put(
        '${ApiConfig.budgets}/${budget.id}',
        _convertToBackendFormat(budget)
      );
      
      if (data != null && data['success'] == true && data['data'] != null) {
        print('✅ Budget updated successfully with ID: ${budget.id}');
        return _convertBackendBudget(data['data']);
      } else {
        print('❌ Failed to update budget: ${data?['message'] ?? 'Unknown error'}');
      }
      
      return null;
    } catch (e) {
      print('❌ Error updating budget: $e');
      return null;
    }
  }
  
  // Delete a budget
  static Future<bool> deleteBudget(String id) async {
    try {
      print('Deleting budget with ID: $id from: ${ApiConfig.budgets}/$id');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return false;
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      final data = await ApiService.delete('${ApiConfig.budgets}/$id');
      
      if (data != null && data['success'] == true) {
        print('✅ Budget deleted successfully with ID: $id');
        return true;
      } else {
        print('❌ Failed to delete budget: ${data?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting budget: $e');
      return false;
    }
  }
  
  // Get active budgets
  // Get budgets that cross a utilization threshold (default 80%) or exceeded
  static Future<List<Budget>> getBudgetAlerts({double threshold = 80}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found.');
        return [];
      }

      final url = '${ApiConfig.budgets}/alerts?threshold=${threshold.toInt()}';
      print('🔔 Fetching budget alerts from: $url');
      final data = await ApiService.get(url);

      if (data != null && data['success'] == true && data['data'] != null) {
        final List<dynamic> alertsJson = data['data'];
        print('✅ Received ${alertsJson.length} budget alerts');
        return alertsJson.map((json) => _convertBackendBudget(json)).toList();
      }
      print('ℹ️ No budget alerts or invalid response.');
      return [];
    } catch (e) {
      print('❌ Error fetching budget alerts: $e');
      return [];
    }
  }

  static Future<List<Budget>> getActiveBudgets() async {
    try {
      print('Fetching active budgets from: ${ApiConfig.budgets}/active');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return [];
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      final data = await ApiService.get('${ApiConfig.budgets}/active');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final List<dynamic> budgetsJson = data['data'];
        print('✅ Successfully fetched ${budgetsJson.length} active budgets');
        return budgetsJson.map((json) => _convertBackendBudget(json)).toList();
      } else {
        print('❌ API response format issue: ${data?.toString() ?? 'null response'}');
      }
      
      print('No active budgets found or invalid response format');
      return [];
    } catch (e) {
      print('❌ Error fetching active budgets: $e');
      return [];
    }
  }
  
  // Helper method to convert backend budget format to frontend Budget model
  static Budget _convertBackendBudget(Map<String, dynamic> json) {
    // Log the received data for debugging
    print('📥 Budget data received from backend: $json');
    
    // Convert category string to TransactionCategory enum if it exists
    TransactionCategory? category;
    if (json['category'] != null) {
      try {
        final categoryStr = json['category'] as String;
        // Try to match by exact name first
        category = TransactionCategory.values.firstWhere(
          (e) => e.name == categoryStr || e.toString().split('.').last == categoryStr,
          orElse: () => TransactionCategory.other_expense
        );
        print('✅ Successfully mapped category: $categoryStr to ${category.toString()}');
      } catch (e) {
        print('⚠️ Error mapping category: $e');
        category = TransactionCategory.other_expense;
      }
    }
    
    // Handle numeric values properly with null safety
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return Budget(
      id: json['_id'] ?? json['id'] ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? 'Untitled Budget',
      limit: parseDouble(json['limit']),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now().add(const Duration(days: 30)),
      category: category,
      transactionIds: json['transactionIds'] != null 
          ? List<String>.from(json['transactionIds']) 
          : [],
      spent: parseDouble(json['spent']),
    );
  }
  
  // Helper method to convert frontend Budget model to backend format
  static Map<String, dynamic> _convertToBackendFormat(Budget budget) {
    // Create a base map with required fields
    final Map<String, dynamic> data = {
      'title': budget.title,
      'limit': budget.limit,
      'startDate': budget.startDate.toIso8601String(),
      'endDate': budget.endDate.toIso8601String(),
      'spent': budget.spent,
    };
    
    // Only add optional fields if they exist
    if (budget.category != null) {
      // Send the full category name as expected by the backend
      data['category'] = budget.category!.toString().split('.').last;
    }
    
    if (budget.transactionIds.isNotEmpty) {
      data['transactionIds'] = budget.transactionIds;
    }
    
    // Only include the ID if it's a valid MongoDB ObjectId (24 hex characters)
    // This prevents the "Cast to ObjectId failed" error
    if (!budget.id.startsWith('local_') && 
        RegExp(r'^[0-9a-f]{24}$').hasMatch(budget.id)) {
      data['_id'] = budget.id;
    }
    
    // Log the data being sent to help with debugging
    print('📤 Budget data being sent to backend: $data');
    
    return data;
  }
}
