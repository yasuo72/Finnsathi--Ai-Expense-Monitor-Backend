import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A service that handles navigation throughout the app
/// This allows for navigation without context in services and other non-widget classes
class NavigationService extends ChangeNotifier {
  static final NavigationService _instance = NavigationService._internal();
  
  factory NavigationService() => _instance;
  
  NavigationService._internal();
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Navigate to a named route
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }
  
  /// Replace the current route with a new named route
  Future<dynamic> replaceTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }
  
  /// Navigate back to the previous route
  void goBack() {
    return navigatorKey.currentState!.pop();
  }
  
  /// Navigate back to a specific route, removing all routes until that one
  void goBackToRoute(String routeName) {
    navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }
  
  /// Static helper method to navigate with context
  /// This is useful when you don't have access to the navigator key
  static Future<dynamic> navigate(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }
  
  /// Static helper method to replace current route with context
  static Future<dynamic> replace(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
  }
  
  /// Static helper method to go back with context
  static void back(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  /// Static helper method to go back to a specific route with context
  static void backToRoute(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(ModalRoute.withName(routeName));
  }
  
  /// Static helper method to navigate to a route and remove all previous routes
  static void navigateAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}
