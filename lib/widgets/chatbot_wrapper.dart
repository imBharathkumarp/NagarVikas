import 'package:flutter/material.dart';

class ChatbotFloatingButton extends StatefulWidget {
  const ChatbotFloatingButton({Key? key}) : super(key: key);

  @override
  State<ChatbotFloatingButton> createState() => _ChatbotFloatingButtonState();
}

class _ChatbotFloatingButtonState extends State<ChatbotFloatingButton> with SingleTickerProviderStateMixin {
  bool _isChatOpen = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openChat() {
    setState(() => _isChatOpen = true);
    _controller.forward();
  }

  void _closeChat() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isChatOpen = false);
    });
  }

  // NEW: Function to open chatbot in full page
  void _openFullPageChat() {
    _closeChat(); // Close the floating dialog first
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatbotFullPage(
          onMinimize: () {
            Navigator.of(context).pop();
            // Delay to allow page transition to complete
            Future.delayed(const Duration(milliseconds: 300), () {
              _openChat();
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            heroTag: "chatbot_fab",
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: _openChat,
          ),
        ),
        if (_isChatOpen)
          Positioned(
            bottom: 165,
            right: 16,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 340,
                  height: 420,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // UPDATED: Made the header clickable to open full page with dynamic sizing
                      GestureDetector(
                        onTap: _openFullPageChat,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 60),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.smart_toy, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Nagar Vikas Assistant",
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // NEW: Added tap hint
                                          Text(
                                            "Tap to expand",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                splashRadius: 20,
                                onPressed: _closeChat,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: const Color(0xFFF6F8FB),
                          child: const ChatbotConversationWidget(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// NEW: Full page chatbot widget with minimize functionality
class ChatbotFullPage extends StatelessWidget {
  final VoidCallback? onMinimize;
  
  const ChatbotFullPage({
    Key? key,
    this.onMinimize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: onMinimize,
          child: Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Nagar Vikas Assistant",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (onMinimize != null)
            IconButton(
              icon: const Icon(Icons.minimize, color: Colors.white),
              onPressed: onMinimize,
              tooltip: 'Minimize to small view',
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showChatOptions(context);
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF6F8FB),
        child: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: ChatbotConversationWidget(),
          ),
        ),
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                // Add clear chat functionality if needed
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & FAQ'),
              onTap: () {
                Navigator.pop(context);
                // Add help functionality if needed
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChatbotConversationWidget extends StatefulWidget {
  const ChatbotConversationWidget({Key? key}) : super(key: key);

  @override
  State<ChatbotConversationWidget> createState() => _ChatbotConversationWidgetState();
}

class _ChatbotConversationWidgetState extends State<ChatbotConversationWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(text: "How can I help you?", isBot: true),
    _ChatMessage(text: "Try: How do I report an issue?", isBot: true),
  ];
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false));
      _isTyping = true;
    });
    _controller.clear();
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(text: getMessage(text), isBot: true));
    });
    
    // Scroll to bottom again after bot response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String getMessage(String input) {
    final lower = input.toLowerCase();
    // FAQ keyword logic
    if (lower.contains('report') || (lower.contains('issue') || lower.contains('complaint'))) {
      return 'To report an issue, go to the Issues section from the main menu and fill out the form with details and photos.';
    } else if (lower.contains('register') || lower.contains('sign up')) {
      return 'To register, tap on the Register button on the home screen and fill in your details.';
    } else if (lower.contains('track') && (lower.contains('complaint') || lower.contains('issue') || lower.contains('status'))) {
      return 'You can track your complaint or issue status in the My Complaints section.';
    } else if (lower.contains('contact') && (lower.contains('support') || lower.contains('help'))) {
      return 'For support, contact us at support@nagarvikas.com or call our helpline at 1800-123-456.';
    } else if (lower.contains('reset') && lower.contains('password')) {
      return 'To reset your password, use the Forgot Password link on the login page.';
    } else if (lower.contains('edit') && (lower.contains('profile') || lower.contains('account'))) {
      return 'To edit your profile, go to the Profile section and tap on Edit.';
    } else if (lower.contains('delete') && lower.contains('account')) {
      return 'To delete your account, please contact support for assistance.';
    } else if ((lower.contains('app') || lower.contains('application')) && lower.contains('update')) {
      return 'To update the app, visit the Play Store or App Store and check for updates.';
    } else if (lower.contains('language')) {
      return 'You can change the app language from the Settings menu.';
    } else if (lower.contains('notification')) {
      return 'Notification preferences can be managed in the Settings > Notifications section.';
    } else if (lower.contains('location') && lower.contains('enable')) {
      return 'To enable location, allow location permissions in your device settings and app permissions.';
    } else if (lower.contains('faq') || lower.contains('help')) {
      return 'Frequently Asked Questions:\n- How do I report an issue?\n- How do I register?\n- How do I track my complaint?\n- How do I contact support?\n- How do I edit my profile?\n- How do I delete my account?\n- How do I update the app?\n- How do I change the language?\n- How do I enable notifications?';
    }
    // Fallback
    return 'Sorry, I didn\'t understand. Please try rephrasing your question or ask about reporting issues, registration, tracking complaints, support, password reset, profile, account, app update, language, or notifications.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isTyping && index == 0) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, 
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Assistant is typing...", 
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final msg = _messages[_messages.length - 1 - (index - (_isTyping ? 1 : 0))];
              return Align(
                alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isBot ? Colors.blue[50] : Colors.blueAccent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isBot ? Colors.black87 : Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Type your message...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  _ChatMessage({required this.text, required this.isBot});
}

// UPDATED CHATBOT WRAPPER - THIS IS THE KEY CHANGE
class ChatbotWrapper extends StatefulWidget {
  final Widget child;
  final bool hideChat;

  const ChatbotWrapper({
    required this.child,
    this.hideChat = false,
    Key? key
  }) : super(key: key);

  @override
  State<ChatbotWrapper> createState() => _ChatbotWrapperState();
}

class _ChatbotWrapperState extends State<ChatbotWrapper> {
  bool _isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DrawerNotification>(
      onNotification: (notification) {
        setState(() {
          _isDrawerOpen = notification.isOpen;
        });
        return true;
      },
      child: Stack(
        children: [
          widget.child,
          // Only show chatbot when hideChat is false AND drawer is not open
          if (!widget.hideChat && !_isDrawerOpen)
            const ChatbotFloatingButton(),
        ],
      ),
    );
  }
}

// Add this custom notification class
class DrawerNotification extends Notification {
  final bool isOpen;
  DrawerNotification(this.isOpen);
}