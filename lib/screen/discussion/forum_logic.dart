import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ForumLogic {
  /// Get current user name from Firebase or create default
  static void getCurrentUserName(
    String? userId,
    DatabaseReference usersRef,
    Function(String) onNameReceived,
  ) async {
    if (userId != null) {
      try {
        final snapshot = await usersRef.child(userId).once();
        if (snapshot.snapshot.value != null) {
          final userData =
              Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          onNameReceived(
              userData['name'] ?? userData['displayName'] ?? _getDefaultName());
        } else {
          final defaultName = _getDefaultName();
          await usersRef.child(userId).set({
            'name': defaultName,
            'displayName': defaultName,
            'email': FirebaseAuth.instance.currentUser?.email ?? '',
            'createdAt': ServerValue.timestamp,
          });
          onNameReceived(defaultName);
        }
      } catch (e) {
        print('Error getting user name: $e');
        onNameReceived(_getDefaultName());
      }
    }
  }

  /// Generate default name for user
  static String _getDefaultName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      return user!.email!.split('@')[0];
    }
    return 'User${Random().nextInt(1000)}';
  }

  /// Format timestamp for display
  static String formatTime(dynamic timeValue) {
    if (timeValue == null) return '';

    try {
      DateTime dateTime;
      if (timeValue is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timeValue);
      } else {
        return '';
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        return DateFormat('h:mm a').format(dateTime);
      } else if (messageDate == today.subtract(Duration(days: 1))) {
        return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
      } else {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  /// Get date string for separator
  static String getDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return "Today";
    } else if (messageDate == yesterday) {
      return "Yesterday";
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
    } else {
      return DateFormat('MMM d, y').format(date); // Jan 15, 2024
    }
  }

  /// Get avatar color based on user name
  static Color getAvatarColor(String name) {
    final colors = [
      Color(0xFFef5350), // red[400]
      Color(0xFF42a5f5), // blue[400]
      Color(0xFF66bb6a), // green[400]
      Color(0xFFff9800), // orange[400]
      Color(0xFFab47bc), // purple[400]
      Color(0xFF26a69a), // teal[400]
      Color(0xFF5c6bc0), // indigo[400]
      Color(0xFFec407a), // pink[400]
    ];
    return colors[name.hashCode % colors.length];
  }

  /// Build terms section with title and bullet points
  static Widget buildTermsSection(
    String title,
    List<String> points,
    bool isDarkMode,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        ...points
            .map((point) => Padding(
                  padding:
                      EdgeInsets.only(left: 8, bottom: isSmallScreen ? 3 : 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• ",
                        style: TextStyle(
                          color: isDarkMode
                              ? Color(0xFFbdbdbd) // grey[400]
                              : Color(0xFF757575), // grey[600]
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            color: isDarkMode
                                ? Color(0xFFe0e0e0) // grey[300]
                                : Color(0xFF616161), // grey[700]
                            fontSize: isSmallScreen ? 12 : 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}
