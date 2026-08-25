import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_config.dart';
import 'auth_state_service.dart';
import 'api_service.dart';
import '../config/api_config.dart'; // Import ApiConfig

class AuthService {
  // Helper method to get the correct MIME type for image files
  static MediaType _getImageMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('image', 'jpeg');
    }
  }
  // Use AppConfig.useMockData instead of a separate flag
  // This ensures consistency with the rest of the app

  // Save user profile data to shared preferences for profile display
  static String _formatProfilePictureUrl(String url) {
    // If it's already a full URL, return it as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If it's a base64 image or file path, return it as is
    if (url.startsWith('data:image') || url.startsWith('file://')) {
      return url;
    }
    
    // If it's a relative path from the backend (starts with /uploads/), prepend the backend URL
    if (url.startsWith('/uploads/')) {
      return '${AppConfig.backendBaseUrl}${url}';
    }
    
    // Return the URL as is for any other case
    return url;
  }

  static Future<void> saveUserProfileData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Extract profile picture URL with proper formatting
      String profilePictureUrl = 'https://randomuser.me/api/portraits/lego/1.jpg';
      
      // Check different possible keys for profile picture
      if (userData['profilePicture'] != null) {
        profilePictureUrl = _formatProfilePictureUrl(userData['profilePicture']);
        print('Found profile picture in userData[profilePicture]: $profilePictureUrl');
      } else if (userData['avatarUrl'] != null) {
        profilePictureUrl = _formatProfilePictureUrl(userData['avatarUrl']);
        print('Found profile picture in userData[avatarUrl]: $profilePictureUrl');
      } else if (userData['profile_picture'] != null) {
        profilePictureUrl = _formatProfilePictureUrl(userData['profile_picture']);
        print('Found profile picture in userData[profile_picture]: $profilePictureUrl');
      }

      // Create a profile data map with user information
      final Map<String, dynamic> profileData = {
        'id': userData['id'] ?? userData['_id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        'name': userData['name'] ?? 'User',
        'email': userData['email'] ?? '',
        'phone': userData['mobile'] ?? userData['phone'] ?? '',
        'avatarUrl': profilePictureUrl,
        'dob': userData['dob'] ?? userData['dateOfBirth'] ?? '',
        'membershipLevel': 'Basic',
        'levelProgress': 0.1,
        'nextLevel': 'Silver',
        'xp': 100,
        'level': 1,
        'points': 100,
        'rank': 100,
        'completedTransactions': 0,
      };

      // Save profile data
      await prefs.setString('user_profile', jsonEncode(profileData));
      print('User profile data saved successfully with profile picture: $profilePictureUrl');
    } catch (e) {
      print('Error saving user profile data: $e');
    }
  }

  static Future<http.Response> signup({
    required String name,
    required String dob,
    required String email,
    required String password,
    String? mobile,
    String? profileImage,
  }) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Create a mock successful response with user data and token
      final userData = {
        'name': name,
        'email': email,
        'dob': dob,
        'profilePicture': profileImage != null ? 'file://$profileImage' : 'https://randomuser.me/api/portraits/lego/1.jpg',
      };

      final token = 'mock_auth_token_${DateTime.now().millisecondsSinceEpoch}';

      // Save authentication state
      await AuthStateService.saveAuthState(token: token, userData: userData);

      // Also save the token for API requests
      await ApiService.saveAuthToken(token);

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'User registered successfully',
          'token': token,
          'user': userData,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    } else {
      // Use ApiService for real backend connection
      try {
        print('Attempting to register with Railway backend');
        print('Using URL: ${ApiConfig.register}');
        print('Sending registration data: name=$name, email=$email, dob=$dob');
        
        http.Response response;
        
        // Create multipart request if we have a profile image
        if (profileImage != null) {
          try {
            final file = File(profileImage);
            
            // Validate file exists
            if (!file.existsSync()) {
              print('Profile image file does not exist: $profileImage');
              throw Exception('Profile image file does not exist');
            }
            
            // Get file info
            final fileLength = await file.length();
            print('Profile image file size: $fileLength bytes');
            
            // Skip image upload if file is too small (likely invalid)
            if (fileLength < 100) {
              print('Profile image file is too small, skipping upload');
              
              // Fall back to regular JSON request
              final headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              };
              
              final body = jsonEncode({
                'name': name,
                'dob': dob,
                'email': email,
                'password': password,
                if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
              });
              
              print('Falling back to JSON request: $body');
              
              response = await http.post(
                Uri.parse(ApiConfig.register),
                headers: headers,
                body: body,
              );
              
              return response;
            }
            
            // Create multipart request
            final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.register));
            
            // Add text fields
            request.fields['name'] = name;
            request.fields['dob'] = dob;
            request.fields['email'] = email;
            request.fields['password'] = password;
            if (mobile != null && mobile.isNotEmpty) {
              request.fields['mobile'] = mobile;
            }
            
            // Get file extension from path
            final fileExtension = profileImage.split('.').last.toLowerCase();
            print('Profile image file extension: $fileExtension');
            
            // Create file stream
            final fileStream = http.ByteStream(file.openRead());
            
            // Use the parameter name 'profilePicture' to match backend expectation
            final multipartFile = http.MultipartFile(
              'profilePicture',
              fileStream,
              fileLength,
              filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
              contentType: _getImageMimeType(fileExtension),
            );
            
            request.files.add(multipartFile);
            
            // Add headers
            request.headers['Accept'] = 'application/json';
            
            print('Sending multipart request with profile image');
            print('File details: ${multipartFile.filename}, ${multipartFile.contentType}, ${multipartFile.length} bytes');
            
            // Send the request
            final streamedResponse = await request.send();
            response = await http.Response.fromStream(streamedResponse);
          } catch (e) {
            print('Error processing profile image: $e');
            
            // Fall back to regular JSON request without profile image
            final headers = {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            };
            
            final body = jsonEncode({
              'name': name,
              'dob': dob,
              'email': email,
              'password': password,
              if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
            });
            
            print('Falling back to JSON request after error: $body');
            
            response = await http.post(
              Uri.parse(ApiConfig.register),
              headers: headers,
              body: body,
            );
          }
        } else {
          // Regular JSON request without profile image
          final headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };
          
          final body = jsonEncode({
            'name': name,
            'dob': dob,
            'email': email,
            'password': password,
            if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
          });
          
          print('Request body: $body');
          
          response = await http.post(
            Uri.parse(ApiConfig.register),
            headers: headers,
            body: body,
          );
        }

        print('Registration status code: ${response.statusCode}');
        print('Registration response body: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Success response
          final data = jsonDecode(response.body);

          // Save authentication state if registration successful
          if (data['token'] != null) {
            await ApiService.saveAuthToken(data['token']);

            // Create user data map
            final userData =
                data['user'] ?? {'name': name, 'email': email, 'dob': dob};

            // Save auth state
            await AuthStateService.saveAuthState(
              token: data['token'],
              userData: userData,
            );

            // Also save user profile data for profile display
            await saveUserProfileData(userData);
          }

          return response;
        } else {
          // Error response - return the actual response so we can see the error details
          print('Registration failed with status: ${response.statusCode}');
          return response;
        }
      } catch (e) {
        print('Signup error: ${e.toString()}');
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Network error: ${e.toString()}',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
    }
  }

  static Future<http.Response> signin({
    String? email,
    String? mobile,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Create a mock successful response with user data
      final userData = {
        'name': 'Demo User',
        'email': email ?? 'demo@example.com',
        'profilePicture': 'https://randomuser.me/api/portraits/lego/1.jpg',
      };

      final token = 'mock_auth_token_12345';

      // Save authentication state
      await AuthStateService.saveAuthState(token: token, userData: userData);

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'User logged in successfully',
          'token': token,
          'user': userData,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    } else {
      // Use direct HTTP request for real backend connection
      try {
        print('Attempting to login with Railway backend');
        print('Using URL: ${ApiConfig.login}');
        print('API Base URL: ${ApiConfig.baseUrl}');
        print('App Config Base URL: ${AppConfig.backendBaseUrl}');
        print('Sending login data: email=$email, mobile=$mobile');
        
        // Test connection to backend
        try {
          final testResponse = await http.get(Uri.parse('${AppConfig.backendBaseUrl}'));
          print('Backend connection test status: ${testResponse.statusCode}');
          print('Backend connection test response: ${testResponse.body}');
        } catch (e) {
          print('Backend connection test error: $e');
        }

        // Make a direct HTTP request to get more detailed error information
        final headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        final body = jsonEncode({
          if (email != null && email.isNotEmpty) 'email': email,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
          'password': password,
        });

        print('Request body: $body');

        final response = await http.post(
          Uri.parse(ApiConfig.login),
          headers: headers,
          body: body,
        );

        print('Login status code: ${response.statusCode}');
        print('Login response body: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Success response
          final data = jsonDecode(response.body);

          // Save auth token if login successful
          if (data['token'] != null) {
            await ApiService.saveAuthToken(data['token']);

            // Create user data map
            final userData = data['user'] ?? {'email': email};
            
            // Make sure we have the profile picture URL from the backend
            if (userData['profilePicture'] == null && data['user'] != null && data['user']['profilePicture'] != null) {
              userData['profilePicture'] = _formatProfilePictureUrl(data['user']['profilePicture']);
            }

            // Save auth state
            await AuthStateService.saveAuthState(
              token: data['token'],
              userData: userData,
            );

            // Also save user profile data for profile display
            await saveUserProfileData(userData);

            // Trigger a notification that login was successful - this will be used by other services
            await SharedPreferences.getInstance().then((prefs) {
              prefs.setBool('login_successful', true);
              prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
            });

            print('Authentication state and profile data saved successfully with profile picture: ${userData['profilePicture']}');
          } else {
            print('No token received from backend');
          }

          return response;
        } else {
          // Error response - return the actual response so we can see the error details
          print('Login failed with status: ${response.statusCode}');
          return response;
        }
      } catch (e) {
        print('Login error: ${e.toString()}');
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Network error: ${e.toString()}',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
    }
  }

  static Future<http.Response> verifyOtp({
    String? email,
    String? mobile,
    required String otp,
  }) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // For demo purposes, consider any 4-digit OTP as valid
      if (otp.length == 4 && int.tryParse(otp) != null) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OTP verified successfully',
            'token': 'mock_verified_token_12345',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else {
        // Return error for invalid OTP format
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid OTP. Please enter a 4-digit code.',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      }
    } else {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/verify');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'mobile': mobile, 'otp': otp}),
      );
      return response;
    }
  }

  static Future<http.Response> verifyResetOtp({
    String? email,
    String? mobile,
    required String otp,
  }) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // For demo purposes, accept any 4-digit OTP
      if (otp.length == 4 && int.tryParse(otp) != null) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'OTP verified successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid OTP. Please enter a 4-digit code.',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      }
    } else {
      try {
        final url = Uri.parse('${AppConfig.backendBaseUrl}/api/auth/verify-reset-otp');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'mobile': mobile, 'otp': otp}),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            return http.Response(
              jsonEncode({
                'success': false,
                'message': 'Request timeout. Please try again.',
              }),
              408,
              headers: {'content-type': 'application/json'},
            );
          },
        );
        return response;
      } catch (e) {
        print('Verify reset OTP error: $e');
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Network error: ${e.toString()}',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
    }
  }

  static Future<http.Response> forgotPassword({
    String? email,
    String? mobile,
  }) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'OTP sent to your email/mobile for password reset',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    } else {
      try {
        final url = Uri.parse('${AppConfig.backendBaseUrl}/api/auth/forgot-password');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'mobile': mobile}),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            // Return a timeout error response
            return http.Response(
              jsonEncode({
                'success': false,
                'message': 'Request timeout. Please check your connection and try again.',
              }),
              408,
              headers: {'content-type': 'application/json'},
            );
          },
        );
        return response;
      } catch (e) {
        print('Forgot password error: $e');
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Network error: ${e.toString()}',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
    }
  }

  static Future<http.Response> resetPassword({
    String? email,
    String? mobile,
    required String otp,
    required String newPassword,
  }) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // For demo purposes, accept any 4-digit OTP for password reset
      if (otp.length == 4 && int.tryParse(otp) != null) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Password reset successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid OTP. Please enter a 4-digit code.',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      }
    } else {
      try {
        final url = Uri.parse('${AppConfig.backendBaseUrl}/api/auth/reset-password');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'mobile': mobile,
            'otp': otp,
            'newPassword': newPassword,
          }),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            return http.Response(
              jsonEncode({
                'success': false,
                'message': 'Request timeout. Please try again.',
              }),
              408,
              headers: {'content-type': 'application/json'},
            );
          },
        );
        return response;
      } catch (e) {
        print('Reset password error: $e');
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Network error: ${e.toString()}',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
    }
  }

  static Future<http.Response> getProfile(String token) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      return http.Response(
        jsonEncode({
          'success': true,
          'user': {
            'name': 'Demo User',
            'email': 'demo@example.com',
            'dob': '01-01-1990',
            'mobile': '+91 9876543210',
            'profilePicture': 'https://randomuser.me/api/portraits/lego/1.jpg',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    } else {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/users/profile');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    }
  }

  static Future<http.Response> updateProfile({
    required String token,
    String? name,
    String? dob,
    String? profileImagePath,
  }) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Profile updated successfully',
          'user': {
            'name': name ?? 'Demo User',
            'dob': dob ?? '01-01-1990',
            'email': 'demo@example.com',
            'mobile': '+91 9876543210',
            'profilePicture': profileImagePath != null ? 'file://$profileImagePath' : 'https://randomuser.me/api/portraits/lego/1.jpg',
          }
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    } else {
      try {
        if (profileImagePath != null) {
          // Use multipart request for profile image update
          final request = http.MultipartRequest('PUT', Uri.parse('${AppConfig.backendBaseUrl}/api/users/profile'));
          
          // Add auth header
          request.headers['Authorization'] = 'Bearer $token';
          
          // Add text fields
          if (name != null) request.fields['name'] = name;
          if (dob != null) request.fields['dob'] = dob;
          
          // Add profile image file
          final file = File(profileImagePath);
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = await file.length();
          
          final multipartFile = http.MultipartFile(
            'profileImage',
            fileStream,
            fileLength,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          
          request.files.add(multipartFile);
          
          // Send the request
          final streamedResponse = await request.send();
          return await http.Response.fromStream(streamedResponse);
        } else {
          // Regular JSON request without profile image
          final url = Uri.parse('${AppConfig.backendBaseUrl}/api/users/profile');
          final response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              if (name != null) 'name': name,
              if (dob != null) 'dob': dob,
            }),
          );
          return response;
        }
      } catch (e) {
        print('Error updating profile: $e');
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Error updating profile: $e',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
    }
  }

  static Future<http.Response> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (AppConfig.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // For demo purposes, accept any non-empty password change
      if (oldPassword.isNotEmpty && newPassword.isNotEmpty) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Password changed successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Password cannot be empty'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      }
    } else {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/change-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      return response;
    }
  }
}
