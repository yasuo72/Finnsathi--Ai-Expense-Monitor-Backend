import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationApiService extends ChangeNotifier {
  // Notification data
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  
  // Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  
  // Constructor
  NotificationApiService() {
    _initialize();
  }
  
  // Initialize the service
  Future<void> _initialize() async {
    await _loadLocalNotifications();
    await refreshNotifications();
  }
  
  // Get all notifications for the current user
  static Future<List<Map<String, dynamic>>> getAllNotifications() async {
    try {
      print('Fetching notifications from: ${ApiConfig.notifications}');
      
      // Check if auth token exists before making the request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token found. User may not be logged in properly.');
        return [];
      }
      
      print('🔑 Using auth token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
      final data = await ApiService.get(ApiConfig.notifications);
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }
  
  // Refresh notifications (non-static method for the instance)
  Future<void> refreshNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final notifications = await getAllNotifications();
      _notifications = notifications;
      
      // Update unread count
      await refreshUnreadCount();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error refreshing notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get unread notifications count
  static Future<int> getUnreadCount() async {
    try {
      final data = await ApiService.get('${ApiConfig.notifications}/unread-count');
      
      if (data != null && data['success'] == true && data['count'] != null) {
        return data['count'];
      }
      
      // If the endpoint doesn't exist, count unread notifications manually
      final notifications = await getAllNotifications();
      return notifications.where((n) => n['isRead'] == false).length;
    } catch (e) {
      print('Error fetching unread notifications count: $e');
      return 0;
    }
  }
  
  // Refresh unread count (non-static method for the instance)
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error refreshing unread count: $e');
    }
  }
  
  // Mark a notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final data = await ApiService.put(
        '${ApiConfig.notifications}/$notificationId/read',
        {}
      );
      
      return data != null && data['success'] == true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }
  
  // Mark a notification as read (non-static method for the instance)
  Future<bool> markNotificationAsRead(String notificationId) async {
    final success = await markAsRead(notificationId);
    
    if (success) {
      // Update the notification in the local list
      final index = _notifications.indexWhere((n) => n['_id'] == notificationId || n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        
        // Decrease unread count
        if (_unreadCount > 0) _unreadCount--;
        
        notifyListeners();
      }
    }
    
    return success;
  }
  
  // Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final data = await ApiService.put(
        '${ApiConfig.notifications}/read-all',
        {}
      );
      
      return data != null && data['success'] == true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
  
  // Mark all notifications as read (non-static method for the instance)
  Future<bool> markAllNotificationsAsRead() async {
    final success = await markAllAsRead();
    
    if (success) {
      // Update all notifications in the local list
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
      
      // Reset unread count
      _unreadCount = 0;
      
      notifyListeners();
    }
    
    return success;
  }
  
  // Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final data = await ApiService.delete('${ApiConfig.notifications}/$notificationId');
      
      return data != null && data['success'] == true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
  
  // Delete a notification (non-static method for the instance)
  Future<bool> removeNotification(String notificationId) async {
    final success = await deleteNotification(notificationId);
    
    if (success) {
      // Remove the notification from the local list
      final index = _notifications.indexWhere((n) => n['_id'] == notificationId || n['id'] == notificationId);
      if (index != -1) {
        final wasUnread = _notifications[index]['isRead'] == false;
        _notifications.removeAt(index);
        
        // Decrease unread count if it was unread
        if (wasUnread && _unreadCount > 0) _unreadCount--;
        
        notifyListeners();
      }
    }
    
    return success;
  }
  
  // Update notification preferences
  static Future<bool> updateNotificationPreferences(Map<String, bool> preferences) async {
    try {
      final data = await ApiService.put(
        '${ApiConfig.notifications}/settings',
        preferences
      );
      
      return data != null && data['success'] == true;
    } catch (e) {
      print('Error updating notification preferences: $e');
      return false;
    }
  }
  
  // Get notification preferences
  static Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final data = await ApiService.get('${ApiConfig.notifications}/settings');
      
      if (data != null && data['success'] == true && data['data'] != null) {
        return Map<String, bool>.from(data['data']);
      }
      
      return {};
    } catch (e) {
      print('Error fetching notification preferences: $e');
      return {};
    }
  }
  
  // Create a local notification (for events that happen in the app)
  Future<void> createLocalNotification(String title, String message, {String type = 'info'}) async {
    try {
      // Create a local notification object
      final notification = {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'date': DateTime.now().toIso8601String(),
      };
      
      // Add to the local list
      _notifications.insert(0, notification);
      _unreadCount++;
      
      // Save to local storage for persistence
      await _saveLocalNotifications();
      
      notifyListeners();
    } catch (e) {
      print('Error creating local notification: $e');
    }
  }
  
  // Save local notifications to shared preferences
  Future<void> _saveLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Only save local notifications (those with IDs starting with 'local_')
      final localNotifications = _notifications
          .where((n) => (n['id'] as String).startsWith('local_'))
          .toList();
      
      await prefs.setString('local_notifications', jsonEncode(localNotifications));
    } catch (e) {
      print('Error saving local notifications: $e');
    }
  }
  
  // Load local notifications from shared preferences
  Future<void> _loadLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localNotificationsJson = prefs.getString('local_notifications');
      
      if (localNotificationsJson != null) {
        final List<dynamic> decoded = jsonDecode(localNotificationsJson);
        final localNotifications = List<Map<String, dynamic>>.from(decoded);
        
        // Add local notifications to the list
        _notifications.addAll(localNotifications);
        
        // Update unread count
        final localUnreadCount = localNotifications.where((n) => n['isRead'] == false).length;
        _unreadCount += localUnreadCount;
      }
    } catch (e) {
      print('Error loading local notifications: $e');
    }
  }
}
