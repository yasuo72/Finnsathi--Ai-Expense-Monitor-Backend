import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  // Base URL for the API
  static String get baseUrl {
    // Try to get from .env file first
    final envUrl = dotenv.env['API_BASE_URL'];
    
    // If not found in .env, use Railway backend URL with explicit https protocol
    return envUrl ?? 'https://finnsathi-ai-expense-monitor-backend-production.up.railway.app/api';
    // Note: Previous default was 'http://10.0.2.2:5000/api' for Android emulators
    // and 'http://localhost:5000/api' for iOS simulator
  }
  
  // Debug method to test backend connection
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse(baseUrl.replaceAll('/api', ''));
      print('Testing connection to: $url');
      final response = await http.get(url);
      print('Connection test status: ${response.statusCode}');
      print('Connection test response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Connection test error: $e');
      return false;
    }
  }

  // Auth endpoints
  static String get login => '$baseUrl/auth/signin';
  static String get register => '$baseUrl/auth/signup';
  
  // User endpoints
  static String get users => '$baseUrl/users';
  static String getUserById(String id) => '$users/$id';
  
  // Transaction endpoints
  static String get transactions => '$baseUrl/transactions';
  static String getTransactionById(String id) => '$transactions/$id';
  
  // Budget endpoints
  static String get budgets => '$baseUrl/budgets';
  static String getBudgetById(String id) => '$budgets/$id';
  
  // Savings goal endpoints
  static String get savingsGoals => '$baseUrl/savings-goals';
  static String getSavingsGoalById(String id) => '$savingsGoals/$id';
  
  // Wallet endpoints
  static String get wallet => '$baseUrl/wallet';
  
  // Gamification endpoints
  static String get gamification => '$baseUrl/gamification';
  
  // Statistics endpoints
  static String get statistics => '$baseUrl/statistics';
  
  // Notification endpoints
  static String get notifications => '$baseUrl/notifications';
  
  // Chatbot endpoints
  static String get chatbot => '$baseUrl/chatbot';
  
  // Prediction endpoints
  static String get predictions => '$baseUrl/predictions';
}
