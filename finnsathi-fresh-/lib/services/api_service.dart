import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import '../config/api_config.dart';
import 'auth_state_service.dart';

class ApiService {
  // Base URL for API requests
  static String get baseUrl => AppConfig.apiBaseUrl;

  // HTTP headers
  static Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Get auth token from shared preferences with enhanced fallback options
  static Future<String?> _getAuthToken() async {
    // Use AuthStateService to get the token for consistency
    final token = await AuthStateService.getAuthToken();

    // If we have a valid token, return it with debug info
    if (token != null && token.isNotEmpty) {
      print(
        '🔑 Using primary auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
      );
      return token;
    }

    // If primary token is missing, try all possible fallbacks
    print('⚠️ Primary token missing - trying fallbacks');
    final prefs = await SharedPreferences.getInstance();

    // Try all possible token keys in order of preference
    final possibleKeys = ['auth_token', 'token', 'access_token', 'jwt_token'];

    for (final key in possibleKeys) {
      final fallbackToken = prefs.getString(key);
      if (fallbackToken != null && fallbackToken.isNotEmpty) {
        print('🔄 Found fallback token in "$key"');
        return fallbackToken;
      }
    }

    print('❌ No valid auth token found in any location');
    return null;
  }

  // Save auth token to shared preferences
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear auth token (for logout)
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Generic GET request
  static Future<dynamic> get(String url, {bool requiresAuth = true}) async {
    // Use mock data if enabled
    if (AppConfig.useMockData) {
      return _getMockResponse(url);
    }

    try {
      print('🌐 API GET Request to: $url');

      // Validate URL format
      if (!url.startsWith('http')) {
        print('⚠️ URL does not have protocol, adding https://');
        if (!url.startsWith('/')) {
          url = 'https://$url';
        } else {
          url =
              'https://finnsathi-ai-expense-monitor-backend-production.up.railway.app$url';
        }
      }
      print('🌐 Normalized URL: $url');

      // Get auth headers with improved token handling
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      if (requiresAuth &&
          (headers['Authorization'] == null ||
              headers['Authorization']!.isEmpty)) {
        print('⚠️ Authorization header is missing or empty!');
        // Try to refresh the token from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          print(
            '🔄 Refreshed Authorization header with token from SharedPreferences',
          );
        } else {
          print(
            '❌ Failed to refresh Authorization header - no valid token found',
          );
        }
      }
      print('🔑 Headers: $headers');

      // Make the request with timeout
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Request timed out after 15 seconds');
              throw TimeoutException('Request timed out after 15 seconds');
            },
          );

      print('📥 Response Status: ${response.statusCode}');

      // Log response body with better formatting
      if (response.body.isNotEmpty) {
        try {
          final bodyPreview =
              response.body.length > 500
                  ? "${response.body.substring(0, 500)}..."
                  : response.body;
          print('📥 Response Body: $bodyPreview');

          // Try to parse as JSON for better logging
          final dynamic jsonBody = jsonDecode(response.body);
          if (jsonBody is Map && jsonBody.containsKey('success')) {
            print('📥 Success: ${jsonBody['success']}');
          }
        } catch (e) {
          print('⚠️ Could not parse response as JSON: $e');
        }
      } else {
        print('⚠️ Response body is empty');
      }

      return _handleResponse(response);
    } catch (e, stackTrace) {
      print('❌ API Error: $e');
      print('📜 Stack trace: $stackTrace');

      // If real API call fails, fall back to mock data
      return _getMockResponse(url);
    }
  }

  // Generic POST request
  static Future<dynamic> post(
    String url,
    dynamic body, {
    bool requiresAuth = true,
  }) async {
    // Use mock data if enabled
    if (AppConfig.useMockData) {
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Simulate network delay
      return _getMockResponse(url, body);
    }

    try {
      print('🌐 API POST Request to: $url');

      // Ensure body has required fields for savings goals (but NOT for /add or /withdraw endpoints)
      if (url.contains('savings-goals') &&
          !url.contains('/add') &&
          !url.contains('/withdraw') &&
          body is Map<String, dynamic>) {
        // Ensure required fields for savings goals (only for create/update endpoints)
        if (!body.containsKey('title') ||
            body['title'] == null ||
            body['title'].toString().isEmpty) {
          body['title'] = 'Unnamed Goal';
        }
        if (!body.containsKey('targetAmount') || body['targetAmount'] == null) {
          body['targetAmount'] = 0.0;
        }
        if (!body.containsKey('currentAmount') ||
            body['currentAmount'] == null) {
          body['currentAmount'] = 0.0;
        }

        // Add 'name' field which is required by the backend
        // The backend expects 'name' instead of or in addition to 'title'
        body['name'] = body['title'];

        print('💡 Enhanced request body with required fields for savings goal');
      }

      final bodyJson = jsonEncode(body);
      print('📦 Request Body: $bodyJson');

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      print('🔑 Headers: $headers');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: bodyJson,
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Enhanced error handling for common HTTP errors
      if (response.statusCode >= 400) {
        print('❌ HTTP Error ${response.statusCode}: ${response.reasonPhrase}');
        try {
          final errorJson = jsonDecode(response.body);
          print(
            '❌ Error details: ${errorJson['message'] ?? errorJson['error'] ?? 'Unknown error'}',
          );

          // For 400 Bad Request errors, log more details about the request
          if (response.statusCode == 400) {
            print('⚠️ Bad Request Details:');
            print('  - URL: $url');
            print('  - Headers: $headers');
            print('  - Body: $bodyJson');
            print('  - Response: ${response.body}');
          }
        } catch (e) {
          print('❌ Could not parse error response: $e');
        }
      }

      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
      // Only fall back to mock data on network errors, not parsing errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        print('⚠️ Network error - using mock data as fallback');
        return _getMockResponse(url, body);
      }
      // Re-throw parsing errors so we can see them
      rethrow;
    }
  }

  // Generic PUT request
  static Future<dynamic> put(
    String url,
    dynamic body, {
    bool requiresAuth = true,
  }) async {
    // Use mock data if enabled
    if (AppConfig.useMockData) {
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Simulate network delay
      return _getMockResponse(url, body);
    }

    try {
      print('🌐 API PUT Request to: $url');
      print('📦 Request Body: ${jsonEncode(body)}');

      final headers = await _getHeaders(requiresAuth: requiresAuth);
      print('🔑 Headers: $headers');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
      // Only fall back to mock data on network errors, not parsing errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        print('⚠️ Network error - using mock data as fallback');
        return _getMockResponse(url, body);
      }
      // Re-throw parsing errors so we can see them
      rethrow;
    }
  }

  // Generic DELETE request
  static Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    // Use mock data if enabled
    if (AppConfig.useMockData) {
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Simulate network delay
      return _getMockResponse(url);
    }

    try {
      // Normalize URL to ensure it's properly formatted
      if (!url.startsWith('http')) {
        // If URL doesn't start with http/https, assume it's a relative path
        if (!url.startsWith('/')) {
          url = '/$url';
        }
        url = ApiConfig.baseUrl + url;
      }

      print('🌐 API DELETE Request to: $url');

      // Get auth token with fallback mechanism
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      if (requiresAuth &&
          (headers['Authorization'] == null ||
              headers['Authorization']!.isEmpty)) {
        // Try alternative token keys if the primary one failed
        final prefs = await SharedPreferences.getInstance();
        final alternativeToken = prefs.getString('token');

        if (alternativeToken != null && alternativeToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $alternativeToken';
          print('🔄 Using alternative token key');
        } else {
          print('⚠️ No valid auth token found for DELETE request');
        }
      }

      print('🔑 Headers: $headers');

      // Add timeout to prevent hanging requests
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏱️ DELETE request timed out after 15 seconds');
              throw TimeoutException('Request timed out');
            },
          );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Special handling for 401 Unauthorized - token might be expired
      if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        // Here you could implement token refresh logic if needed
      }

      return _handleResponse(response);
    } catch (e) {
      print('❌ API DELETE Error: $e');
      // Return error information instead of mock data for better debugging
      return {
        'success': false,
        'message': 'Error during DELETE request: $e',
        'error': e.toString(),
      };
    }
  }

  // Handle HTTP response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success response
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      // Error response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        throw Exception('API Error (${response.statusCode}): $errorMessage');
      } catch (e) {
        throw Exception(
          'API Error (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    }
  }

  // Get mock response based on path
  static Map<String, dynamic> _getMockResponse(
    String url, [
    Map<String, dynamic>? body,
  ]) {
    // Extract the endpoint from the URL
    final Uri uri = Uri.parse(url);
    final String path = uri.path;

    // Handle auth endpoints
    if (path.contains('/auth/register') || path.contains('/auth/signup')) {
      final name = body?['name'] ?? 'Demo User';
      final email = body?['email'] ?? 'demo@example.com';
      final token = 'mock_auth_token_${DateTime.now().millisecondsSinceEpoch}';

      return {
        'success': true,
        'message': 'User registered successfully',
        'token': token,
        'user': {
          'name': name,
          'email': email,
          'dob': body?['dob'] ?? '2000-01-01',
        },
      };
    } else if (path.contains('/auth/login') || path.contains('/auth/signin')) {
      final email = body?['email'] ?? 'demo@example.com';
      final token = 'mock_auth_token_${DateTime.now().millisecondsSinceEpoch}';

      return {
        'success': true,
        'message': 'User logged in successfully',
        'token': token,
        'user': {'name': 'Demo User', 'email': email, 'dob': '2000-01-01'},
      };
    } else if (path.contains('/transactions')) {
      // For new users, return empty transaction data
      return {'success': true, 'data': []};
    } else if (path.contains('/budgets')) {
      final now = DateTime.now();
      return {
        'success': true,
        'data': [
          {
            'id': '1',
            'title': 'Monthly Food Budget',
            'category': 'food',
            'limit': 10000,
            'spent': 3500,
            'startDate': DateTime(now.year, now.month, 1).toIso8601String(),
            'endDate': DateTime(now.year, now.month + 1, 0).toIso8601String(),
            'transactionIds': [],
            'isActive': true,
          },
          {
            'id': '2',
            'title': 'Entertainment Budget',
            'category': 'entertainment',
            'limit': 5000,
            'spent': 2000,
            'startDate': DateTime(now.year, now.month, 1).toIso8601String(),
            'endDate': DateTime(now.year, now.month + 1, 0).toIso8601String(),
            'transactionIds': [],
            'isActive': true,
          },
        ],
      };
    } else if (path.contains('/savings-goals')) {
      final now = DateTime.now();
      return {
        'success': true,
        'data': [
          {
            'id': '1',
            'title': 'Vacation',
            'description': 'Summer vacation fund',
            'targetAmount': 50000,
            'currentAmount': 20000,
            'createdDate':
                now.subtract(const Duration(days: 30)).toIso8601String(),
            'targetDate': now.add(const Duration(days: 90)).toIso8601String(),
            'color': 0xFF2196F3, // Blue color
            'iconName': 'beach_access',
          },
          {
            'id': '2',
            'title': 'New Laptop',
            'description': 'For work and gaming',
            'targetAmount': 80000,
            'currentAmount': 30000,
            'createdDate':
                now.subtract(const Duration(days: 60)).toIso8601String(),
            'targetDate': now.add(const Duration(days: 180)).toIso8601String(),
            'color': 0xFF4CAF50, // Green color
            'iconName': 'laptop',
          },
        ],
      };
    } else if (path.contains('/wallet')) {
      return {
        'success': true,
        'data': {
          'balance': 25000,
          'cards': [
            {'id': '1', 'name': 'Main Card', 'balance': 15000},
            {'id': '2', 'name': 'Savings Card', 'balance': 10000},
          ],
          'cash': 5000,
        },
      };
    } else if (path.contains('/notifications')) {
      return {
        'success': true,
        'data': [
          {
            'id': '1',
            'title': 'Budget Alert',
            'message': 'You are close to your Food budget limit',
            'read': false,
            'date':
                DateTime.now()
                    .subtract(const Duration(hours: 5))
                    .toIso8601String(),
          },
          {
            'id': '2',
            'title': 'Savings Goal',
            'message': 'You are 40% towards your Vacation goal',
            'read': true,
            'date':
                DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
          },
        ],
      };
    } else if (path.contains('/statistics')) {
      if (path.contains('/spending-by-category')) {
        return {
          'success': true,
          'data': [
            {'category': 'Food', 'amount': 5500},
            {'category': 'Entertainment', 'amount': 2000},
            {'category': 'Transportation', 'amount': 3000},
          ],
        };
      } else if (path.contains('/income-vs-expense')) {
        return {
          'success': true,
          'data': {'income': 50000, 'expense': 10500},
        };
      }
    } else if (path.contains('/predictions')) {
      return {
        'success': true,
        'data': {
          'nextMonth': 12000,
          'trend': 'increasing',
          'categories': [
            {'category': 'Food', 'amount': 6000},
            {'category': 'Entertainment', 'amount': 3000},
            {'category': 'Transportation', 'amount': 3000},
          ],
        },
      };
    } else if (path.contains('/chatbot')) {
      return {
        'success': true,
        'data': {
          'text': 'I\'m here to help with your finances!',
          'intent': 'greeting',
          'confidence': 0.9,
        },
      };
    }

    // Default response for any other endpoint
    return {'success': true, 'message': 'Mock data response', 'data': {}};
  }
}
