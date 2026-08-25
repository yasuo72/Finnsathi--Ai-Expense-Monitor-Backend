import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../services/api_service_manager.dart';

/// This file contains provider setup for API-related services
/// It can be used in the main.dart file to wrap the app with these providers

List<SingleChildWidget> getApiProviders() {
  return [
    ChangeNotifierProvider<ApiServiceManager>(
      create: (_) => ApiServiceManager(),
    ),
  ];
}

/// Extension method to easily access the ApiServiceManager from any widget
extension ApiServiceManagerExtension on BuildContext {
  ApiServiceManager get apiManager => Provider.of<ApiServiceManager>(this, listen: false);
  
  /// Use this when you want to listen to changes in the ApiServiceManager
  ApiServiceManager get watchApiManager => Provider.of<ApiServiceManager>(this);
}
