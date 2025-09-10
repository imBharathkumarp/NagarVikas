// 📦 Required packages and internal imports
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nagarvikas/screen/user/issues/issue_selection.dart';
import 'package:nagarvikas/screen/auth/register_screen.dart';
import 'package:nagarvikas/screen/admin/admin_dashboard.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../service/local_status_storage.dart';
import '../../service/notification_service.dart';
import '../../theme/theme_provider.dart';
import '../admin/widgets/bottom_nav_admin.dart';
import '../user/widgets/bottom_nav_bar.dart';

// 🧩 Stateful widget for login page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

// 🧠 Login page logic and UI state
class LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 📝 Controllers for email and password input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // ⏳ Loading state to show progress indicator
  bool isLoading = false;

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
          parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  /// Handles user authentication and redirects based on role (admin or regular user)
  Future<void> _loginUser() async {
    // Button press animation
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    setState(() {
      isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(msg: "Please enter both email and password");
        setState(() => isLoading = false);
        return;
      }

      // 🔓 Firebase email/password login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // ✅ Check if email is verified
      if (user != null && !user.emailVerified) {
        Fluttertoast.showToast(
          msg: "You need to verify your email before logging in.\n"
              "Please check your Inbox/Spam folder.",
          toastLength: Toast.LENGTH_LONG, // For longer duration
          timeInSecForIosWeb: 3, // Works on iOS/Web
          gravity: ToastGravity.BOTTOM, // Position
          backgroundColor:
              const Color.fromARGB(255, 4, 4, 4), // Optional styling
          textColor: Colors.white, // Optional styling
          fontSize: 14.0, // Optional
        );
        await _auth.signOut();
        setState(() => isLoading = false);
        return;
      }

      Fluttertoast.showToast(msg: "Login Successful!");

      // 🛂 If user is an admin (email contains "gov"), show PIN dialog
      if (email.contains("gov")) {
        await Future.delayed(Duration(milliseconds: 3000));
        _showAdminPinDialog(email);
      } else {
        // 👉 Show local notifications if any, then navigate
        final notifications = await LocalStatusStorage.getNotifications();
        if (notifications.isNotEmpty) {
          for (var i = 0; i < notifications.length; i++) {
            final n = notifications[i];
            await NotificationService().showNotification(
              id: i + 100, // avoid collision with other IDs
              title: 'Complaint Status Updated',
              body: n['message'] ?? 'Your complaint status has changed.',
              payload: n['complaint_id'] ?? '',
            );
          }
          await LocalStatusStorage.clearNotifications();
        }
        // 👉 Navigate to issue selection page for regular users
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BottomNavBar()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
          msg: e.message ?? "Login failed. Please try again.");
    } catch (e) {
      Fluttertoast.showToast(msg: "An unexpected error occurred.");
    }

    setState(() {
      isLoading = false;
    });
  }

  // 🔐 Displays PIN prompt for admin verification before accessing dashboard
  void _showAdminPinDialog(String email) {
    TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return AlertDialog(
              backgroundColor:
                  themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Container(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: themeProvider.isDarkMode
                              ? [Colors.teal, Colors.teal[300]!]
                              : [
                                  const Color(0xFF1565C0),
                                  const Color(0xFF42A5F5)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Admin Authentication",
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enter your 4-digit PIN to access the admin dashboard.",
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: "• • • •",
                      hintStyle: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[500]
                            : Colors.grey[400],
                        fontSize: 20,
                        letterSpacing: 8,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[600]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: themeProvider.isDarkMode
                              ? Colors.teal
                              : const Color(0xFF1565C0),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    maxLength: 4,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: themeProvider.isDarkMode
                                ? [Colors.teal, Colors.teal[300]!]
                                : [
                                    const Color(0xFF1565C0),
                                    const Color(0xFF42A5F5)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            if (pinController.text == "2004") {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool("isAdmin", true);

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              final adminNotifications =
                                  await LocalStatusStorage
                                      .getAdminNotifications();
                              if (adminNotifications.isNotEmpty) {
                                for (var i = 0;
                                    i < adminNotifications.length;
                                    i++) {
                                  final n = adminNotifications[i];
                                  await NotificationService().showNotification(
                                    id: i + 500,
                                    title: 'New Complaint Filed',
                                    body: n['message'] ??
                                        'A new complaint has been filed.',
                                    payload: n['complaint_id'] ?? '',
                                  );
                                }
                                await LocalStatusStorage
                                    .clearAdminNotifications();
                              }
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        MainNavigationWrapper()),
                              );
                            } else {
                              Fluttertoast.showToast(
                                  msg: "Incorrect PIN! Access Denied.");
                            }
                          },
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🔑 Forgot password logic using Firebase reset email
  Future<void> _forgotPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your email to reset password.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(msg: "Password reset link sent to $email");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error sending reset email.");
    }
  }

  // 🧱 UI layout and animations
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor:
              isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
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
                    minHeight: screenHeight -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
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
                              "Welcome Back!",
                              style: TextStyle(
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Sign in to continue your civic journey",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Compact Login illustration
                      ZoomIn(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          height: screenHeight * 0.2,
                          width: screenHeight * 0.2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [
                                      Colors.teal.withOpacity(0.2),
                                      Colors.teal.withOpacity(0.1)
                                    ]
                                  : [
                                      const Color(0xFF1565C0).withOpacity(0.1),
                                      const Color(0xFF42A5F5).withOpacity(0.05)
                                    ],
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/login.png",
                              height: screenHeight * 0.15,
                              width: screenHeight * 0.15,
                              fit: BoxFit.contain,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.9)
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Compact Input Fields
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: Column(
                          children: [
                            // Email Field
                            _buildCompactTextField(
                              controller: _emailController,
                              hint: "Email Address",
                              icon: Icons.email_outlined,
                              isDarkMode: isDarkMode,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            _buildCompactTextField(
                              controller: _passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              isDarkMode: isDarkMode,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.teal[300]
                                        : const Color(0xFF1565C0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Compact Login Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 1200),
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDarkMode
                                        ? [Colors.teal, Colors.teal[300]!]
                                        : [
                                            const Color(0xFF1565C0),
                                            const Color(0xFF42A5F5)
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode
                                          ? Colors.teal.withOpacity(0.3)
                                          : const Color(0xFF1565C0)
                                              .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _loginUser,
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login,
                                                color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "Sign In",
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

                      SizedBox(height: screenHeight * 0.02),

                      // Compact Signup Navigation
                      FadeInUp(
                        duration: const Duration(milliseconds: 1300),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const RegisterScreen(),
                                    transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) =>
                                        FadeTransition(
                                            opacity: animation, child: child),
                                    transitionDuration:
                                        const Duration(milliseconds: 500),
                                  ),
                                );
                              },
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.teal[300]
                                      : const Color(0xFF1565C0),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
