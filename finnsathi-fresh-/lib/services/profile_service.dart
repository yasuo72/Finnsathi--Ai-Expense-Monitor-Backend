import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_profile_model.dart';
import '../services/auth_state_service.dart';
import '../app_config.dart';
import '../services/auth_service.dart';

class ProfileService extends ChangeNotifier {
  // Helper method to parse trophy rarity from string
  TrophyRarity _parseTrophyRarity(String rarityStr) {
    switch (rarityStr) {
      case 'common':
        return TrophyRarity.common;
      case 'uncommon':
        return TrophyRarity.uncommon;
      case 'rare':
        return TrophyRarity.rare;
      case 'epic':
        return TrophyRarity.epic;
      case 'legendary':
        return TrophyRarity.legendary;
      default:
        return TrophyRarity.common;
    }
  }

  static const String _profileKey = 'user_profile';

  UserProfile? _currentProfile;

  UserProfile get currentProfile => _currentProfile ?? UserProfile.mock();

  // Helper method to format profile picture URLs
  static String _formatProfilePictureUrl(String url) {
    // Log the original URL for debugging
    debugPrint('Original profile picture URL: $url');
    
    // If URL is empty, return empty string
    if (url.isEmpty) {
      debugPrint('Empty profile picture URL');
      return '';
    }

    // If it's already a full URL, return it as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      debugPrint('URL is already a full URL: $url');
      return url;
    }

    // If it's a base64 image or file path, return it as is
    if (url.startsWith('data:image') || url.startsWith('file://')) {
      debugPrint('URL is a base64 image or file path');
      return url;
    }

    // If it's a relative path from the backend (starts with /uploads/), prepend the backend URL
    if (url.startsWith('/uploads/')) {
      final formattedUrl = '${AppConfig.backendBaseUrl}${url}';
      debugPrint('Formatted profile picture URL: $formattedUrl');
      return formattedUrl;
    }
    
    // If it's just a filename without path, assume it's in uploads directory
    if (!url.contains('/') && (url.contains('.jpg') || url.contains('.jpeg') || url.contains('.png') || url.contains('.gif'))) {
      final formattedUrl = '${AppConfig.backendBaseUrl}/uploads/${url}';
      debugPrint('Formatted filename to full URL: $formattedUrl');
      return formattedUrl;
    }

    // Return the URL as is for any other case
    debugPrint('Returning URL as is: $url');
    return url;
  }

  ProfileService() {
    // Load profile when service is initialized
    _loadUserProfile();
  }

  // Refresh the profile data (call this when user data might have changed)
  void refreshProfile() {
    _loadUserProfile();
  }

  // Load the user profile from SharedPreferences
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null) {
        // Parse the stored profile JSON
        final Map<String, dynamic> profileMap = jsonDecode(profileJson);
        _currentProfile = _createProfileFromJson(profileMap);
      } else {
        // Create and save a default profile if none exists
        _currentProfile = UserProfile.mock();
        await _saveUserProfile(_currentProfile!);
      }

      // Notify listeners that profile has been loaded
      notifyListeners();

      // Fetch latest profile from backend and merge if necessary
      await _fetchAndUpdateFromBackend();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _currentProfile = UserProfile.mock();
      notifyListeners();
    }
  }

  // Fetch latest profile from backend and merge into local cache
  Future<void> _fetchAndUpdateFromBackend() async {
    try {
      final token = await AuthStateService.getAuthToken();
      if (token == null || token.isEmpty) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/users/profile');
      debugPrint('📡 Fetching profile from backend: $url');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        Map<String, dynamic>? payload;
        if (data['data'] is Map) {
          payload = Map<String, dynamic>.from(data['data']);
        } else if (data['user'] is Map) {
          payload = Map<String, dynamic>.from(data['user']);
        }
        if (payload != null) {
          final merged = {
            ...payload,
            'avatarUrl': payload['profilePicture'] ?? payload['avatarUrl'] ?? '',
          };
          _currentProfile = _createProfileFromJson(merged);
          await _saveUserProfile(_currentProfile!);
          notifyListeners();
          debugPrint('✅ Profile refreshed from backend');
        }
      } else {
        debugPrint('⚠️ Failed to fetch profile (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Error fetching profile from backend: $e');
    }
  }

  // Create a UserProfile from JSON data
  UserProfile _createProfileFromJson(Map<String, dynamic> json) {
    // Create achievements list from JSON if available
    List<Achievement> achievements = [];
    if (json.containsKey('achievements') && json['achievements'] is List) {
      achievements =
          (json['achievements'] as List).map((item) {
            return Achievement(
              id: item['id'] ?? '',
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              icon: item['icon'] ?? '',
              isUnlocked: item['isUnlocked'] ?? false,
              dateUnlocked:
                  item['dateUnlocked'] != null
                      ? DateTime.parse(item['dateUnlocked'])
                      : null,
              xpReward: item['xpReward'] ?? 50,
            );
          }).toList();
    } else {
      // Use default achievements if none in JSON
      achievements = UserProfile.mock().achievements;
    }

    // Create trophies list from JSON if available
    List<Trophy> trophies = [];
    if (json.containsKey('trophies') && json['trophies'] is List) {
      trophies =
          (json['trophies'] as List).map((item) {
            return Trophy(
              id: item['id'] ?? '',
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              rarity: _parseTrophyRarity(item['rarity'] ?? 'common'),
              iconPath: item['iconPath'] ?? item['icon'] ?? '',  // Support both iconPath and legacy icon field
              isUnlocked: item['isUnlocked'] ?? false,
              dateAwarded:  // Use dateAwarded instead of dateUnlocked
                  item['dateAwarded'] != null
                      ? DateTime.parse(item['dateAwarded'])
                      : (item['dateUnlocked'] != null  // Fallback to dateUnlocked for backward compatibility
                          ? DateTime.parse(item['dateUnlocked'])
                          : null),
              xpReward: item['xpReward'] ?? 100,
            );
          }).toList();
    } else {
      // Use default trophies if none in JSON
      trophies = UserProfile.mock().trophies;
    }

    // Create badges list from JSON if available
    List<String> badges = [];
    if (json.containsKey('badges') && json['badges'] is List) {
      badges = (json['badges'] as List)
          .map((item) => item.toString())
          .toList();
    } else {
      // Use default badges if none in JSON
      badges = UserProfile.mock().badges;
    }

    // Create preferences map from JSON if available
    Map<String, dynamic> preferences = {};
    if (json.containsKey('preferences') && json['preferences'] is Map) {
      preferences = Map<String, dynamic>.from(json['preferences']);
    } else {
      // Use default preferences if none in JSON
      preferences = UserProfile.mock().preferences;
    }

    // Create and return the UserProfile
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: _formatProfilePictureUrl(json['avatarUrl'] ?? ''),
      membershipLevel: json['membershipLevel'] ?? 'Basic',
      levelProgress: (json['levelProgress'] ?? 0.0).toDouble(),
      nextLevel: json['nextLevel'] ?? 'Silver',
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      points: json['points'] ?? 0,
      rank: json['rank'] ?? 0,
      completedTransactions: json['completedTransactions'] ?? 0,
      achievements: achievements,
      trophies: trophies,
      preferences: preferences,
      badges: badges,
    );
  }

  // Get the current user profile
  Future<UserProfile> getUserProfile() async {
    if (_currentProfile != null) {
      return _currentProfile!;
    }
    
    await _loadUserProfile();
    return currentProfile;
  }

  // Save user profile to SharedPreferences
  Future<void> _saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert achievements to JSON
      final achievementsJson = profile.achievements.map((achievement) {
        return {
          'id': achievement.id,
          'title': achievement.title,
          'description': achievement.description,
          'icon': achievement.icon,
          'isUnlocked': achievement.isUnlocked,
          'dateUnlocked': achievement.dateUnlocked?.toIso8601String(),
          'xpReward': achievement.xpReward,
        };
      }).toList();

      // Convert trophies to JSON
      final trophiesJson = profile.trophies.map((trophy) {
        return {
          'id': trophy.id,
          'title': trophy.title,
          'description': trophy.description,
          'rarity': trophy.rarity.toString().split('.').last,
          'iconPath': trophy.iconPath, // Use iconPath instead of icon
          'isUnlocked': trophy.isUnlocked,
          'dateAwarded': trophy.dateAwarded?.toIso8601String(), // Use dateAwarded instead of dateUnlocked
          'xpReward': trophy.xpReward,
        };
      }).toList();

      // Create profile JSON
      final profileJson = {
        'id': profile.id,
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'avatarUrl': profile.avatarUrl,
        'membershipLevel': profile.membershipLevel,
        'levelProgress': profile.levelProgress,
        'nextLevel': profile.nextLevel,
        'xp': profile.xp,
        'level': profile.level,
        'points': profile.points,
        'rank': profile.rank,
        'completedTransactions': profile.completedTransactions,
        'achievements': achievementsJson,
        'trophies': trophiesJson,
        'preferences': profile.preferences,
        'badges': profile.badges,
      };

      // Save profile JSON to SharedPreferences
      await prefs.setString(_profileKey, jsonEncode(profileJson));
      debugPrint('User profile saved successfully');
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      // Update the current profile
      _currentProfile = profile;
      
      // Save to SharedPreferences
      await _saveUserProfile(profile);
      
      // Sync with backend if we have a valid token
      final token = await AuthStateService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        try {
          debugPrint('🔄 Syncing profile update with backend');
          
          // Check if the profile image is a local file path or a base64 image
          String? profileImagePath;
          if (profile.avatarUrl.startsWith('file://')) {
            // Convert file:// URL to local path
            profileImagePath = profile.avatarUrl.replaceFirst('file://', '');
            debugPrint('📷 Using local file for profile image: $profileImagePath');
          }
          
          final response = await AuthService.updateProfile(
            token: token,
            name: profile.name,
            // No dob field in UserProfile, so we'll skip it
            profileImagePath: profileImagePath,
          );
          
          if (response.statusCode >= 200 && response.statusCode < 300) {
            debugPrint('✅ Profile synced with backend successfully');
            
            // Update auth state with latest profile data
            final responseData = jsonDecode(response.body);
            if (responseData['user'] != null) {
              // Convert the user data to a Map for AuthStateService
              final Map<String, dynamic> userData = responseData['user'];
              
              // Save the updated user data to auth state
              await AuthStateService.saveAuthState(
                userData: userData,
                token: token, // Keep the existing token
              );
              
              // Update the shared preferences with a force_data_refresh flag
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('force_data_refresh', true);
              
              debugPrint('✅ Updated auth state with latest profile data');
              debugPrint('✅ Set force_data_refresh flag to ensure data is refreshed on next app start');
            }
          } else {
            debugPrint('❌ Failed to sync profile with backend: ${response.statusCode}');
            debugPrint('Response: ${response.body}');
          }
        } catch (syncError) {
          debugPrint('❌ Error syncing profile with backend: $syncError');
        }
      } else {
        debugPrint('⚠️ No auth token available, profile update not synced with backend');
      }

      // Notify listeners about the update
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      if (_currentProfile == null) {
        await _loadUserProfile();
      }

      // Update preferences in the current profile
      _currentProfile = _currentProfile!.copyWith(preferences: preferences);

      // Save the updated profile
      await _saveUserProfile(_currentProfile!);

      // Notify listeners about the update
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
    }
  }

  // Get user achievements
  List<Achievement> getUserAchievements() {
    return currentProfile.achievements;
  }

  // Upload profile picture and update profile
  Future<bool> updateProfilePicture(String newAvatarUrl) async {
    try {
      // Get current profile
      final profile = currentProfile;

      // Create updated profile with new avatar URL
      final updatedProfile = profile.copyWith(
        avatarUrl: _formatProfilePictureUrl(newAvatarUrl),
      );

      // Update the profile
      await updateUserProfile(updatedProfile);
      return true;
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      return false;
    }
  }

  // Helper method to get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default to JPEG if unknown
    }
  }

  // Upload profile picture from local file path to the backend server
  Future<String?> uploadProfilePicture(String filePath) async {
    try {
      // If using mock data, just return the file path
      if (AppConfig.useMockData) {
        // Update the profile with the new avatar URL
        final newAvatarUrl = 'file://$filePath';

        // Update the profile with the new avatar URL
        await updateProfilePicture(newAvatarUrl);

        // Notify listeners to refresh UI
        notifyListeners();

        debugPrint('Mock profile picture updated: $newAvatarUrl');
        return newAvatarUrl;
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return null;
      }

      // Get file size
      final fileLength = await file.length();

      if (fileLength == 0) {
        debugPrint('File is empty: $filePath');
        return null;
      }

      if (fileLength > 5 * 1024 * 1024) {
        // 5MB limit
        debugPrint('File is too large: ${fileLength / 1024 / 1024}MB');
        return null;
      }

      // Determine MIME type from file extension
      final fileExtension = filePath.split('.').last.toLowerCase();
      final mimeType = _getMimeType(fileExtension);

      debugPrint('Uploading profile picture: $filePath');
      debugPrint('File size: ${fileLength / 1024}KB, MIME type: $mimeType');

      // Create multipart request
      final url = Uri.parse('${ApiConfig.baseUrl}/users/profile-picture');
      final request = http.MultipartRequest('POST', url);

      // Add auth header
      final token = await AuthStateService.getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
      }

      // Add file with proper MIME type
      final fileStream = http.ByteStream(file.openRead());
      final filename =
          'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      final multipartFile = http.MultipartFile(
        'profilePicture',
        fileStream,
        fileLength,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      // Send the request
      debugPrint('Sending profile picture upload request to $url');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Profile picture upload response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse response
        final data = jsonDecode(response.body);
        String? profilePictureUrl;
        
        // Extract profile picture URL from response
        // The backend may wrap the updated profile picture URL in different
        // structures depending on the endpoint.  Handle all the common cases:
        // 1️⃣  { profilePicture: '/uploads/..' }
        // 2️⃣  { user: { profilePicture: '/uploads/..' } }
        // 3️⃣  { data: { profilePicture: '/uploads/..' } }
        if (data['profilePicture'] != null) {
          profilePictureUrl = _formatProfilePictureUrl(data['profilePicture']);
        } else if (data['user'] != null && data['user']['profilePicture'] != null) {
          profilePictureUrl = _formatProfilePictureUrl(data['user']['profilePicture']);
        } else if (data['data'] != null && data['data']['profilePicture'] != null) {
          profilePictureUrl = _formatProfilePictureUrl(data['data']['profilePicture']);
        }
        
        if (profilePictureUrl != null) {
          // Update current profile with new picture URL
          if (_currentProfile != null) {
            _currentProfile = _currentProfile!.copyWith(avatarUrl: profilePictureUrl);
            await _saveUserProfile(_currentProfile!);
            
            // Force refresh the profile data
            await _loadUserProfile();
            
            // Notify listeners to update UI
            notifyListeners();
            
            debugPrint('Profile picture updated successfully: $profilePictureUrl');
          }
          
          return profilePictureUrl;
        }
      } else if (response.statusCode == 400) {
        // Handle bad request errors specifically
        debugPrint('Bad request error (400): ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Unknown error';
          debugPrint('Error message: $errorMessage');
        } catch (e) {
          debugPrint('Could not parse error response: $e');
        }
      }

      // If upload fails, fall back to local file reference
      debugPrint('Profile picture upload failed, using local file reference');
      return 'file://$filePath';
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }
}
