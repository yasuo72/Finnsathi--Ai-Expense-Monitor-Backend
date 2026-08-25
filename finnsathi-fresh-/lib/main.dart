// Finsaathi Multi App - Custom Sign Up Screen
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'services/theme_service.dart';
import 'services/navigation_service.dart';
import 'routing/app_routes.dart';
// These screens are imported in their respective parent screens
import 'services/finance_service.dart';
import 'services/ai_chat_service.dart';
import 'services/wallet_service.dart';
import 'services/profile_service.dart';
import 'services/gamification_service.dart';
// API services for backend integration
import 'providers/api_providers.dart';
import 'services/api_service_manager.dart';
import 'app_config.dart';
import 'config/api_config.dart';
import 'services/google_auth_service.dart';
import 'services/shop_service.dart';

// Define color constants for consistent usage
const Color kPrimaryColor = Color(0xFF3F51B5); // Indigo for primary actions
const Color kSecondaryColor = Color(
  0xFF7986CB,
); // Lighter indigo for secondary elements
const Color kAccentColor = Color(
  0xFF4CAF50,
); // Green for accents and success states
const Color kErrorColor = Color(0xFFE57373); // Soft red for errors

// Light theme colors
const Color kLightBackground = Color(0xFFF5F7FA); // Soft off-white background
const Color kLightSurface = Colors.white; // White surface
const Color kLightText = Color(0xFF424242); // Dark grey for text
const Color kLightSecondaryText = Color(
  0xFF757575,
); // Medium grey for secondary text

// Dark theme colors
const Color kDarkBackground = Color(0xFF121212); // Material dark background
const Color kDarkSurface = Color(0xFF1E1E1E); // Slightly lighter surface
const Color kDarkCardColor = Color(0xFF252525); // Card color for dark mode
const Color kDarkText = Color(0xFFEEEEEE); // Off-white for text
const Color kDarkSecondaryText = Color(
  0xFFB0B0B0,
); // Light grey for secondary text

final lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kPrimaryColor,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: kLightBackground,
  cardColor: kLightSurface,
  shadowColor: Colors.black.withOpacity(0.1),
  dividerColor: Colors.grey.shade200,
  appBarTheme: const AppBarTheme(
    backgroundColor: kLightSurface,
    elevation: 0,
    iconTheme: IconThemeData(color: kLightText),
    titleTextStyle: TextStyle(
      color: kLightText,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: kLightSurface,
    selectedItemColor: kPrimaryColor,
    unselectedItemColor: Colors.grey.shade600,
    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
    elevation: 8,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: kLightText),
    bodyMedium: TextStyle(color: kLightText),
    titleLarge: TextStyle(color: kLightText, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: kLightText, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: kLightSecondaryText),
    labelLarge: TextStyle(color: kLightText),
  ),
  colorScheme: const ColorScheme.light(
    primary: kPrimaryColor,
    secondary: kSecondaryColor,
    tertiary: kAccentColor,
    surface: kLightSurface,
    background: kLightBackground,
    error: kErrorColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: kLightText,
    onBackground: kLightText,
    onError: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: kPrimaryColor,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: kDarkBackground,
  cardColor: kDarkCardColor,
  shadowColor: Colors.black.withOpacity(0.3),
  dividerColor: Colors.grey.shade800,
  appBarTheme: const AppBarTheme(
    backgroundColor: kDarkSurface,
    elevation: 0,
    iconTheme: IconThemeData(color: kDarkText),
    titleTextStyle: TextStyle(
      color: kDarkText,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kDarkSurface,
    selectedItemColor: kSecondaryColor,
    unselectedItemColor: Colors.grey,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
    elevation: 8,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: kDarkText),
    bodyMedium: TextStyle(color: kDarkText),
    titleLarge: TextStyle(color: kDarkText, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: kDarkText, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: kDarkSecondaryText),
    labelLarge: TextStyle(color: kDarkText),
  ),
  colorScheme: const ColorScheme.dark(
    primary: kSecondaryColor, // Using a lighter shade for dark mode
    secondary: kPrimaryColor,
    tertiary: kAccentColor,
    surface: kDarkSurface,
    background: kDarkBackground,
    error: kErrorColor,
    onPrimary: kDarkText,
    onSecondary: kDarkText,
    onSurface: kDarkText,
    onBackground: kDarkText,
    onError: kDarkText,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kSecondaryColor,
      foregroundColor: kDarkText,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kDarkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade800),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kSecondaryColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: kDarkSecondaryText),
    hintStyle: const TextStyle(color: kDarkSecondaryText),
  ),
);

// Platform-specific channel for performance optimizations
const platform = MethodChannel('com.finsaathi/performance');

// Completer for background initialization
final Completer<void> _backgroundInitCompleter = Completer<void>();

// Run background initialization tasks
Future<void> _runBackgroundInit() async {
  try {
    // Pre-initialize heavy components in background
    await AppConfig.initialize();

    // Pre-warm the network connection to backend
    final apiUrl =
        'finnsathi-ai-expense-monitor-backend-production.up.railway.app';
    await http.get(Uri.https(apiUrl, '/health'));

    _backgroundInitCompleter.complete();
  } catch (e) {
    // Complete even if there's an error to avoid blocking the app
    _backgroundInitCompleter.complete();
    debugPrint('Background initialization error: $e');
  }
}

Future<void> main() async {
  // Start measuring app startup time
  final startTime = DateTime.now().millisecondsSinceEpoch;

  // Ensure Flutter is initialized with optimized settings
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Apply aggressive optimizations for faster startup

  // Start background initialization immediately
  _runBackgroundInit();

  // Configure Flutter engine for performance
  binding.renderView.automaticSystemUiAdjustment = false;

  // Set system UI overlay style to make navigation bar match theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Make the status bar transparent and use light icons for dark theme
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      // Make the navigation bar dark with light icons
      systemNavigationBarColor:
          Colors
              .transparent, // Use dark background color instead of transparent
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced:
          false, // Disable contrast enforcement
    ),
  );

  // Configure system UI mode for proper display
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  // Run critical UI setup in parallel
  final futures = <Future>[];

  // Set preferred orientation
  // futures.add(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));

  // Optimize system UI mode for faster startup
  // futures.add(SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.edgeToEdge,
  //   overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  // ));

  // Load environment variables
  futures.add(dotenv.load());

  // Wait for critical UI configurations to complete
  await Future.wait(futures);

  // Initialize services in parallel for faster startup
  final financeService = FinanceService();
  final themeService = ThemeService();
  final walletService = WalletService();
  final profileService = ProfileService();
  final navigationService = NavigationService();
  final apiServiceManager = ApiServiceManager();
  final shopService = ShopService();

  // Use real API data to connect with Railway backend
  if (AppConfig.useMockData) {
    AppConfig.setUseMockData(false); // Don't await this
  }

  // Notify native code that Flutter is ready
  try {
    await platform.invokeMethod('optimizePerformance');
  } catch (e) {
    // Ignore errors, this is just an optimization
  }

  // Log startup time
  final endTime = DateTime.now().millisecondsSinceEpoch;
  debugPrint('App startup time: ${endTime - startTime} ms');

  // Start initialization in parallel
  financeService.init();
  themeService.init();

  // Create AI chat service using finance service (it will update as data loads)
  final aiChatService = AIChatService(financeService, 'Global');

  // Run the app with error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    // In production, you might want to log to a service
  };

  runApp(
    MultiProvider(
      providers: [
        // Core app services
        ChangeNotifierProvider<FinanceService>(
          create: (context) => financeService,
        ),
        ChangeNotifierProvider<ThemeService>(create: (context) => themeService),
        ChangeNotifierProvider<NavigationService>(
          create: (context) => navigationService,
        ),
        ChangeNotifierProvider<ProfileService>(
          create: (context) => profileService,
        ),
        ChangeNotifierProvider<WalletService>(
          create: (context) => walletService,
        ),
        ChangeNotifierProvider<ShopService>(create: (context) => shopService),
        ChangeNotifierProvider<AIChatService>(
          create: (context) => aiChatService,
        ),
        ChangeNotifierProvider<GamificationService>(
          create: (context) {
            final financeService = Provider.of<FinanceService>(
              context,
              listen: false,
            );
            return GamificationService(profileService, financeService);
          },
        ),
        // Add API service providers for backend integration
        ChangeNotifierProvider<ApiServiceManager>(
          create: (context) => apiServiceManager,
        ),
        // Include all API-related providers
        ...getApiProviders(),
      ],
      child: const FinsaathiApp(),
    ),
  );
}

class FinsaathiApp extends StatefulWidget {
  const FinsaathiApp({super.key});

  @override
  FinsaathiAppState createState() => FinsaathiAppState();
}

class FinsaathiAppState extends State<FinsaathiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize GoogleAuthService with better error handling
    try {
      GoogleAuthService.initialize()
          .then((_) {
            debugPrint('⚠️ GoogleAuthService initialized successfully');
          })
          .catchError((error) {
            debugPrint('❌ Error initializing GoogleAuthService: $error');
          });
    } catch (e) {
      debugPrint('❌ Critical error initializing GoogleAuthService: $e');
    }

    // Wait for the background initialization to complete
    _backgroundInitCompleter.future.then((_) {
      debugPrint('Background initialization completed');
      // Pre-warm image cache to avoid stutters
      PaintingBinding.instance.imageCache.maximumSize = 100;
    });

    // Initialize API services
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Test backend connection first
      final isConnected = await ApiConfig.testConnection();
      print('Backend connection test result: $isConnected');

      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Cannot connect to the backend server. Please check your internet connection or try again later.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () async {
                final retryResult = await ApiConfig.testConnection();
                if (retryResult) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connection successful!')),
                  );
                }
              },
            ),
          ),
        );
      }

      // Initialize API Service Manager after the first frame
      Provider.of<ApiServiceManager>(context, listen: false).initializeData();

      // Show notification about mock data mode if enabled
      if (AppConfig.useMockData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'App is running in offline mode due to backend server issues. Your data will not be saved to the cloud.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to improve stability
    if (state == AppLifecycleState.resumed) {
      // Clear caches when app is resumed to free up memory
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get ThemeService instance from provider
    final themeService = Provider.of<ThemeService>(context);
    final navigationService = Provider.of<NavigationService>(
      context,
      listen: false,
    );

    // Ensure system UI settings are consistently applied
    final isDarkMode = themeService.isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // Make the status bar transparent and use appropriate icons based on theme
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        // Make the navigation bar transparent with appropriate icons based on theme
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finsaathi Multi',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Add navigation key from service
      navigatorKey: navigationService.navigatorKey,
      // Reduce animations slightly to avoid OpenGL issues
      builder: (context, child) {
        // Apply a global configuration to images to prevent OpenGL issues
        return MediaQuery(
          // Set a safer text scale factor
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      // Skip the animated splash screen for faster startup
      // Navigate directly to a lightweight loading screen
      initialRoute: '/loading',
      // Use the onGenerateRoute to handle app routes
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF4866FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF4866FF)),
        ),
      ),
    );
  }
}
