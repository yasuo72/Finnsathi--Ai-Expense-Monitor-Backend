import 'api_service.dart';
import '../app_config.dart';

class ChatbotApiService {
  static const String _endpoint = '/chatbot';
  
  // Send a message to the chatbot and get a response
  static Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final data = await ApiService.post(
        '${AppConfig.apiBaseUrl}$_endpoint/message',
        {'message': message}
      );
      
      if (data != null && data['success'] == true) {
        return {
          'intent': data['intent'] ?? 'unknown',
          'score': data['score'] ?? 0.0,
          'answer': data['answer'] ?? 'Sorry, I couldn\'t process your request.',
          'entities': data['entities'] ?? []
        };
      }
      
      return {
        'intent': 'error',
        'score': 0.0,
        'answer': 'Failed to get response from the chatbot.',
        'entities': []
      };
    } catch (e) {
      print('Error sending message to chatbot: $e');
      return {
        'intent': 'error',
        'score': 0.0,
        'answer': 'An error occurred while communicating with the chatbot.',
        'entities': []
      };
    }
  }
  
  // Get financial insights from the chatbot
  static Future<Map<String, dynamic>> getFinancialInsights() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/insights');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      
      return {};
    } catch (e) {
      print('Error getting financial insights: $e');
      return {};
    }
  }
  
  // Get spending recommendations
  static Future<List<String>> getSpendingRecommendations() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/recommendations/spending');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<String>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error getting spending recommendations: $e');
      return [];
    }
  }
  
  // Get savings recommendations
  static Future<List<String>> getSavingsRecommendations() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/recommendations/savings');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<String>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error getting savings recommendations: $e');
      return [];
    }
  }
  
  // Get budget recommendations
  static Future<List<String>> getBudgetRecommendations() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/recommendations/budget');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<String>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error getting budget recommendations: $e');
      return [];
    }
  }
  
  // Gemini expense analysis (new)
  static Future<String> analyzeExpenses(List<Map<String, dynamic>> expenses) async {
    try {
      final data = await ApiService.post(
        '${AppConfig.apiBaseUrl}/gemini/analyze-expenses',
        {
          'expenses': expenses,
        },
      );

      if (data != null && data['analysis'] != null) {
        return data['analysis'] as String;
      }
      return 'No analysis available.';
    } catch (e) {
      print('Error analyzing expenses via Gemini: $e');
      return 'Failed to analyze expenses.';
    }
  }

  // Add a transaction through the chatbot (natural language processing)
  static Future<Map<String, dynamic>> addTransactionFromText(String text) async {
    try {
      final data = await ApiService.post(
        '${AppConfig.apiBaseUrl}$_endpoint/add-transaction',
        {'text': text}
      );
      
      if (data != null && data['success'] == true) {
        return {
          'success': true,
          'transaction': data['transaction'],
          'message': data['message'] ?? 'Transaction added successfully.'
        };
      }
      
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add transaction.'
      };
    } catch (e) {
      print('Error adding transaction from text: $e');
      return {
        'success': false,
        'message': 'An error occurred while processing your request.'
      };
    }
  }
}
