import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../app_config.dart';
import 'auth_service.dart';
import 'auth_state_service.dart';

class GoogleAuthService {
  // Create a singleton instance for better management
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Initialize with a simpler configuration that doesn't require SHA-1 verification
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    // Using a simpler configuration without serverClientId to avoid SHA-1 issues
    // This will still provide the user's email and basic profile info
  );

  // Initialize the service and check if Google Play Services are available
  static Future<void> initialize() async {
    try {
      debugPrint('🔄 Initializing GoogleAuthService...');
      debugPrint(
        '🔄 Using server client ID: ${_googleSignIn.serverClientId ?? "Not set"}',
      );
      debugPrint('🔄 Using scopes: ${_googleSignIn.scopes.join(", ")}');

      // Check if the user is already signed in
      final isSignedIn = await _googleSignIn.isSignedIn();
      debugPrint(
        '🔑 User is ${isSignedIn ? 'already signed in' : 'not signed in'}',
      );

      // If there's a previous sign-in that might be causing issues, sign out
      if (isSignedIn) {
        try {
          await _googleSignIn.signOut();
          debugPrint('🔑 Signed out previous Google session for clean state');
        } catch (e) {
          debugPrint('⚠️ Error signing out previous Google session: $e');
        }
      }

      // Check if we're using the correct backend URL
      debugPrint('🔄 Using backend URL: ${AppConfig.apiBaseUrl}');
      if (!AppConfig.apiBaseUrl.contains(
        'finnsathi-ai-expense-monitor-backend-production.up.railway.app',
      )) {
        debugPrint(
          '⚠️ WARNING: Backend URL may be incorrect. Expected URL containing "finnsathi-ai-expense-monitor-backend-production.up.railway.app"',
        );
      }

      // Check for google-services.json file
      await checkGoogleServicesFile();
    } catch (e) {
      debugPrint('❌ Error initializing GoogleAuthService: $e');
    }
  }

  // Check if google-services.json file exists in the Android app directory
  static Future<bool> checkGoogleServicesFile() async {
    try {
      // This is a basic check that logs information about the configuration
      // In a real app, we would check if the file exists in the Android app directory
      // but that's not possible from Dart code directly

      debugPrint('🔍 Checking Google Sign-In configuration...');
      debugPrint(
        '🔍 Client ID: 245798805380-od382nvaj7jg2jbodv5lp9033lg5f754.apps.googleusercontent.com',
      );

      // Log instructions for the developer
      debugPrint(
        'ℹ️ IMPORTANT: Make sure google-services.json file is present in android/app/ directory',
      );
      debugPrint(
        'ℹ️ If missing, download it from Google Cloud Console > APIs & Services > Credentials',
      );
      debugPrint(
        'ℹ️ Ensure SHA-1 fingerprint is added to the OAuth client in Google Cloud Console',
      );

      // Provide guidance on how to generate SHA-1 fingerprint
      logSHA1FingerPrintInstructions();

      return true; // Return true as we can't actually check the file from Dart
    } catch (e) {
      debugPrint('❌ Error checking Google services configuration: $e');
      return false;
    }
  }

  // Log instructions for generating and configuring SHA-1 fingerprint
  static void logSHA1FingerPrintInstructions() {
    debugPrint('\n🔑 SHA-1 Fingerprint Configuration Guide:');
    debugPrint(
      'ℹ️ ApiException 10 is typically caused by a missing or incorrect SHA-1 fingerprint',
    );
    debugPrint(
      'ℹ️ Follow these steps to generate and configure your SHA-1 fingerprint:',
    );
    debugPrint('\n1. Generate SHA-1 fingerprint:');
    debugPrint('   - Open terminal/command prompt');
    debugPrint('   - Navigate to your Android project: cd android');
    debugPrint(
      '   - Run: ./gradlew signingReport (Linux/Mac) OR gradlew signingReport (Windows)',
    );
    debugPrint(
      '   - Look for "SHA1:" in the output under debug or release variants',
    );
    debugPrint('\n2. Add SHA-1 to Google Cloud Console:');
    debugPrint('   - Go to https://console.cloud.google.com/');
    debugPrint('   - Select your project');
    debugPrint('   - Go to APIs & Services > Credentials');
    debugPrint('   - Find your OAuth 2.0 Client ID for Android');
    debugPrint('   - Click Edit');
    debugPrint('   - Add the SHA-1 fingerprint');
    debugPrint('   - Save changes');
    debugPrint('\n3. Download updated google-services.json:');
    debugPrint('   - Go to Firebase Console (if using Firebase)');
    debugPrint('   - Download the updated google-services.json file');
    debugPrint('   - Place it in android/app/ directory');
    debugPrint('\n4. If not using Firebase:');
    debugPrint(
      '   - Create a credentials.json file in android/app/src/main/res/raw/',
    );
    debugPrint('   - Add your client ID to this file');
    debugPrint(
      '\n💡 After completing these steps, rebuild your app and try Google Sign-In again',
    );
  }

  // Method to sign in with Google
  // Method to sign in with Google - updated to accept onSuccess callback
  Future<bool> signInWithGoogle(
    BuildContext context, {
    Function? onSuccess,
  }) async {
    try {
      debugPrint('⚠️ GOOGLE SIGN-IN START: Attempting to sign in with Google');
      debugPrint(
        '⚠️ GOOGLE SIGN-IN CONFIG: ServerClientId = ${_googleSignIn.serverClientId}',
      );
      debugPrint('⚠️ GOOGLE SIGN-IN CONFIG: Scopes = ${_googleSignIn.scopes}');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Add timeout to detect hangs
      final signInFuture = _googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint(
            '⚠️ GOOGLE SIGN-IN TIMEOUT: The sign-in process timed out after 30 seconds',
          );
          return null; // Return null on timeout to be handled as a cancellation
        },
      );

      debugPrint('⚠️ GOOGLE SIGN-IN CALL: Calling _googleSignIn.signIn()');
      final GoogleSignInAccount? googleUser = await signInFuture;
      debugPrint(
        '⚠️ GOOGLE SIGN-IN RESULT: ${googleUser != null ? "User account selected" : "No user account selected (null)"}',
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (googleUser == null) {
        debugPrint(
          '⚠️ GOOGLE SIGN-IN CANCELLED: User cancelled the sign-in process',
        );
        return false;
      }

      // Get authentication tokens

      debugPrint('🔑 Getting Google authentication tokens...');
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint('✅ Got authentication tokens');

      // Check if tokens are null
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      debugPrint(
        '⚠️ Google Sign-In tokens status: idToken=${idToken != null}, accessToken=${accessToken != null}',
      );

      // Check if we have at least the accessToken
      if (accessToken == null) {
        debugPrint('⚠️ Google Sign-In failed: accessToken is null');
        return false;
      }

      // Call backend authentication with the available tokens and user info
      // Even if tokens are limited, we can still authenticate with email and profile info
      final success = await _authenticateWithBackend(
        googleUser,
        idToken ?? '', // May be empty if not available
        accessToken, // We already checked that accessToken is not null
      );

      // Call onSuccess callback if authentication was successful
      if (success) {
        debugPrint(
          '✅ Authentication successful, preparing to navigate to home screen',
        );
        // Only call onSuccess if provided, otherwise handle navigation here
        if (onSuccess != null) {
          onSuccess();
        } else if (context.mounted) {
          // Default navigation if no callback is provided
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }

      return success;
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Handle ApiException error 10 specifically
      if (e.toString().contains('ApiException: 10')) {
        debugPrint(
          '❌ Google Sign-In API Exception 10 - This usually indicates a SHA certificate mismatch',
        );
        debugPrint(
          '❌ Please verify that the SHA-1 fingerprint is correctly configured in Google Cloud Console',
        );

        // Show a more user-friendly error message with guidance
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Google Sign-In Error'),
                content: const Text(
                  'There was an error with Google Sign-In (Error 10). This is typically caused by missing configuration files or a mismatch in the app\'s security configuration.\n\n'
                  'To fix this issue:\n'
                  '1. Make sure the google-services.json file is present in the android/app/ directory\n'
                  '2. Verify that the SHA-1 fingerprint is correctly configured in Google Cloud Console\n'
                  '3. Make sure you\'re using the correct Google account\n'
                  '4. Try clearing Google Play Services cache\n'
                  '5. Restart the app and try again',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }

      debugPrint('Error signing in with Google: $e');

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign In failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }

  // Authenticate with our backend using Google credentials
  // Public method for direct authentication with backend from other classes
  static Future<bool> authenticateWithBackend({
    required GoogleSignInAccount googleUser,
    required String idToken,
    required String accessToken,
  }) async {
    return await _authenticateWithBackend(googleUser, idToken, accessToken);
  }

  static Future<bool> _authenticateWithBackend(
    GoogleSignInAccount googleUser,
    String idToken,
    String accessToken,
  ) async {
    try {
      debugPrint('🔄 Authenticating with backend using Google credentials');

      // Call our backend's Google auth endpoint
      // AppConfig.apiBaseUrl already includes /api suffix
      // Make sure we're using the correct endpoint path
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/google');
      debugPrint('🌐 Sending request to backend: $url');
      
      // Log the backend base URL for debugging
      debugPrint('🌐 Backend base URL: ${AppConfig.backendBaseUrl}');

      // Build request body with available tokens
      final requestBody = {
        'idToken': idToken,
        'accessToken': accessToken,
        'name': googleUser.displayName,
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
      };

      // Log token availability for debugging
      debugPrint(
        '! Google Sign-In tokens status: idToken=${idToken.isNotEmpty}, accessToken=${accessToken.isNotEmpty}',
      );
      if (idToken.isEmpty) {
        debugPrint(
          '! Using only accessToken for authentication (idToken is empty)',
        );
      }
      debugPrint('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      // If first attempt fails with 404, try with a different URL structure
      if (response.statusCode == 404) {
        debugPrint(
          '⚠️ First attempt failed with 404, trying alternative URL structure...',
        );
        // Try using the backend base URL directly with the correct path structure
        // This handles cases where the API base URL might have duplicate /api prefixes
        final alternativeUrl = Uri.parse('${AppConfig.backendBaseUrl}/api/auth/google');
        debugPrint('🌐 Trying alternative URL: $alternativeUrl');
        debugPrint(
          '🌐 Sending request to alternative backend URL: $alternativeUrl',
        );

        final alternativeResponse = await http.post(
          alternativeUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        debugPrint(
          '📥 Alternative response status: ${alternativeResponse.statusCode}',
        );
        debugPrint('📥 Alternative response body: ${alternativeResponse.body}');

        if (alternativeResponse.statusCode == 200 ||
            alternativeResponse.statusCode == 201) {
          final data = jsonDecode(alternativeResponse.body);

          // Save the token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('login_successful', true);
          await prefs.setInt(
            'login_timestamp',
            DateTime.now().millisecondsSinceEpoch,
          );

          // Save user profile data
          if (data['user'] != null) {
            await AuthService.saveUserProfileData(data['user']);
          } else {
            // Create basic profile from Google data
            await AuthService.saveUserProfileData({
              'name': googleUser.displayName,
              'email': googleUser.email,
              'profilePicture': googleUser.photoUrl,
            });
          }

          // Update auth state
          await AuthStateService.saveAuthState(
            token: data['token'],
            userData:
                data['user'] ??
                {
                  'name': googleUser.displayName,
                  'email': googleUser.email,
                  'profilePicture': googleUser.photoUrl,
                },
          );

          debugPrint('✅ Successfully authenticated with backend');
          return true;
        }
      }

      // Handle successful response from first attempt
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Save the token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('login_successful', true);
        await prefs.setInt(
          'login_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );

        // Save user profile data
        if (data['user'] != null) {
          await AuthService.saveUserProfileData(data['user']);
        } else {
          // Create basic profile from Google data
          await AuthService.saveUserProfileData({
            'name': googleUser.displayName,
            'email': googleUser.email,
            'profilePicture': googleUser.photoUrl,
          });
        }

        // Update auth state
        await AuthStateService.saveAuthState(
          token: data['token'],
          userData:
              data['user'] ??
              {
                'name': googleUser.displayName,
                'email': googleUser.email,
                'profilePicture': googleUser.photoUrl,
              },
        );

        debugPrint('✅ Successfully authenticated with backend');
        return true;
      } else {
        debugPrint(
          '❌ Backend authentication failed with status code: ${response.statusCode}',
        );
        debugPrint('Response body: ${response.body}');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error authenticating with backend: $e');
      return false;
    }
  }

  // Sign out from Google
  static Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear auth state
      await AuthStateService.clearAuthState();

      debugPrint('✅ Successfully signed out from Google');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
    }
  }
}
