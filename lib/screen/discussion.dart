import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_provider.dart';

/// DiscussionForum
/// A real-time chat interface where users can post and view messages.
/// Uses Firebase Realtime Database for message storage.

class DiscussionForum extends StatefulWidget {
  const DiscussionForum({super.key});

  @override
  DiscussionForumState createState() => DiscussionForumState();
}

class DiscussionForumState extends State<DiscussionForum>
    with TickerProviderStateMixin {
  final TextEditingController _messageController =
  TextEditingController(); // Controls text input
  final DatabaseReference _messagesRef =
  FirebaseDatabase.instance.ref("discussion/"); // Firebase DB ref
  final DatabaseReference _usersRef =
  FirebaseDatabase.instance.ref("users/"); // Users DB ref
  final ScrollController _scrollController =
  ScrollController(); // Scroll controller for ListView
  String? userId;
  String? currentUserName;
  bool _showDisclaimer = true;
  bool _hasAgreedToTerms = false;
  bool _showTermsDialog = false;

  // Animation controllers for enhanced UI
  late AnimationController _sendButtonAnimationController;
  late AnimationController _messageAnimationController;
  late AnimationController _disclaimerController;
  late Animation<double> _sendButtonScaleAnimation;
  late Animation<double> _messageSlideAnimation;

  bool _isTyping = false;
  String? _replyingToMessageId;
  String? _replyingToMessage;
  String? _replyingToSender;
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid; // Get current user ID
    _getCurrentUserName();
    _checkTermsAgreement();
    _initAnimations();

    // Listen to text changes for typing indicator
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });

    // Auto-hide disclaimer after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted && _showDisclaimer && _hasAgreedToTerms) {
        _hideDisclaimer();
      }
    });
  }

  @override
  void dispose() {
    _sendButtonAnimationController.dispose();
    _messageAnimationController.dispose();
    _disclaimerController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _sendButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _disclaimerController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _disclaimerController.forward();

    _sendButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _sendButtonAnimationController,
      curve: Curves.easeInOut,
    ));

    _messageSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _hideDisclaimer() {
    if (_showDisclaimer) {
      _disclaimerController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showDisclaimer = false;
          });
        }
      });
    }
  }

  /// Check if user has agreed to terms and conditions
  void _checkTermsAgreement() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'terms_agreed_${userId ?? 'anonymous'}';
    bool hasAgreed = prefs.getBool(key) ?? false;

    setState(() {
      _hasAgreedToTerms = hasAgreed;
      _showTermsDialog = !hasAgreed;
    });
  }

  /// Save terms agreement to local storage
  void _agreeToTerms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'terms_agreed_${userId ?? 'anonymous'}';
    await prefs.setBool(key, true);

    setState(() {
      _hasAgreedToTerms = true;
      _showTermsDialog = false;
    });
  }

  /// Build terms and conditions dialog
  Widget _buildTermsDialog(ThemeProvider themeProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenHeight < 700 || screenWidth < 400;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 20 : 40,
          ),
          child: Container(
            width: screenWidth > 500 ? 450 : screenWidth * 0.9,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
              maxWidth: screenWidth > 500 ? 450 : screenWidth * 0.9,
            ),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.gavel,
                          size: isSmallScreen ? 32 : 40,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 20),

                      // Title
                      Text(
                        "Terms & Community Guidelines",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Terms content - Flexible height
                Flexible(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24),
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTermsSection(
                            "Discussion Forum Guidelines",
                            [
                              "Be respectful and courteous to all participants",
                              "No abusive, offensive, or discriminatory language",
                              "Keep discussions constructive and on-topic",
                              "No spam, advertising, or promotional content",
                              "Respect privacy - no sharing personal information",
                              "Report inappropriate content to moderators"
                            ],
                            themeProvider,
                            isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildTermsSection(
                            "Terms of Use",
                            [
                              "You must be 13+ years old to participate",
                              "Content posted becomes part of public discussion",
                              "We reserve the right to moderate content",
                              "Violations may result in restricted access",
                              "Use at your own risk and responsibility"
                            ],
                            themeProvider,
                            isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildTermsSection(
                            "Privacy & Data",
                            [
                              "Messages are stored securely in our database",
                              "Your display name will be visible to others",
                              "We don't share personal data with third parties",
                              "You can request data deletion anytime"
                            ],
                            themeProvider,
                            isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom section with agreement text and buttons
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    children: [
                      // Agreement text
                      Text(
                        "By clicking 'I Agree', you acknowledge that you have read and agree to abide by these terms and guidelines.",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey[400]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _agreeToTerms,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2196F3),
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                "I Agree",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a terms section with title and bullet points
  Widget _buildTermsSection(String title, List<String> points, ThemeProvider themeProvider, bool isSmallScreen) {
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
                  color: themeProvider.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              Expanded(
                child: Text(
                  point,
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[300]
                        : Colors.grey[700],
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

  /// Get current user's display name
  void _getCurrentUserName() async {
    if (userId != null) {
      try {
        final snapshot = await _usersRef.child(userId!).once();
        if (snapshot.snapshot.value != null) {
          final userData =
          Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          setState(() {
            currentUserName = userData['name'] ??
                userData['displayName'] ??
                _getDefaultName();
          });
        } else {
          // If user data doesn't exist, create it with email prefix
          final defaultName = _getDefaultName();

          await _usersRef.child(userId!).set({
            'name': defaultName,
            'displayName': defaultName,
            'email': FirebaseAuth.instance.currentUser?.email ?? '',
            'createdAt': ServerValue.timestamp,
          });

          setState(() {
            currentUserName = defaultName;
          });
        }
      } catch (e) {
        print('Error getting user name: $e');
        setState(() {
          currentUserName = _getDefaultName();
        });
      }
    }
  }

  /// Get default name from email or generate random name
  String _getDefaultName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      return user!.email!.split('@')[0];
    }
    return 'User${Random().nextInt(1000)}';
  }

  /// Sends a message to Firebase Realtime Database
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || currentUserName == null)
      return;

    // Animate send button
    _sendButtonAnimationController.forward().then((_) {
      _sendButtonAnimationController.reverse();
    });

    Map<String, dynamic> messageData = {
      "message": _messageController.text.trim(),
      "senderId": userId,
      "senderName": currentUserName,
      "timestamp": ServerValue.timestamp,
      "createdAt": ServerValue.timestamp,
    };

    // Add reply information if replying
    if (_isReplying && _replyingToMessageId != null) {
      messageData["replyTo"] = _replyingToMessageId;
      messageData["replyToMessage"] = _replyingToMessage ?? '';
      messageData["replyToSender"] = _replyingToSender ?? 'Unknown User';
    }

    _messagesRef.push().set(messageData);

    _messageController.clear();
    _clearReply();
    setState(() {
      _isTyping = false;
    });

    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Set up reply to a message
  void _replyToMessage(String messageId, String message, String senderName) {
    setState(() {
      _isReplying = true;
      _replyingToMessageId = messageId;
      _replyingToMessage = message;
      _replyingToSender = senderName;
    });

    // Focus on text field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  /// Clear reply state
  void _clearReply() {
    setState(() {
      _isReplying = false;
      _replyingToMessageId = null;
      _replyingToMessage = null;
      _replyingToSender = null;
    });
  }

  /// Build reply indicator bar
  Widget _buildReplyIndicator(ThemeProvider themeProvider) {
    if (!_isReplying) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: const Color.fromARGB(255, 4, 204, 240),
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: const Color.fromARGB(255, 4, 204, 240),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyingToSender}',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 4, 204, 240),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _replyingToMessage ?? '',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearReply,
            child: Icon(
              Icons.close,
              size: 18,
              color: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the disclaimer banner
  Widget _buildDisclaimerBanner(ThemeProvider themeProvider) {
    return AnimatedBuilder(
      animation: _disclaimerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _disclaimerController.value)),
          child: Opacity(
            opacity: _disclaimerController.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2196F3).withOpacity(0.9),
                    Color(0xFF2196F3).withOpacity(0.7),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Be respectful • No abusive language • Keep discussions constructive",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _hideDisclaimer,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a single message bubble (left or right aligned)
  Widget _buildMessage(Map<String, dynamic> messageData, bool isMe, ThemeProvider themeProvider) {
    // Format the time from createdAt or timestamp
    String formatTime(dynamic timeValue) {
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
        final messageDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

        if (messageDate == today) {
          // Today: show time only
          return DateFormat('h:mm a').format(dateTime);
        } else if (messageDate == today.subtract(Duration(days: 1))) {
          // Yesterday
          return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
        } else {
          // Other days: show date and time
          return DateFormat('MMM d, h:mm a').format(dateTime);
        }
      } catch (e) {
        return '';
      }
    }

    final timeString =
    formatTime(messageData["createdAt"] ?? messageData["timestamp"]);
    final hasReply = messageData["replyTo"] != null;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(isMe ? (1 - value) * 50 : (value - 1) * 50, 0),
          child: Opacity(
            opacity: value,
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                  margin: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                  child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                      // Show sender name only for other people's messages
                      if (!isMe)
                  Container(
              margin: EdgeInsets.only(left: 12, right: 12, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getAvatarColor(messageData["senderName"] ?? "Unknown"),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    messageData["senderName"] ?? "Unknown User",
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Message bubble with enhanced styling and reply functionality
            GestureDetector(
              onLongPress: () {
                // Don't allow replying to own messages
                if (!isMe) {
                  _replyToMessage(
                    messageData["key"] ?? "",
                    messageData["message"] ?? "",
                    messageData["senderName"] ?? "Unknown User",
                  );
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1976D2),
                      Color(0xFF2196F3),
                    ],
                  )
                      : null,
                  color: isMe
                      ? null
                      : (themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[100]),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: isMe ? Radius.circular(18) : Radius.circular(3),
                    bottomRight: isMe ? Radius.circular(3) : Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode
                          ? Colors.black26
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: !isMe && !themeProvider.isDarkMode
                      ? Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Reply indicator (if this message is a reply)
                    if (hasReply) ...[
                      Container(
                        padding: EdgeInsets.all(6),
                        margin: EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: (isMe
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border(
                            left: BorderSide(
                              color: isMe
                                  ? Colors.white
                                  : const Color.fromARGB(255, 4, 204, 240),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageData["replyToSender"] ?? "Unknown User",
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : const Color.fromARGB(255, 4, 204, 240),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              messageData["replyToMessage"] ?? "",
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white70
                                    : (themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Main message text
                    Text(
                      messageData["message"],
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : (themeProvider.isDarkMode ? Colors.white : Colors.black87),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),

                    // Timestamp and reply button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (timeString.isNotEmpty) ...[
                          Text(
                            timeString,
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white70
                                  : (themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              fontSize: 11,
                            ),
                          ),
                        ],

                        // Reply button (only for other people's messages)
                        if (!isMe) ...[
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _replyToMessage(
                                messageData["key"] ?? "",
                                messageData["message"] ?? "",
                                messageData["senderName"] ?? "Unknown User",
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.reply,
                                size: 14,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],),
        ),),
            ),);},
    );
  }

  /// Generate consistent color for user avatars
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.indigo[400]!,
      Colors.pink[400]!,
    ];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
        // Enhanced App bar
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: themeProvider.isDarkMode
              ? Colors.grey[800]
              : Colors.white,
          title: Column(
            children: [
              Text(
                "Discussion Forum",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Share your thoughts",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode
                    ? [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                      ]
                    : [
                        Colors.white,
                        Color(0xFFF8F9FA),
                      ],
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    themeProvider.isDarkMode
                        ? Colors.grey[600]!
                        : Colors.grey[300]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            const EnhancedAnimatedBackground(), // Enhanced animated background

            // Show terms dialog or main content
            if (_showTermsDialog)
              _buildTermsDialog(themeProvider)
            else if (_hasAgreedToTerms)
              Column(
                children: [
                  // Disclaimer banner
                  if (_showDisclaimer) _buildDisclaimerBanner(themeProvider),

// Real-time message list with enhanced styling and reply functionality
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[900]
                            : Color(0xFFF8F9FA),
                      ),
                      child: StreamBuilder(
                        stream: _messagesRef.orderByChild("timestamp").onValue,
                        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data?.snapshot.value == null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: themeProvider.isDarkMode
                                              ? Colors.black26
                                              : Colors.grey.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.forum_outlined,
                                      size: 48,
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "No messages yet!",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Be the first to start the conversation",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Convert snapshot to list of messages
                          Map<dynamic, dynamic> messagesMap = snapshot
                              .data!.snapshot.value as Map<dynamic, dynamic>;

                          List<Map<String, dynamic>> messagesList = messagesMap
                              .entries
                              .map((e) => {
                            "key": e.key,
                            ...Map<String, dynamic>.from(e.value)
                          })
                              .toList();

                          // Sort by timestamp (ascending)
                          messagesList.sort(
                                  (a, b) => a["timestamp"].compareTo(b["timestamp"]));

                          return ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            itemCount: messagesList.length,
                            itemBuilder: (context, index) {
                              final message = messagesList[index];
                              bool isMe = message["senderId"] == userId;
                              return _buildMessage(
                                  message, isMe, themeProvider); // Render message with reply functionality
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Reply indicator
                  _buildReplyIndicator(themeProvider),

                  // Enhanced message input field & send button with reply functionality
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[800]
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.isDarkMode
                              ? Colors.black26
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          // Enhanced text input field with reply functionality
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[700]
                                    : Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _isTyping
                                      ? Color(0xFF2196F3)
                                      : (themeProvider.isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!),
                                  width: _isTyping ? 2 : 1,
                                ),
                                boxShadow: _isTyping
                                    ? [
                                  BoxShadow(
                                    color: Color(0xFF2196F3).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                                    : null,
                              ),
                              child: TextField(
                                controller: _messageController,
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: null,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  hintText: _isReplying
                                      ? "Reply to ${_replyingToSender}..."
                                      : "Type your message...",
                                  hintStyle: TextStyle(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(left: 8, right: 4),
                                    child: Icon(
                                      _isReplying ? Icons.reply : Icons.chat_bubble_outline,
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),

                          // Enhanced send button
                          AnimatedBuilder(
                            animation: _sendButtonScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _sendButtonScaleAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: _isTyping
                                        ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1976D2),
                                        Color(0xFF2196F3),
                                      ],
                                    )
                                        : null,
                                    color: !_isTyping
                                        ? (themeProvider.isDarkMode
                                        ? Colors.grey[600]
                                        : Colors.grey[400])
                                        : null,
                                    shape: BoxShape.circle,
                                    boxShadow: _isTyping
                                        ? [
                                      BoxShadow(
                                        color: Color(0xFF2196F3).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(28),
                                      onTap: _isTyping ? _sendMessage : null,
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _isTyping ? Icons.send_rounded : Icons.send_outlined,
                                          color: Colors.white,
                                          size: _isTyping ? 24 : 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class EnhancedAnimatedBackground extends StatefulWidget {
  const EnhancedAnimatedBackground({super.key});

  @override
  State<EnhancedAnimatedBackground> createState() => _EnhancedAnimatedBackgroundState();
}

class _EnhancedAnimatedBackgroundState extends State<EnhancedAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int bubbleCount = 25;
  late List<_EnhancedBubble> bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 25)
    )..repeat();

    final random = Random();
    bubbles = List.generate(bubbleCount, (index) {
      final size = random.nextDouble() * 25 + 8;
      return _EnhancedBubble(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: size,
        speed: random.nextDouble() * 0.15 + 0.03,
        dx: (random.nextDouble() - 0.5) * 0.001,
        opacity: random.nextDouble() * 0.15 + 0.05,
        color: Colors.blue.withOpacity(0.1),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _EnhancedBubblePainter(bubbles, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _EnhancedBubble {
  double x, y, radius, speed, dx, opacity;
  Color color;
  _EnhancedBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.dx,
    required this.opacity,
    required this.color,
  });
}

class _EnhancedBubblePainter extends CustomPainter {
  final List<_EnhancedBubble> bubbles;
  final double progress;
  _EnhancedBubblePainter(this.bubbles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final double dy = (bubble.y + progress * bubble.speed) % 1.2;
      final double dx = (bubble.x + progress * bubble.dx) % 1.0;
      final Offset center = Offset(dx * size.width, dy * size.height);

      // Create gradient paint for more appealing bubbles
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [
            bubble.color.withOpacity(bubble.opacity * 0.8),
            bubble.color.withOpacity(bubble.opacity * 0.2),
            Colors.transparent,
          ],
          stops: [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: bubble.radius));

      canvas.drawCircle(center, bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
