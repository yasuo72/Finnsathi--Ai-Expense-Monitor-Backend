// Platform-specific imports removed as we're using Railway backend by default
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  // Flag to use mock data instead of real API
  static bool _useMockData = false; // Set back to false to use real backend
  static bool get useMockData => _useMockData;
  static set useMockData(bool value) => _useMockData = value;

  // Custom backend URL (can be set from settings)
  static String? _customBackendUrl;

  // Initialize config
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _useMockData =
        prefs.getBool('use_mock_data') ??
        false; // Default to false to use real backend
    _customBackendUrl = prefs.getString('custom_backend_url');

    // Use real backend connection
    _useMockData = false;
  }

  // Toggle mock data usage
  static Future<void> setUseMockData(bool value) async {
    _useMockData = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_mock_data', value);
  }

  // Set custom backend URL
  static Future<void> setCustomBackendUrl(String? url) async {
    _customBackendUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.isNotEmpty) {
      await prefs.setString('custom_backend_url', url);
    } else {
      await prefs.remove('custom_backend_url');
    }
  }

  // API base URL for endpoints (with /api suffix)
  static String get apiBaseUrl => backendBaseUrl + '/api';
  static set apiBaseUrl(String url) {
    // Extract the base URL without the /api suffix
    if (url.endsWith('/api')) {
      setCustomBackendUrl(url.substring(0, url.length - 4));
    } else {
      setCustomBackendUrl(url);
    }
  }

  // Save all settings at once
  static Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_mock_data', _useMockData);
    if (_customBackendUrl != null && _customBackendUrl!.isNotEmpty) {
      await prefs.setString('custom_backend_url', _customBackendUrl!);
    } else {
      await prefs.remove('custom_backend_url');
    }
  }

  // Base URL for the backend API
  static String get backendBaseUrl {
    // Use custom URL if set
    if (_customBackendUrl != null && _customBackendUrl!.isNotEmpty) {
      return _customBackendUrl!;
    }

    // Try to get from .env file
    final envUrl = dotenv.env['BACKEND_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Use Railway backend URL
    return 'https://finnsathi-ai-expense-monitor-backend-production.up.railway.app';

    // Fallback to local development URLs if Railway is not available
    // if (Platform.isAndroid) {
    //   // 10.0.2.2 is the special IP that Android emulators use to connect to localhost
    //   return 'http://10.0.2.2:5000';
    // } else if (Platform.isIOS) {
    //   // For iOS simulator
    //   return 'http://localhost:5000';
    // } else {
    //   // Default for other platforms
    //   return 'http://localhost:5000';
    // }
  }

  // API base path
  static String get apiBasePath => '/api';

  // App name
  static String get appName => 'FinSathi';

  // App version
  static String get appVersion => '1.0.0';
}
