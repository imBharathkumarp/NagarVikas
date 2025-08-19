import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

class DiscussionForumState extends State<DiscussionForum> with TickerProviderStateMixin {
  final TextEditingController _messageController =
  TextEditingController(); // 💬 Controls text input
  final DatabaseReference _messagesRef =
  FirebaseDatabase.instance.ref("discussion/"); // 🔗 Firebase DB ref
  final DatabaseReference _usersRef =
  FirebaseDatabase.instance.ref("users/"); // 🔗 Users DB ref
  final ScrollController _scrollController =
  ScrollController(); // 📜 Scroll controller for ListView
  String? userId;
  String? currentUserName;
  bool _showDisclaimer = true;
  bool _hasAgreedToTerms = false;
  bool _showTermsDialog = false;
  late AnimationController _disclaimerController;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid; // 🔑 Get current user ID
    _getCurrentUserName();
    _checkTermsAgreement();

    // Initialize disclaimer animation controller
    _disclaimerController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _disclaimerController.forward();

    // Auto-hide disclaimer after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted && _showDisclaimer) {
        _hideDisclaimer();
      }
    });
  }

  @override
  void dispose() {
    _disclaimerController.dispose();
    super.dispose();
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

  /// 📋 Check if user has agreed to terms and conditions
  void _checkTermsAgreement() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'terms_agreed_${userId ?? 'anonymous'}';
    bool hasAgreed = prefs.getBool(key) ?? false;

    setState(() {
      _hasAgreedToTerms = hasAgreed;
      _showTermsDialog = !hasAgreed;
    });
  }

  /// ✅ Save terms agreement to local storage
  void _agreeToTerms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'terms_agreed_${userId ?? 'anonymous'}';
    await prefs.setBool(key, true);

    setState(() {
      _hasAgreedToTerms = true;
      _showTermsDialog = false;
    });
  }

  /// 📜 Build terms and conditions dialog
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
                          color: const Color.fromARGB(255, 4, 204, 240).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.gavel,
                          size: isSmallScreen ? 32 : 40,
                          color: const Color.fromARGB(255, 4, 204, 240),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 20),

                      // Title
                      Text(
                        "Terms & Community Guidelines",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Terms content - Flexible height
                Flexible(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTermsSection(
                            "📋 Discussion Forum Guidelines",
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
                            "⚖️ Terms of Use",
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
                            "🔒 Privacy & Data",
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
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                                backgroundColor: const Color.fromARGB(255, 4, 204, 240),
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

  /// 📝 Build a terms section with title and bullet points
  Widget _buildTermsSection(String title, List<String> points, ThemeProvider themeProvider, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 4, 204, 240),
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        ...points.map((point) => Padding(
          padding: EdgeInsets.only(left: 8, bottom: isSmallScreen ? 3 : 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "• ",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
              Expanded(
                child: Text(
                  point,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    fontSize: isSmallScreen ? 12 : 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  /// 👤 Get current user's display name
  void _getCurrentUserName() async {
    if (userId != null) {
      try {
        final snapshot = await _usersRef.child(userId!).once();
        if (snapshot.snapshot.value != null) {
          final userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          setState(() {
            currentUserName = userData['name'] ?? userData['displayName'] ?? _getDefaultName();
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

  /// 📤 Sends a message to Firebase Realtime Database
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || currentUserName == null) return;

    _messagesRef.push().set({
      "message": _messageController.text.trim(), // ✏️ Message text
      "senderId": userId, // 👤 Sender ID
      "senderName": currentUserName, // 👤 Sender display name - ADDED THIS
      "timestamp": ServerValue.timestamp, // 🕐 Server-side timestamp
    });

    _messageController.clear(); // 🔄 Clear input
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  /// 🏷️ Builds the disclaimer banner
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
                    const Color.fromARGB(255, 4, 204, 240).withOpacity(0.9),
                    const Color.fromARGB(255, 4, 204, 240).withOpacity(0.7),
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

  /// 🧱 Builds a single message bubble (left or right aligned)
  Widget _buildMessage(Map<String, dynamic> messageData, bool isMe, ThemeProvider themeProvider) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Show sender name only for other people's messages
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(left: 8, right: 8, bottom: 2),
                child: Text(
                  messageData["senderName"] ?? "Unknown User", // Use senderName directly from Firebase
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Message bubble
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.blueAccent
                    : (themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: isMe ? Radius.circular(10) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(10),
                ),
              ),
              child: Text(
                messageData["message"], // 📝 Display message
                style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : (themeProvider.isDarkMode ? Colors.white : Colors.black),
                    fontSize: 18
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor:
        themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        // 🧭 App bar
        appBar: AppBar(
          elevation: 5,
          shadowColor: Colors.black87,
          centerTitle: true,
          title: Text(
              "Discussion Forum",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              )
          ),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        body: Stack(
          children: [
            const AnimatedBackground(), // Animated background with bubbles

            // Show terms dialog or main content
            if (_showTermsDialog)
              _buildTermsDialog(themeProvider)
            else if (_hasAgreedToTerms)
              Column(
                children: [
                  // 🏷️ Disclaimer banner
                  if (_showDisclaimer) _buildDisclaimerBanner(themeProvider),

                  // 🔄 Real-time message list
                  Expanded(
                    child: StreamBuilder(
                      stream: _messagesRef.orderByChild("timestamp").onValue,
                      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                        if (!snapshot.hasData ||
                            snapshot.data?.snapshot.value == null) {
                          return Center(
                              child: Text(
                                "No messages yet!",
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              )); // 👤 Empty state
                        }

                        // 🔄 Convert snapshot to list of messages
                        Map<dynamic, dynamic> messagesMap = snapshot
                            .data!.snapshot.value as Map<dynamic, dynamic>;

                        List<Map<String, dynamic>> messagesList = messagesMap
                            .entries
                            .map((e) => {
                          "key": e.key,
                          ...Map<String, dynamic>.from(e.value)
                        })
                            .toList();

                        // 🕐 Sort by timestamp (ascending)
                        messagesList.sort(
                                (a, b) => a["timestamp"].compareTo(b["timestamp"]));

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: messagesList.length,
                          itemBuilder: (context, index) {
                            final message = messagesList[index];
                            bool isMe = message["senderId"] == userId;
                            return _buildMessage(
                                message, isMe, themeProvider); // 🧱 Render message
                          },
                        );
                      },
                    ),
                  ),

                  // 💬 Message input field & send button
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // ✏️ Text input field
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _messageController,
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  icon: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, left: 18, right: 8, bottom: 8),
                                    child: Icon(
                                        Icons.message,
                                        color: themeProvider.isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey
                                    ),
                                  ),
                                  hintText: "Type a message...",
                                  hintStyle: TextStyle(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none, // Remove default border
                                  ),
                                  contentPadding:
                                  EdgeInsets.symmetric(horizontal: 1),
                                  filled: true,
                                  fillColor: themeProvider.isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),

                        // 🚀 Send button
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0, top: 8, right: 8),
                          child: FloatingActionButton(
                            onPressed: _sendMessage,
                            backgroundColor: const Color.fromARGB(255, 7, 7, 7),
                            child: Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Center(
                child: CircularProgressIndicator(
                  color: const Color.fromARGB(255, 4, 204, 240),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int bubbleCount = 30;
  late List<_Bubble> bubbles;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: Duration(seconds: 20))
      ..repeat();
    final random = Random();
    bubbles = List.generate(bubbleCount, (index) {
      final size = random.nextDouble() * 30 + 10;
      return _Bubble(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: size,
        speed: random.nextDouble() * 0.2 + 0.05,
        dx: (random.nextDouble() - 0.5) * 0.002,
        color: Colors.blue.withOpacity(0.25),
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
        painter: _BubblePainter(bubbles, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Bubble {
  double x, y, radius, speed, dx;
  Color color;
  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.dx,
    required this.color,
  });
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress;
  _BubblePainter(this.bubbles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final double dy = (bubble.y + progress * bubble.speed) % 1.2;
      final double dx = (bubble.x + progress * bubble.dx) % 1.0;
      final Offset center = Offset(dx * size.width, dy * size.height);
      final Paint paint = Paint()..color = bubble.color;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: bubble.radius,
          height: bubble.radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
