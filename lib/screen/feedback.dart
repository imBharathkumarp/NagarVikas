import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

/// 📝 FeedbackPage
/// Allows users to rate the app, leave written feedback, and optionally provide suggestions.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  FeedbackPageState createState() => FeedbackPageState();
}

class FeedbackPageState extends State<FeedbackPage> with TickerProviderStateMixin {
  // ⭐ User rating value (0.0 to 5.0)
  double _rating = 0.0;

  // 🖊️ Controller for feedback input
  final TextEditingController _feedbackController = TextEditingController();

  // ✅ Checkbox state for suggestions
  bool _suggestions = false;

  // Animation controllers for smooth interactions
  late AnimationController _submitAnimationController;
  late AnimationController _ratingAnimationController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _submitAnimationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _ratingAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Animate FAB entrance
    Future.delayed(Duration(milliseconds: 500), () {
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _submitAnimationController.dispose();
    _ratingAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor: themeProvider.isDarkMode
            ? Colors.grey[800]
            : const Color.fromARGB(255, 21, 172, 241),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: themeProvider.isDarkMode
                  ? [Colors.grey[800]!, Colors.grey[850]!]
                  : [
                      const Color.fromARGB(255, 21, 172, 241), 
                      const Color.fromARGB(255, 15, 140, 200)
                    ],
            ),
          ),
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(context, themeProvider),
              
              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Scrollable content area
                      Expanded(
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header section with emoji and title
                                _buildHeaderSection(themeProvider),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                                // Rating section
                                _buildRatingSection(themeProvider),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                                // Feedback section
                                _buildFeedbackSection(themeProvider),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                                // Suggestions section
                                _buildSuggestionsSection(themeProvider),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Compact fixed submit button at bottom
                      _buildCompactSubmitContainer(themeProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Remove floating action button
        // floatingActionButton: _buildFloatingSubmitButton(themeProvider),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    });
  }

  /// Custom App Bar matching current theme
  Widget _buildCustomAppBar(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 46, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: themeProvider.isDarkMode
              ? [Colors.grey[800]!, Colors.grey[850]!]
              : [
                  const Color.fromARGB(255, 21, 172, 241), 
                  const Color.fromARGB(255, 15, 140, 200)
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Feedback',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                // Add help action
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Header section with welcoming design
  Widget _buildHeaderSection(ThemeProvider themeProvider) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              '💬',
              style: TextStyle(fontSize: 32),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'We value your opinion',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Help us improve by sharing your experience',
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ⭐ Modern rating section
  Widget _buildRatingSection(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your experience',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 24),
          _buildModernRatingBar(themeProvider),
          if (_rating > 0) ...[
            SizedBox(height: 20),
            _buildRatingFeedbackText(themeProvider),
          ],
        ],
      ),
    );
  }

  /// ⭐ Enhanced star rating with animations
  Widget _buildModernRatingBar(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        bool isSelected = _rating > index;
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1.0;
            });
            _ratingAnimationController.forward().then((_) {
              _ratingAnimationController.reverse();
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isSelected 
                  ? LinearGradient(
                      colors: [Colors.amber.withOpacity(0.15), Colors.orange.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isSelected 
                  ? (themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[100])
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? Colors.amber.withOpacity(0.4) 
                    : (themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                width: 1.5,
              ),
            ),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isSelected 
                  ? Colors.amber[600] 
                  : (themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500]),
              size: 28,
            ),
          ),
        );
      }),
    );
  }

  /// 💬 Rating feedback text
  Widget _buildRatingFeedbackText(ThemeProvider themeProvider) {
    String feedbackText = '';
    Color textColor = themeProvider.isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    if (_rating >= 4) {
      feedbackText = 'Awesome! 🎉';
      textColor = Colors.green[600]!;
    } else if (_rating >= 3) {
      feedbackText = 'Good! 👍';
      textColor = Colors.blue[600]!;
    } else if (_rating >= 2) {
      feedbackText = 'Okay 😐';
      textColor = Colors.orange[600]!;
    } else {
      feedbackText = 'We can do better 😔';
      textColor = Colors.red[400]!;
    }

    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _rating > 0 ? 1.0 : 0.0,
      child: Center(
        child: Text(
          feedbackText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// 📝 Modern feedback input section
  Widget _buildFeedbackSection(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us more',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your thoughts, suggestions, or report issues...',
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: themeProvider.isDarkMode 
                      ? Colors.blue[400]! 
                      : const Color.fromARGB(255, 21, 172, 241), 
                  width: 2
                ),
              ),
              contentPadding: EdgeInsets.all(20),
            ),
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Suggestions checkbox section
  Widget _buildSuggestionsSection(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.3,
            child: Checkbox(
              value: _suggestions,
              onChanged: (bool? value) {
                setState(() {
                  _suggestions = value ?? false;
                });
              },
              activeColor: themeProvider.isDarkMode 
                  ? Colors.blue[400] 
                  : const Color.fromARGB(255, 21, 172, 241),
              checkColor: Colors.white,
              side: BorderSide(
                color: themeProvider.isDarkMode ? Colors.grey[500]! : Colors.grey[400]!,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Would you like to give any suggestions?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📤 Compact Submit Container
  Widget _buildCompactSubmitContainer(ThemeProvider themeProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? Colors.grey[900]
            : const Color(0xFFF8F9FA),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTapDown: (_) => _submitAnimationController.forward(),
          onTapUp: (_) => _submitAnimationController.reverse(),
          onTapCancel: () => _submitAnimationController.reverse(),
          onTap: _submitFeedback,
          child: AnimatedBuilder(
            animation: _submitAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 - (_submitAnimationController.value * 0.02),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode
                          ? [Colors.blue[600]!, Colors.blue[500]!]
                          : [
                              const Color.fromARGB(255, 21, 172, 241), 
                              const Color.fromARGB(255, 15, 140, 200)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode
                            ? Colors.blue.withOpacity(0.3)
                            : const Color.fromARGB(255, 21, 172, 241).withOpacity(0.25),
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 🚀 Enhanced feedback submission with modern dialog
  void _submitFeedback() {
    String feedback = _feedbackController.text;
    log('Rating: $_rating');
    log('Feedback: $feedback');
    log('Suggestions: $_suggestions');

    // ✅ Show a modern thank-you dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green[500],
                        size: 48,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Thank You!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Your feedback helps us improve and create a better experience for everyone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context); // Go back to previous screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.isDarkMode 
                              ? Colors.blue[600] 
                              : const Color.fromARGB(255, 21, 172, 241),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}