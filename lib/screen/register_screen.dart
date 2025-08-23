/// RegisterScreen
/// A stateful widget that handles new user registration using Firebase Authentication.
/// Includes:
/// - Email/password input
/// - Password validation
/// - Email verification
/// - Guest login
/// - Firebase Realtime Database integration
library;

// import necessary Flutter and Firebase packages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nagarvikas/screen/login_page.dart';
import 'package:nagarvikas/screen/issue_selection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';
import '../widgets/bottom_nav_bar.dart';

// Register screen widget
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  // Firebase authentication and realtime database reference
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("users");

  // Text field controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // Animation controllers
  late AnimationController _registerButtonAnimationController;
  late AnimationController _guestButtonAnimationController;
  late Animation<double> _registerButtonScaleAnimation;
  late Animation<double> _guestButtonScaleAnimation;

  // ✅ This enables auto-capitalization and Capitalizes the first letter of each word.

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _registerButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _guestButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _registerButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _registerButtonAnimationController, curve: Curves.easeInOut),
    );
    _guestButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _guestButtonAnimationController, curve: Curves.easeInOut),
    );

    _nameController.addListener(() {
      final text = _nameController.text;
      final capitalized = text
          .split(' ')
          .map((word) =>
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
          .join(' ');

      // Avoid endless loops
      if (text != capitalized) {
        _nameController.value = _nameController.value.copyWith(
          text: capitalized,
          selection: TextSelection.collapsed(offset: capitalized.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _registerButtonAnimationController.dispose();
    _guestButtonAnimationController.dispose();
    super.dispose();
  }

  // Flags for loading and password validation
  bool isLoading = false;
  bool hasUppercase = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;
  bool showPasswordRequirements = false;

  // ✅ Real-time password validation logic
  void _validatePassword(String password) {
    setState(() {
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasMinLength = password.length >= 8;
    });
  }

  // ✅ Handles user registration process
  Future<void> _registerUser() async {
    // Button press animation
    _registerButtonAnimationController.forward().then((_) {
      _registerButtonAnimationController.reverse();
    });

    String password = _passwordController.text.trim();

    // Check if password meets criteria
    if (!hasMinLength || !hasUppercase || !hasSpecialChar) {
      setState(() {
        showPasswordRequirements = true;
      });
      Fluttertoast.showToast(
          msg: "Password does not meet the required criteria.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ✅ Create user using Firebase Authentication
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: password,
      );

      // ✅ Send email verification
      await userCredential.user!.sendEmailVerification();

      // ✅ Save user details in Firebase Realtime Database
      await _dbRef.child(userCredential.user!.uid).set({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
      });

      Fluttertoast.showToast(
          msg:
          "Registration successful! Please verify your email before logging in.");

      await _auth.signOut(); // Sign out the user after registration
      await Future.delayed(Duration(seconds: 2));

      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle various Firebase auth errors
      String errorMessage = "An error occurred. Please try again.";

      if (e.code == 'email-already-in-use') {
        errorMessage = "Email already registered. Please log in.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address. Please enter a valid email.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak. Try a stronger password.";
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "Email/password accounts are disabled.";
      }

      Fluttertoast.showToast(msg: errorMessage);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Signs in the user anonymously and navigates to the issue selection screen.
  Future<void> _continueAsGuest() async {
    // Button press animation
    _guestButtonAnimationController.forward().then((_) {
      _guestButtonAnimationController.reverse();
    });

    try {
      await _auth.signInAnonymously();
      Fluttertoast.showToast(msg: "Signed in as Guest");
      if(mounted){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavBar()),
        );
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  /// Builds the registration UI with animation, input fields,
  /// and buttons for registration and guest login.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [Colors.grey[900]!, Colors.grey[850]!]
                    : [const Color(0xFFF8F9FA), const Color(0xFFFFFFFF)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Compact Welcome Section
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          children: [
                            Text(
                              "Join Our Community",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Create your account to start making a difference",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Compact Registration illustration
                      ZoomIn(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          height: screenHeight * 0.18,
                          width: screenHeight * 0.18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [Colors.teal.withOpacity(0.2), Colors.teal.withOpacity(0.1)]
                                  : [const Color(0xFF1565C0).withOpacity(0.1), const Color(0xFF42A5F5).withOpacity(0.05)],
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/register.png",
                              height: screenHeight * 0.13,
                              width: screenHeight * 0.13,
                              fit: BoxFit.contain,
                              color: isDarkMode ? Colors.white.withOpacity(0.9) : null,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Compact Input Fields
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Column(
                          children: [
                            // Name Field
                            _buildCompactTextField(
                              controller: _nameController,
                              hint: "Full Name",
                              icon: Icons.person_outline,
                              isDarkMode: isDarkMode,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            _buildCompactTextField(
                              controller: _emailController,
                              hint: "Email Address",
                              icon: Icons.email_outlined,
                              isDarkMode: isDarkMode,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            _buildCompactTextField(
                              controller: _passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              isDarkMode: isDarkMode,
                              obscureText: _obscurePassword,
                              onChanged: _validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Password Requirements List
                      if (showPasswordRequirements)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Password Requirements:",
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  buildPasswordValidationItem(
                                      "At least 8 characters", hasMinLength, themeProvider),
                                  buildPasswordValidationItem(
                                      "At least 1 uppercase letter", hasUppercase, themeProvider),
                                  buildPasswordValidationItem(
                                      "At least 1 special character", hasSpecialChar, themeProvider),
                                ],
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: screenHeight * 0.03),

                      // Compact Register Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 1200),
                        child: AnimatedBuilder(
                          animation: _registerButtonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _registerButtonScaleAnimation.value,
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDarkMode
                                        ? [Colors.teal, Colors.teal[300]!]
                                        : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode 
                                          ? Colors.teal.withOpacity(0.3)
                                          : const Color(0xFF1565C0).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _registerUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person_add, color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "Create Account",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Compact Guest Login Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 1400),
                        child: AnimatedBuilder(
                          animation: _guestButtonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _guestButtonScaleAnimation.value,
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDarkMode 
                                        ? Colors.grey[600]! 
                                        : const Color(0xFF1565C0).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode 
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: OutlinedButton(
                                  onPressed: _continueAsGuest,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset("assets/anonymous.png", height: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Continue as Guest",
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : const Color(0xFF1565C0),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Compact Login Navigation
                      FadeInUp(
                        duration: const Duration(milliseconds: 1600),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        const LoginPage(),
                                    transitionsBuilder:
                                        (context, animation, secondaryAnimation, child) =>
                                            FadeTransition(opacity: animation, child: child),
                                    transitionDuration: const Duration(milliseconds: 500),
                                  ),
                                );
                              },
                              child: Text(
                                "Sign In",
                                style: TextStyle(
                                  color: isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.teal : const Color(0xFF1565C0),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Widget to build password requirement item
  Widget buildPasswordValidationItem(String text, bool isValid, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isValid ? Colors.green : (themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400]),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isValid 
                    ? Colors.green 
                    : (themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}