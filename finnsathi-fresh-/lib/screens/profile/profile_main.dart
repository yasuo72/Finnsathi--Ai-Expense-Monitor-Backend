import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/security_screen.dart';
import 'screens/linked_accounts_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/about_screen.dart';

/// Main entry point for the Profile section
/// This handles all the routing within the profile section
class ProfileMain extends StatelessWidget {
  const ProfileMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initial route is the main profile screen
    return Navigator(
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget screen;
        
        // Handle different routes within the profile section
        switch (settings.name) {
          case '/':
            screen = const ProfileScreen();
            break;
          case '/edit':
            screen = const EditProfileScreen();
            break;
          case '/security':
            screen = const SecurityScreen();
            break;
          case '/linked-accounts':
            screen = const LinkedAccountsScreen();
            break;
          case '/support':
            screen = const HelpSupportScreen();
            break;
          case '/about':
            screen = const AboutScreen();
            break;
          default:
            screen = const ProfileScreen();
        }
        
        // Use the consistent page transition style
        return MaterialPageRoute(
          builder: (_) => screen,
          settings: settings,
        );
      },
    );
  }
}

// Create placeholder screens for the profile section
// These will be implemented in separate files later

// All placeholder screens have been replaced with fully implemented screens in their respective files
