import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A service that handles the authentication state persistence
class AuthStateService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Check if user is logged in with enhanced persistence check
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    // Check all possible auth indicators
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    // Check token and user data directly
    final token = prefs.getString(_tokenKey);
    final altToken = prefs.getString('token'); // Alternative token key
    final effectiveToken = token ?? altToken;

    final userData = prefs.getString(_userDataKey);
    final userProfile = prefs.getString('user_profile');
    final effectiveUserData = userData ?? userProfile;

    // Print auth details for debugging
    print('🔐 Auth check details:');
    print('  - Flags: isLoggedIn=$isLoggedIn');
    print(
      '  - Tokens: ${token != null ? 'exists' : 'null'}, Alt: ${altToken != null ? 'exists' : 'null'}',
    );
    print(
      '  - User data: ${userData != null ? 'exists' : 'null'}, Profile: ${userProfile != null ? 'exists' : 'null'}',
    );

    // CRITICAL: Consider user logged in if we have a token and user data
    // This ensures authentication persistence across app restarts
    if (effectiveToken != null &&
        effectiveToken.isNotEmpty &&
        effectiveUserData != null &&
        effectiveUserData.isNotEmpty) {
      print('✅ Found valid token and user data - user is logged in');

      // If we have valid token and data but flags are inconsistent, fix them
      if (!isLoggedIn) {
        print(
          '🔄 Fixing auth state inconsistency: Setting all login flags to true',
        );
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setBool('auth_state_valid', true);
        await prefs.setBool('login_successful', true);
      }

      return true;
    }

    return isLoggedIn;
  }

  /// Save authentication state with enhanced persistence
  static Future<void> saveAuthState({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Save token in both possible locations for maximum compatibility
    await prefs.setString(_tokenKey, token);
    await prefs.setString('token', token); // Alternative token key

    // Save user data
    final userDataJson = jsonEncode(userData);
    await prefs.setString(_userDataKey, userDataJson);

    // Also save as user_profile for profile display
    try {
      // Create a profile data map with user information
      final Map<String, dynamic> profileData = {
        'id':
            userData['id'] ??
            userData['_id'] ??
            'usr_${DateTime.now().millisecondsSinceEpoch}',
        'name': userData['name'] ?? 'User',
        'email': userData['email'] ?? '',
        'phone': userData['mobile'] ?? userData['phone'] ?? '',
        'avatarUrl':
            userData['profilePicture'] ??
            userData['avatarUrl'] ??
            'https://randomuser.me/api/portraits/lego/1.jpg',
      };

      // Save profile data
      await prefs.setString('user_profile', jsonEncode(profileData));
    } catch (e) {
      // Continue even if profile data saving fails
    }

    // Set all login status flags consistently
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setBool('login_successful', true);
    await prefs.setBool('auth_state_valid', true);
  }

  /// Get saved auth token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get saved user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString == null) return null;

    try {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get simplified user profile (id, name, email, phone, avatarUrl)
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString('user_profile');
    if (profileString == null) return null;

    try {
      return jsonDecode(profileString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear authentication state (logout) with enhanced cleanup
  static Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all possible auth tokens
    await prefs.remove(_tokenKey);
    await prefs.remove('token'); // Alternative token key

    // Clear all possible user data
    await prefs.remove(_userDataKey);
    await prefs.remove('user_profile');

    // Reset all auth flags
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.setBool('login_successful', false);
    await prefs.setBool('auth_state_valid', false);

    // Clear any session timestamps
    await prefs.remove('login_timestamp');
  }

  /// Logout user and navigate to login screen
  static Future<void> logout(Function navigateToLogin) async {
    await clearAuthState();
    navigateToLogin();
  }
}
