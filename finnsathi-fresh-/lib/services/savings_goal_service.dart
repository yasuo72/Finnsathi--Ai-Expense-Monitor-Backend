import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/finance_models.dart';
import 'api_service.dart';

class SavingsGoalService {
  // Get all savings goals for the current user
  static Future<List<SavingsGoal>> getAllSavingsGoals() async {
    try {
      print('🌐 Fetching savings goals from: ${ApiConfig.savingsGoals}');

      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final altToken = prefs.getString('token'); // Try alternative token key
      final effectiveToken = token ?? altToken;

      if (effectiveToken == null || effectiveToken.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        print(
          '⚠️ Checked both "auth_token" and "token" keys in SharedPreferences',
        );
        return [];
      }

      print(
        '🔑 Using auth token: ${effectiveToken.substring(0, effectiveToken.length > 10 ? 10 : effectiveToken.length)}...',
      );

      // Add detailed request logging
      print('📤 Making GET request to: ${ApiConfig.savingsGoals}');
      final data = await ApiService.get(ApiConfig.savingsGoals);

      // Log the raw response for debugging
      print(
        '📥 Received response: ${data != null ? 'data present' : 'null response'}',
      );
      if (data != null) {
        print('📄 Response success flag: ${data['success']}');
        print('📄 Response has data: ${data['data'] != null}');
        if (data['data'] != null) {
          print('📄 Response data type: ${data['data'].runtimeType}');
          if (data['data'] is List) {
            print('📄 Response data length: ${(data['data'] as List).length}');
          }
        }
      }

      if (data != null && data['success'] == true && data['data'] != null) {
        final List<dynamic> savingsGoalsJson = data['data'];
        print(
          '✅ Successfully fetched ${savingsGoalsJson.length} savings goals',
        );

        // Log each savings goal ID for debugging
        for (var i = 0; i < savingsGoalsJson.length; i++) {
          final goal = savingsGoalsJson[i];
          print(
            '  📌 Goal ${i + 1}: ID=${goal['_id'] ?? goal['id'] ?? 'unknown'}, Title=${goal['title'] ?? goal['name'] ?? 'unnamed'}',
          );
        }

        return savingsGoalsJson
            .map((json) => _convertBackendSavingsGoal(json))
            .toList();
      } else {
        print(
          '❌ API response format issue: ${data?.toString() ?? 'null response'}',
        );

        // Check for specific error conditions
        if (data != null && data['message'] != null) {
          print('❌ API error message: ${data['message']}');
        }
        if (data != null && data['error'] != null) {
          print('❌ API error details: ${data['error']}');
        }
      }

      print('⚠️ No savings goals found or invalid response format');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching savings goals: $e');
      print('📜 Stack trace: $stackTrace');
      return [];
    }
  }

  // Get a single savings goal by ID
  static Future<SavingsGoal?> getSavingsGoalById(String id) async {
    try {
      print(
        'Fetching savings goal with ID: $id from: ${ApiConfig.savingsGoals}/$id',
      );

      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }

      print(
        '🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
      );
      final data = await ApiService.get('${ApiConfig.savingsGoals}/$id');

      if (data != null && data['success'] == true && data['data'] != null) {
        print('✅ Successfully fetched savings goal with ID: $id');
        return _convertBackendSavingsGoal(data['data']);
      } else {
        print(
          '❌ API response format issue: ${data?.toString() ?? 'null response'}',
        );
      }

      print('Savings goal not found or invalid response format');
      return null;
    } catch (e) {
      print('❌ Error fetching savings goal: $e');
      return null;
    }
  }

  // Create a new savings goal
  static Future<SavingsGoal?> createSavingsGoal(SavingsGoal savingsGoal) async {
    try {
      print('Creating savings goal at: ${ApiConfig.savingsGoals}');

      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }

      // Convert savings goal to backend format
      final savingsGoalData = _convertToBackendFormat(savingsGoal);
      print('📦 Savings goal data prepared for API: $savingsGoalData');

      // Log the color being sent to the backend
      print(
        '🎨 Sending color value: 0x${savingsGoal.color.value.toRadixString(16).toUpperCase()}',
      );

      // Add detailed logging for the request
      print(
        '🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
      );
      print('🌐 Sending POST request to: ${ApiConfig.savingsGoals}');

      // Ensure required fields are present to avoid 400 Bad Request
      if (savingsGoalData['title'] == null ||
          savingsGoalData['title'].isEmpty) {
        savingsGoalData['title'] = 'Unnamed Goal';
      }
      if (savingsGoalData['targetAmount'] == null) {
        savingsGoalData['targetAmount'] = 0.0;
      }

      // Make the API request
      final data = await ApiService.post(
        ApiConfig.savingsGoals,
        savingsGoalData,
      );

      // Handle the response
      if (data != null) {
        print('📡 Received response: $data');

        // Handle real API response
        if (data['success'] == true) {
          // Check if data is an object or an array
          if (data['data'] is Map) {
            // Single object response
            print(
              '✅ Savings goal created successfully with ID: ${data['data']['_id'] ?? data['data']['id']}',
            );
            return _convertBackendSavingsGoal(data['data']);
          } else if (data['data'] is List && data['data'].isNotEmpty) {
            // Array response (likely mock data)
            print('✅ Using mock data response');
            // Create a new savings goal with the mock data ID but our content
            final mockSavingsGoal = savingsGoal.copyWith(
              id: data['data'][0]['id'].toString(),
            );
            return mockSavingsGoal;
          }
        } else {
          print('❌ API returned error: ${data['message'] ?? 'Unknown error'}');
          print('❌ Error details: ${data['error'] ?? 'No details provided'}');
          return null;
        }
      }

      print('❌ Failed to create savings goal: No response data');
      return null;
    } catch (e, stackTrace) {
      print('❌ Error creating savings goal: $e');
      print('📜 Stack trace: $stackTrace');

      // Return the original savings goal as fallback
      // This ensures the local UI still works even if API fails
      return savingsGoal;
    }
  }

  // Update an existing savings goal
  static Future<SavingsGoal?> updateSavingsGoal(SavingsGoal savingsGoal) async {
    try {
      print(
        'Updating savings goal with ID: ${savingsGoal.id} at: ${ApiConfig.savingsGoals}/${savingsGoal.id}',
      );
      print('Savings goal data: ${_convertToBackendFormat(savingsGoal)}');

      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }

      print(
        '🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
      );
      final data = await ApiService.put(
        '${ApiConfig.savingsGoals}/${savingsGoal.id}',
        _convertToBackendFormat(savingsGoal),
      );

      if (data != null && data['success'] == true && data['data'] != null) {
        print('✅ Savings goal updated successfully with ID: ${savingsGoal.id}');
        return _convertBackendSavingsGoal(data['data']);
      } else {
        print(
          '❌ Failed to update savings goal: ${data?['message'] ?? 'Unknown error'}',
        );
      }

      return null;
    } catch (e) {
      print('❌ Error updating savings goal: $e');
      return null;
    }
  }

  // Delete a savings goal
  static Future<bool> deleteSavingsGoal(String id) async {
    try {
      print(
        '🗑️ Deleting savings goal with ID: $id from: ${ApiConfig.savingsGoals}/$id',
      );

      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      // Try alternative token if primary one is not available
      if (token == null || token.isEmpty) {
        token = prefs.getString('token');
        if (token == null || token.isEmpty) {
          print('⚠️ No auth token found. User may not be logged in properly.');
          return false;
        }
        print('🔄 Using alternative token key');
      }

      print(
        '🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
      );

      // Ensure the URL is properly formatted
      final endpoint = '${ApiConfig.savingsGoals}/$id';
      print('🌐 DELETE endpoint: $endpoint');

      // Make the DELETE request with explicit headers
      final response = await http
          .delete(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏱️ DELETE request timed out after 15 seconds');
              throw TimeoutException('Request timed out');
            },
          );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Handle different status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Savings goal deleted successfully with ID: $id');
        return true;
      } else if (response.statusCode == 404) {
        print('⚠️ Savings goal not found with ID: $id');
        // If the goal doesn't exist on the server, consider it deleted
        return true;
      } else if (response.statusCode == 500) {
        print('❌ Server error when deleting savings goal: ${response.body}');
        // For 500 errors, we'll try using the ApiService as a fallback
        final data = await ApiService.delete(endpoint);
        if (data != null && data['success'] == true) {
          print('✅ Savings goal deleted successfully with fallback method');
          return true;
        }
        return false;
      } else {
        print(
          '❌ Failed to delete savings goal: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error deleting savings goal: $e');
      return false;
    }
  }

  // Add money to a savings goal
  static Future<SavingsGoal?> addMoneyToSavingsGoal(
    String id,
    double amount,
  ) async {
    try {
      print('Adding $amount to savings goal with ID: $id');

      // Check if auth token exists before making the request (support both auth_token and token keys)
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token') ?? prefs.getString('token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return null;
      }

      print(
        '🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
      );

      // Prepare request body
      final body = {'amount': amount};

      print('📦 Request body: $body');

      // Check if the ID is valid before making the request
      if (id.isEmpty || id == 'undefined' || id == 'null') {
        print('❌ Invalid savings goal ID: $id');
        return null;
      }

      // Use the correct endpoint format
      final endpoint = '${ApiConfig.savingsGoals}/$id/add';
      print('🌐 Sending POST request to: $endpoint');

      // Make the API request
      final data = await ApiService.post(endpoint, body);

      if (data != null) {
        print('📡 Received response: $data');
        print('📡 Response keys: ${data.keys.toList()}');
        print('📡 Response data type: ${data['data'].runtimeType}');

        if (data['success'] == true) {
          // Handle different response data formats
          if (data['data'] is Map<String, dynamic>) {
            print(
              '📊 Data is Map with keys: ${(data['data'] as Map).keys.toList()}',
            );
            // Check if the response has nested savingsGoal object
            if (data['data'].containsKey('savingsGoal')) {
              print(
                '✅ Successfully added $amount to savings goal with ID: $id (nested response)',
              );
              print(
                '🔍 Backend savingsGoal object: ${data['data']['savingsGoal']}',
              );
              print(
                '💰 Backend currentAmount: ${data['data']['savingsGoal']['currentAmount']}',
              );
              return _convertBackendSavingsGoal(data['data']['savingsGoal']);
            } else {
              // Single object response
              print(
                '✅ Successfully added $amount to savings goal with ID: $id',
              );
              print('🔍 Backend data object: ${data['data']}');
              return _convertBackendSavingsGoal(data['data']);
            }
          } else if (data['data'] is List && data['data'].isNotEmpty) {
            // List response - get the first item if it's a list
            print(
              '✅ Successfully added $amount to savings goal with ID: $id (list response)',
            );
            return _convertBackendSavingsGoal(data['data'][0]);
          } else {
            // If data is present but not in expected format, fetch the updated goal
            print('⚠️ Unexpected response format, fetching updated goal');
            print(
              '⚠️ data[data] type: ${data['data'].runtimeType}, value: ${data['data']}',
            );
            return await getSavingsGoalById(id);
          }
        } else {
          print('❌ API returned error: ${data['message'] ?? 'Unknown error'}');
          print('❌ Error details: ${data['error'] ?? 'No details provided'}');
        }
      } else {
        print('❌ Failed to add money to savings goal: No response data');
      }

      return null;
    } catch (e, stackTrace) {
      print('❌ Error adding money to savings goal: $e');
      print('📜 Stack trace: $stackTrace');

      // Try to fetch the updated goal as a fallback
      try {
        print('🔄 Attempting to fetch updated goal as fallback');
        return await getSavingsGoalById(id);
      } catch (e) {
        print('❌ Fallback fetch also failed: $e');
        return null;
      }
    }
  }

  // Helper method to convert backend savings goal format to frontend SavingsGoal model
  static SavingsGoal _convertBackendSavingsGoal(Map<String, dynamic> json) {
    // Debug log the incoming JSON
    print('🔍 Converting backend savings goal: ${json.toString()}');

    // Convert color value to Color object
    Color color;
    try {
      // Check if color exists in the response
      if (json.containsKey('color') && json['color'] != null) {
        // Handle different color formats from backend
        var colorValue = json['color'];

        int colorInt;

        // If color is a string (hex format), convert it to int
        if (colorValue is String) {
          if (colorValue.startsWith('#')) {
            // Convert hex string (e.g. #FF2196F3) to int
            String hexString = colorValue.substring(1);
            colorInt = int.parse('0xFF$hexString');
          } else if (colorValue.startsWith('0x')) {
            // Convert 0xFFFFFFFF format
            colorInt = int.parse(colorValue);
          } else {
            // Try direct parsing
            colorInt = int.parse(colorValue);
          }
        } else if (colorValue is int) {
          // Already an int
          colorInt = colorValue;
        } else if (colorValue is num) {
          // Could be a num, convert to int
          colorInt = colorValue.toInt();
        } else {
          // Unknown type, use default
          print(
            '⚠️ Unknown color type: ${colorValue.runtimeType}, using default blue',
          );
          colorInt = Colors.blue.value;
        }

        // Now colorInt is guaranteed to be an int
        color = Color(colorInt);
        print(
          '🎨 Using color from backend: 0x${color.value.toRadixString(16).toUpperCase()}',
        );
      } else {
        // Default to blue if color is missing
        color = Colors.blue;
        print('⚠️ No color found in savings goal, using default blue');
      }
    } catch (e, stackTrace) {
      print('⚠️ Error parsing color: $e');
      print('📜 Stack trace: $stackTrace');
      color = Colors.blue; // Fallback color
    }

    // Safe getters for potentially null values
    String getId() {
      final id = json['_id'] ?? json['id'];
      if (id == null) {
        print('⚠️ No ID found in savings goal, generating local ID');
        return 'local_${DateTime.now().millisecondsSinceEpoch}';
      }
      return id.toString();
    }

    String getTitle() {
      final title = json['title'] ?? json['name'];
      if (title == null) {
        print('⚠️ No title found in savings goal, using default');
        return 'Unnamed Goal';
      }
      return title.toString();
    }

    String? getDescription() {
      final description = json['description'];
      return description?.toString();
    }

    double getTargetAmount() {
      final amount = json['targetAmount'];
      if (amount == null) {
        print('⚠️ No target amount found in savings goal, using default 0.0');
        return 0.0;
      }
      return amount is int ? amount.toDouble() : (amount as num).toDouble();
    }

    double getCurrentAmount() {
      final amount = json['currentAmount'];
      if (amount == null) {
        return 0.0;
      }
      return amount is int ? amount.toDouble() : (amount as num).toDouble();
    }

    DateTime getCreatedDate() {
      final date = json['createdDate'] ?? json['createdAt'];
      if (date == null) {
        print('⚠️ No created date found in savings goal, using current time');
        return DateTime.now();
      }
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        print('⚠️ Error parsing created date: $e');
        return DateTime.now();
      }
    }

    DateTime? getTargetDate() {
      final date = json['targetDate'];
      if (date == null) {
        return null;
      }
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        print('⚠️ Error parsing target date: $e');
        return null;
      }
    }

    String? getIconName() {
      final icon = json['iconName'] ?? json['icon'];
      return icon?.toString();
    }

    return SavingsGoal(
      id: getId(),
      title: getTitle(),
      description: getDescription(),
      targetAmount: getTargetAmount(),
      currentAmount: getCurrentAmount(),
      createdDate: getCreatedDate(),
      targetDate: getTargetDate(),
      color: color,
      iconName: getIconName(),
    );
  }

  // Helper method to convert frontend SavingsGoal model to backend format
  static Map<String, dynamic> _convertToBackendFormat(SavingsGoal savingsGoal) {
    // Create a base map with required fields
    final Map<String, dynamic> data = {
      'title':
          savingsGoal.title.isNotEmpty ? savingsGoal.title : 'Unnamed Goal',
      'targetAmount': savingsGoal.targetAmount,
      'currentAmount': savingsGoal.currentAmount,
      // Add 'name' field which is required by the backend (maps to 'title' in our model)
      'name': savingsGoal.title.isNotEmpty ? savingsGoal.title : 'Unnamed Goal',
    };

    // Only add optional fields if they exist
    if (savingsGoal.description != null &&
        savingsGoal.description!.isNotEmpty) {
      data['description'] = savingsGoal.description;
    }

    // For dates, use createdAt instead of createdDate to match backend expectations
    data['createdAt'] = savingsGoal.createdDate.toIso8601String();

    // Add targetDate if available
    if (savingsGoal.targetDate != null) {
      data['targetDate'] = savingsGoal.targetDate!.toIso8601String();
    }

    // Add color and icon if available
    // Format color as int value to ensure backend compatibility
    data['color'] = savingsGoal.color.value;
    print(
      '🎨 Formatting color for backend: ${savingsGoal.color.value} (0x${savingsGoal.color.value.toRadixString(16).toUpperCase()})',
    );

    // Add icon if available
    if (savingsGoal.iconName != null && savingsGoal.iconName!.isNotEmpty) {
      data['iconName'] = savingsGoal.iconName;
    }

    // This prevents the "Cast to ObjectId failed" error
    if (!savingsGoal.id.startsWith('local_') &&
        !savingsGoal.id.contains('local_') &&
        RegExp(r'^[0-9a-f]{24}$').hasMatch(savingsGoal.id)) {
      data['_id'] = savingsGoal.id;
    }

    // Always ensure there's a name field (title) to satisfy backend validation
    if (!data.containsKey('title') ||
        data['title'] == null ||
        data['title'].isEmpty) {
      data['title'] = 'Unnamed Goal';
    }

    // Log the data being sent to help with debugging
    print('📤 Savings goal data being sent to backend: $data');

    return data;
  }
}
