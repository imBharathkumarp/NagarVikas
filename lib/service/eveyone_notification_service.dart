import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class EveryoneNotificationService {
  static final EveryoneNotificationService _instance = EveryoneNotificationService._internal();
  factory EveryoneNotificationService() => _instance;
  EveryoneNotificationService._internal();

  final DatabaseReference _notificationsRef = FirebaseDatabase.instance.ref("everyone_notifications/");
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users/");

  /// Send @everyone notification
  Future<void> sendEveryoneNotification({
    required String messageId,
    required String senderId,
    required String senderName,
    required String messageText,
  }) async {
    try {
      // Create notification record
      final notificationData = {
        'messageId': messageId,
        'senderId': senderId,
        'senderName': senderName,
        'messageText': messageText,
        'timestamp': ServerValue.timestamp,
        'type': 'everyone',
      };

      // Store in Firebase
      await _notificationsRef.child(messageId).set(notificationData);

      // Get all users to send notifications
      final usersSnapshot = await _usersRef.once();
      if (usersSnapshot.snapshot.exists) {
        final usersData = Map<String, dynamic>.from(usersSnapshot.snapshot.value as Map);
        
        // Send local notification to all users (except sender)
        for (String userId in usersData.keys) {
          if (userId != senderId) {
            await _sendLocalNotificationToUser(userId, senderName, messageText);
          }
        }
      }
    } catch (e) {
      print('Error sending @everyone notification: $e');
      throw e;
    }
  }

  /// Send local notification to specific user
  Future<void> _sendLocalNotificationToUser(String userId, String senderName, String messageText) async {
    try {
      // Check if user has already been notified for this message
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Only send notification if this is the target user
      if (currentUserId == userId) {
        await NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '@everyone from $senderName',
          body: messageText.length > 50 
              ? '${messageText.substring(0, 50)}...' 
              : messageText,
          payload: 'everyone_message',
        );
      }
    } catch (e) {
      print('Error sending local notification: $e');
    }
  }

  /// Check if message contains @everyone
  static bool containsEveryone(String message) {
    return message.toLowerCase().contains('@everyone');
  }

  /// Replace @everyone with highlighted version for display
  static String highlightEveryone(String message) {
    return message.replaceAllMapped(
      RegExp(r'@everyone', caseSensitive: false),
      (match) => '[@everyone]', // We'll style this specially in the UI
    );
  }

  /// Listen for @everyone notifications for current user
  StreamSubscription<DatabaseEvent>? listenForEveryoneNotifications(String userId, Function(Map<String, dynamic>) onNotification) {
    return _notificationsRef
        .orderByChild('timestamp')
        .limitToLast(1)
        .onChildAdded
        .listen((event) async {
      if (event.snapshot.exists) {
        final notificationData = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Don't notify the sender
        if (notificationData['senderId'] != userId) {
          // Check if we've already notified this user for this message
          final prefs = await SharedPreferences.getInstance();
          final notifiedKey = 'notified_${event.snapshot.key}_$userId';
          
          if (!prefs.containsKey(notifiedKey)) {
            await prefs.setBool(notifiedKey, true);
            onNotification(notificationData);
          }
        }
      }
    });
  }
}