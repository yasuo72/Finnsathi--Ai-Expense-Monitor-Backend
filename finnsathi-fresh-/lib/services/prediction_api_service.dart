import 'api_service.dart';
import '../app_config.dart';

class PredictionApiService {
  static const String _endpoint = '/predictions';
  
  // Get spending prediction for next month
  static Future<Map<String, dynamic>> getSpendingPrediction() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/spending');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error fetching spending prediction: $e');
      return {};
    }
  }
  
  // Get savings goal prediction (time to reach goal)
  static Future<Map<String, dynamic>> getSavingsGoalPrediction(String goalId) async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/savings-goal/$goalId');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error fetching savings goal prediction: $e');
      return {};
    }
  }
  
  // Get budget prediction (likelihood of staying within budget)
  static Future<Map<String, dynamic>> getBudgetPrediction(String budgetId) async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/budget/$budgetId');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error fetching budget prediction: $e');
      return {};
    }
  }
  
  // Get financial health prediction
  static Future<Map<String, dynamic>> getFinancialHealthPrediction() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/financial-health');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error fetching financial health prediction: $e');
      return {};
    }
  }
  
  // Get category-specific spending predictions
  static Future<Map<String, dynamic>> getCategorySpendingPrediction(String category) async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/category/$category');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error fetching category spending prediction: $e');
      return {};
    }
  }
  
  // Get income prediction for next month
  static Future<Map<String, dynamic>> getIncomePrediction() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/income');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error fetching income prediction: $e');
      return {};
    }
  }
  
  // Get cash flow prediction for next few months
  static Future<List<Map<String, dynamic>>> getCashFlowPrediction(int months) async {
    try {
      final url = _addQueryParameters(
        '${AppConfig.apiBaseUrl}$_endpoint/cash-flow',
        {'months': months}
      );
      
      final data = await ApiService.get(url);
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error fetching cash flow prediction: $e');
      return [];
    }
  }
  
  // Get anomaly detection (unusual spending patterns)
  static Future<List<Map<String, dynamic>>> getAnomalyDetection() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/anomalies');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error fetching anomaly detection: $e');
      return [];
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
