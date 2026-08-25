import 'api_service.dart';
import '../app_config.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletApiService {
  static const String _endpoint = '/wallet';
  
  // Get wallet balance
  static Future<Map<String, dynamic>?> getWalletBalance() async {
    try {
      print('Fetching wallet balance from: ${ApiConfig.wallet}/balance');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      print('💰 Requesting wallet balance from endpoint: ${ApiConfig.wallet}/balance');
      final data = await ApiService.get(ApiConfig.wallet + '/balance');

      if (data != null && data['success'] == true && data['data'] != null) {
        print('✅ Successfully fetched wallet balance');
        return data['data'];
      } else {
        print('❌ API response format issue: ${data?.toString() ?? 'null response'}');
      }
      
      return null;
    } catch (e) {
      print('❌ Error fetching wallet balance: $e');
      return null;
    }
  }
  
  // Add money to wallet
  static Future<bool> addMoneyToWallet(double amount, String source) async {
    try {
      print('Adding money to wallet at: ${ApiConfig.wallet}/add');
      print('Amount: $amount, Source: $source');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return false;
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      print('💰 Adding money to wallet at endpoint: ${ApiConfig.wallet}/cash/add');
      final data = await ApiService.post(
        ApiConfig.wallet + '/cash/add',
        {
          'amount': amount,
          'source': source
        }
      );
      
      if (data != null && data['success'] == true) {
        print('✅ Successfully added money to wallet');
        return true;
      } else {
        print('❌ Failed to add money to wallet: ${data?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error adding money to wallet: $e');
      return false;
    }
  }
  
  // Withdraw money from wallet
  static Future<bool> withdrawFromWallet(double amount, String destination) async {
    try {
      print('Withdrawing money from wallet at: ${ApiConfig.wallet}/withdraw');
      print('Amount: $amount, Destination: $destination');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return false;
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      print('💰 Withdrawing money from wallet at endpoint: ${ApiConfig.wallet}/cash');
      // The backend uses PUT for updating cash amount
      final data = await ApiService.put(
        ApiConfig.wallet + '/cash',
        {
          'amount': amount,
          'updateReason': destination
        }
      );
      
      if (data != null && data['success'] == true) {
        print('✅ Successfully withdrew money from wallet');
        return true;
      } else {
        print('❌ Failed to withdraw money from wallet: ${data?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('❌ Error withdrawing from wallet: $e');
      return false;
    }
  }
  
  // Transfer money to another user
  static Future<bool> transferMoney(String recipientId, double amount, String note) async {
    try {
      final data = await ApiService.post(
        '${AppConfig.apiBaseUrl}$_endpoint/transfer',
        {
          'recipientId': recipientId,
          'amount': amount,
          'note': note
        }
      );
      
      return data != null && data['success'] == true;
    } catch (e) {
      print('Error transferring money: $e');
      return false;
    }
  }
  
  // Get wallet transaction history
  static Future<List<Map<String, dynamic>>> getWalletTransactions() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/transactions');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error fetching wallet transactions: $e');
      return [];
    }
  }
  
  // Pay bill
  static Future<bool> payBill(String billType, String billNumber, double amount, String provider) async {
    try {
      final data = await ApiService.post(
        '${AppConfig.apiBaseUrl}$_endpoint/pay-bill',
        {
          'billType': billType,
          'billNumber': billNumber,
          'amount': amount,
          'provider': provider
        }
      );
      
      return data != null && data['success'] == true;
    } catch (e) {
      print('Error paying bill: $e');
      return false;
    }
  }
  
  // Request money from another user
  static Future<bool> requestMoney(String fromUserId, double amount, String note) async {
    try {
      final data = await ApiService.post(
        '${AppConfig.apiBaseUrl}$_endpoint/request',
        {
          'fromUserId': fromUserId,
          'amount': amount,
          'note': note
        }
      );
      
      return data != null && data['success'] == true;
    } catch (e) {
      print('Error requesting money: $e');
      return false;
    }
  }
  
  // Get money requests (both sent and received)
  static Future<Map<String, List<Map<String, dynamic>>>> getMoneyRequests() async {
    try {
      final data = await ApiService.get('${AppConfig.apiBaseUrl}$_endpoint/requests');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        final Map<String, dynamic> requestsData = data['data'];
        
        return {
          'sent': List<Map<String, dynamic>>.from(requestsData['sent'] ?? []),
          'received': List<Map<String, dynamic>>.from(requestsData['received'] ?? [])
        };
      }
      
      return {'sent': [], 'received': []};
    } catch (e) {
      print('Error fetching money requests: $e');
      return {'sent': [], 'received': []};
    }
  }
  
  // Respond to money request (accept or reject)
  static Future<bool> respondToMoneyRequest(String requestId, bool accept) async {
    try {
      final data = await ApiService.post(
        '${AppConfig.apiBaseUrl}$_endpoint/requests/$requestId/${accept ? 'accept' : 'reject'}',
        {}
      );
      
      return data != null && data['success'] == true;
    } catch (e) {
      print('Error responding to money request: $e');
      return false;
    }
  }
}
