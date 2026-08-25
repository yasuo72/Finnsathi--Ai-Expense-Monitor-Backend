import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/receipt_scanner_screen.dart';
import '../screens/receipt_history_screen.dart';
import '../screens/wallet/send_money_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/wallet/request_money_screen.dart';
import '../screens/shop/order_tracking_screen.dart';
import '../screens/shop/shop_notifications_screen.dart';
import '../models/shop_models.dart'; // Import for Order model
import '../screens/profile/profile_main.dart'; // Import for Profile section
import '../screens/api_test_screen.dart'; // Import for API test screen
import '../services/auth_state_service.dart'; // Import for authentication checks
import '../screens/voice_assistant_screen.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/savings_goal_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/settings_screen.dart';
import '../models/finance_models.dart';

// Import loading and onboarding screens with aliases
import '../screens/loading_screen_new.dart' as new_loading;
import '../screens/onboarding_screen_new.dart' as new_onboarding;
import '../screens/auth/signin_screen_new.dart' as new_signin;
import '../screens/auth/signup_screen_new.dart' as new_signup;
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/forgot_otp_screen.dart';
import '../screens/auth/new_password_screen.dart';

/// Class that handles all the app routes
class AppRoutes {
  static const String shopFilters = '/shop/filters';
  static const String favoriteShops = '/shop/favorites';
  static const String shopReviews = '/shop/reviews';
  static const String orderTracking = '/shop/order-tracking';
  static const String shopNotifications = '/shop/notifications';
  static const String profile = '/profile';
  static const String apiTest = '/api-test';
  static const String receiptHistory = '/receipt_history';
  static const String voiceAssistant = '/voice-assistant';

  /// Helper method to create a route that requires authentication
  /// If user is not authenticated, they will be redirected to the sign-in screen
  static Route<dynamic> _createProtectedRoute(Widget Function() builder) {
    return MaterialPageRoute(
      builder:
          (context) => FutureBuilder<bool>(
            future: AuthStateService.isLoggedIn(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final isLoggedIn = snapshot.data ?? false;
              if (isLoggedIn) {
                return builder();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/signin', (route) => false);
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case '/splash':
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        case '/loading':
          return MaterialPageRoute(
            builder: (_) => const new_loading.LoadingScreen(),
          );

        case '/onboarding':
          return MaterialPageRoute(
            builder:
                (context) => new_onboarding.OnboardingScreen(
                  onFinish:
                      () => Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/signin', (route) => false),
                ),
          );

        case '/signin':
          return MaterialPageRoute(
            builder: (_) => const new_signin.SignInScreen(),
          );

        case '/signup':
          return MaterialPageRoute(
            builder: (_) => const new_signup.SignUpScreen(),
          );

        case '/forgot-password':
          return MaterialPageRoute(
            builder: (_) => const ForgotPasswordScreen(),
          );

        case '/forgot-otp':
          return MaterialPageRoute(
            builder: (_) => const ForgotOtpScreen(),
            settings: settings, // Pass settings to access arguments
          );

        case '/new-password':
          return MaterialPageRoute(
            builder: (_) => const NewPasswordScreen(),
            settings: settings, // Pass settings to access arguments
          );

        case AppRoutes.orderTracking:
          // For OrderTrackingScreen, we need to handle the order parameter at runtime
          // Check if arguments is of type Order, otherwise handle the error
          if (settings.arguments is Order) {
            return _createProtectedRoute(
              () => OrderTrackingScreen(order: settings.arguments as Order),
            );
          } else {
            // Handle the case where arguments is not an Order
            return MaterialPageRoute(
              builder:
                  (_) => const Scaffold(
                    body: Center(child: Text('Invalid order data')),
                  ),
            );
          }

        case AppRoutes.shopNotifications:
          return _createProtectedRoute(() => const ShopNotificationPage());

        case '/':
          // Check authentication before allowing access to home screen
          return _createProtectedRoute(() => const HomeScreen());

        case '/receipt-scanner':
          return _createProtectedRoute(() => const ReceiptScannerScreen());

        case AppRoutes.receiptHistory:
          return _createProtectedRoute(() => const ReceiptHistoryScreen());

        case '/statistics':
          return _createProtectedRoute(() => const StatisticsScreen());

        case '/send-money':
          return _createProtectedRoute(() => const SendMoneyScreen());

        case '/request-money':
          return _createProtectedRoute(() => const RequestMoneyScreen());

        case '/add-transaction':
          // Optional arguments can specify the transaction type
          TransactionType type = TransactionType.expense;
          if (settings.arguments is Map) {
            final args = settings.arguments as Map;
            if (args['type'] is TransactionType) {
              type = args['type'] as TransactionType;
            }
          }
          return _createProtectedRoute(() => AddTransactionScreen(type: type));

        case '/budget':
          return _createProtectedRoute(() => const BudgetScreen());

        case '/savings-goals':
        case '/savings_goals':
          return _createProtectedRoute(() => const SavingsGoalScreen());

        case '/wallet':
          return _createProtectedRoute(() => const WalletScreen());

        case '/settings':
          return _createProtectedRoute(() => const SettingsScreen());

        case '/home':
          return _createProtectedRoute(() => const HomeScreen());

        case AppRoutes.profile:
          return _createProtectedRoute(() => const ProfileMain());

        case AppRoutes.apiTest:
          return MaterialPageRoute(builder: (_) => const ApiTestScreen());

        case AppRoutes.voiceAssistant:
          return _createProtectedRoute(() => const VoiceAssistantScreen());

        default:
          // If the route is not found, show a 404 page
          return MaterialPageRoute(
            builder:
                (_) => Scaffold(
                  appBar: AppBar(title: const Text('Page Not Found')),
                  body: const Center(
                    child: Text('The requested page was not found.'),
                  ),
                ),
          );
      }
    } catch (e) {
      debugPrint('❌ Error generating route: $e');
      // Fallback route in case of any errors
      return MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: const Text('Navigation Error')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('An error occurred during navigation.'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {}, // Simplified for error recovery
                      child: const Text('Go to Sign In'),
                    ),
                  ],
                ),
              ),
            ),
      );
    }
  }
}

// TransactionType is imported from finance_models.dart for route arguments
