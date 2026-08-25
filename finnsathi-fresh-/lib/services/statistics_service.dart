import 'api_service.dart';
import '../app_config.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsService {
  static const String _endpoint = '/statistics';
  
  // Get spending by category for a specific time period
  static Future<Map<String, dynamic>> getSpendingByCategory({
    required String period, // 'week', 'month', 'year'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return {};
      }
      
      Map<String, dynamic> queryParams = {'period': period};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final url = _addQueryParameters(
        '${ApiConfig.statistics}/spending-by-category',
        queryParams
      );
      
      print('📈 Fetching spending by category from: $url');
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      
      final data = await ApiService.get(url);
      
      if (data != null && data['success'] == true && data['data'] != null) {
        print('✅ Successfully fetched spending by category data');
        return data['data'];
      } else {
        print('❌ API response format issue: ${data?.toString() ?? 'null response'}');
      }
      
      return {};
    } catch (e) {
      print('❌ Error fetching spending by category: $e');
      return {};
    }
  }
  
  // Get income vs expenses for a specific time period
  static Future<Map<String, dynamic>> getIncomeVsExpenses({
    required String period, // 'week', 'month', 'year'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return {};
      }
      
      Map<String, dynamic> queryParams = {'period': period};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final url = _addQueryParameters(
        '${ApiConfig.statistics}/income-vs-expenses',
        queryParams
      );
      
      print('📈 Fetching income vs expenses from: $url');
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      
      final data = await ApiService.get(url);
      
      if (data != null && data['success'] == true && data['data'] != null) {
        print('✅ Successfully fetched income vs expenses data');
        return data['data'];
      } else {
        print('❌ API response format issue: ${data?.toString() ?? 'null response'}');
      }
      
      return {};
    } catch (e) {
      print('❌ Error fetching income vs expenses: $e');
      return {};
    }
  }
  
  // Get spending trends over time
  static Future<List<Map<String, dynamic>>> getSpendingTrends({
    required String period, // 'week', 'month', 'year'
    required String interval, // 'day', 'week', 'month'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'period': period,
        'interval': interval
      };
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final url = _addQueryParameters(
        '${AppConfig.apiBaseUrl}$_endpoint/spending-trends',
        queryParams
      );
      
      final data = await ApiService.get(url);
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error fetching spending trends: $e');
      return [];
    }
  }
  
  // Get budget performance
  static Future<List<Map<String, dynamic>>> getBudgetPerformance() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/budget-performance');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error fetching budget performance: $e');
      return [];
    }
  }
  
  // Get savings goals progress
  static Future<List<Map<String, dynamic>>> getSavingsGoalsProgress() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/savings-goals-progress');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error fetching savings goals progress: $e');
      return [];
    }
  }
  
  // Get financial summary
  static Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/financial-summary');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error fetching financial summary: $e');
      return {};
    }
  }
  
  // Get transaction insights
  static Future<Map<String, dynamic>> getTransactionInsights() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/transaction-insights');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error fetching transaction insights: $e');
      return {};
    }
  }
}

// Helper method to add query parameters to URL
String _addQueryParameters(String url, Map<String, dynamic>? queryParameters) {
  if (queryParameters != null && queryParameters.isNotEmpty) {
    final queryString = Uri(queryParameters: queryParameters.map(
      (key, value) => MapEntry(key, value.toString())
    )).query;
    return '$url?$queryString';
  }
  return url;
}
