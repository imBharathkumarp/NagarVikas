// 📦 Importing necessary packages and screens
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:nagarvikas/service/connectivity_service.dart';
import 'package:nagarvikas/widgets/bottom_nav_bar.dart';
import 'package:nagarvikas/widgets/exit_confirmation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nagarvikas/screen/register_screen.dart';
import 'package:nagarvikas/screen/admin_dashboard.dart';
import 'package:nagarvikas/screen/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:nagarvikas/screen/logo.dart';
import 'dart:async';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:nagarvikas/theme/theme_provider.dart';

// 🔧 Background message handler for Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("Handling a background message: ${message.messageId}");
}

void main() async {
  // ✅ Ensures Flutter is initialized before any Firebase code
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ OneSignal push notification setup
  OneSignal.initialize("70614e6d-8bbf-4ac1-8f6d-b261a128059c");
  OneSignal.Notifications.requestPermission(true);

  // ✅ Set up notification opened handler
  OneSignal.Notifications.addClickListener((event) {
    log("Notification Clicked: ${event.notification.body}");
  });

  // ✅ Firebase initialization for Web and Mobile
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCjaGsLVhHmVGva75FLj6PiCv_Z74wGap4",
        authDomain: "nagarvikas-a1d4f.firebaseapp.com",
        projectId: "nagarvikas-a1d4f",
        storageBucket: "nagarvikas-a1d4f.firebasestorage.app",
        messagingSenderId: "847955234719",
        appId: "1:847955234719:web:ac2b6da7a3a0715adfb7aa",
        measurementId: "G-ZZMV642TW3",
      ),
    );
  } else {
    await Firebase.initializeApp(); // This might fail if no default options
  }
  // ✅ Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Run the app
  await ConnectivityService().initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// ✅ Main Application Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'nagarvikas',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(),
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: ExitConfirmationWrapper(
        child: ConnectivityOverlay(child: const AuthCheckScreen()),
      ),
    );
  }
}

// ✅ Auth Check Screen (Decides User/Admin Navigation)
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  AuthCheckScreenState createState() => AuthCheckScreenState();
}

// ✅ State for Auth Check Screen
class AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _showSplash = true;
  firebase_auth.User? user;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkLastLogin();

    // ✅ Listen for authentication state changes like(login/logout changes)
    firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth.User? newUser) {
      setState(() {
        user = newUser;
      });
    });

    // ✅ Splash screen timer
    Timer(const Duration(seconds: 11), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  // ✅ Check Last Login (Fix for User Going to Admin Dashboard)
  Future<void> _checkLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool? storedIsAdmin = prefs.getBool('isAdmin');

    setState(() {
      isAdmin = storedIsAdmin ?? false;
    });
  }

  // ✅ Build Method (Decides Which Screen to Show)
  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    // ✅ Redirect Based on Last Login
    if (user == null) {
      return const WelcomeScreen();
    } else {
      if (isAdmin && user!.email?.contains("gov") == true) {
        return AdminDashboard();
      } else {
        return const BottomNavBar();
      }
    }
  }
}

// ✅ Admin Login Function (Stores Admin Status)
Future<void> handleAdminLogin(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isAdmin', true);
  if (context.mounted) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => AdminDashboard()));
  }
}

// ✅ Logout Function (Clears Admin Status & Redirects to Login)
Future<void> handleLogout(BuildContext context) async {
  // Clear stored admin status
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('isAdmin'); // ✅ Clear admin status
  await firebase_auth.FirebaseAuth.instance.signOut();
  if (context.mounted) {
    Navigator.pushReplacement(
        // ✅ Redirect to Login Page
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()));
  } // ✅ Fix: Use const for LoginPage to avoid unnecessary rebuilds
}

/// SplashScreen - displays an animated logo on app launch
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override // Build Method for Splash Screen
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 252),
      body: Center(
        child: LogoWidget(),
      ),
    );
  }
}

// ✅ Welcome Screen shown before registration
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
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
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _onGetStartedPressed() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });
    
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RegisterScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ).then((_) => setState(() => _isLoading = false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF0A0E1A) 
          : const Color(0xFFF8FAFC),
      drawer: _buildModernDrawer(context, isDarkMode, screenWidth, screenHeight),

      // Main Body
      body: Stack(
        children: [
          // Enhanced Background with gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A0E1A),
                        Color(0xFF1A1F2E),
                        Color(0xFF0A0E1A),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF8FAFC),
                        Color(0xFFEEF2FF),
                        Color(0xFFF8FAFC),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
            ),
          ),

          // Floating orb backgrounds with blur effect
          if (!isDarkMode) ...[
            Positioned(
              top: screenHeight * 0.05,
              right: -screenWidth * 0.15,
              child: Container(
                width: screenWidth * 0.6,
                height: screenWidth * 0.6,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withOpacity(0.15),
                      Colors.purple.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.15,
              left: -screenWidth * 0.15,
              child: Container(
                width: screenWidth * 0.55,
                height: screenWidth * 0.55,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withOpacity(0.12),
                      Colors.pink.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ] else ...[
            Positioned(
              top: screenHeight * 0.08,
              right: -screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.7,
                height: screenWidth * 0.7,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.teal.withOpacity(0.15),
                      Colors.cyan.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.2,
              left: -screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.6,
                height: screenWidth * 0.6,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.indigo.withOpacity(0.12),
                      Colors.purple.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],

          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.07, vertical: screenHeight * 0.08),
            child: Column(
              children: [
                // Enhanced Logo Container with hero animation
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Stack(
                    children: [
                      // Floating background circle
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: isDarkMode
                                  ? [
                                      Colors.teal.withOpacity(0.1),
                                      Colors.cyan.withOpacity(0.05),
                                      Colors.transparent,
                                    ]
                                  : [
                                      Colors.purple.withOpacity(0.08),
                                      Colors.blue.withOpacity(0.04),
                                      Colors.transparent,
                                    ],
                            ),
                          ),
                        ),
                      ),
                      // Main container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(40),
                          border: isDarkMode
                              ? Border.all(color: Colors.white.withOpacity(0.15), width: 1.5)
                              : Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                          boxShadow: isDarkMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 20),
                                  ),
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.15),
                                    blurRadius: 60,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 0),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 40,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 20),
                                  ),
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.1),
                                    blurRadius: 80,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            // Icon with floating effect
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.teal.withOpacity(0.15)
                                    : Colors.purple.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.teal.withOpacity(0.3)
                                      : Colors.purple.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Image.asset(
                                'assets/mobileprofile.png',
                                width: screenWidth * 0.45,
                                height: screenHeight * 0.18,
                                fit: BoxFit.contain,
                                color: isDarkMode ? Colors.white.withOpacity(0.95) : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Welcome text
                            Text(
                              "Welcome!",
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode 
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.grey[800],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Let's make your community better",
                              style: TextStyle(
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode 
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Enhanced Text Container with glassmorphism effect
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.8),
                        width: 1.5,
                      ),
                      boxShadow: isDarkMode
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 35,
                                spreadRadius: 0,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.1),
                                blurRadius: 60,
                                spreadRadius: 0,
                                offset: const Offset(0, 0),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 35,
                                spreadRadius: 0,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.08),
                                blurRadius: 60,
                                spreadRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isDarkMode
                                ? [Colors.white, Colors.grey[300]!]
                                : [Colors.deepPurple, Colors.purple],
                          ).createShader(bounds),
                          child: Text(
                            "Facing Civic Issues?",
                            style: TextStyle(
                              fontSize: screenWidth * 0.075,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Register your complaint now and get it resolved quickly with our efficient system. Your voice matters in building a better community.",
                          style: TextStyle(
                            fontSize: screenWidth * 0.043,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Enhanced Bottom CTA with modern styling
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08, 
            vertical: 20
          ),
          child: AnimatedBuilder(
            animation: _buttonScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _buttonScaleAnimation.value,
                child: Container(
                  height: screenHeight * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: isDarkMode
                        ? const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode 
                            ? Colors.teal.withOpacity(0.3)
                            : Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onGetStartedPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rocket_launch_rounded, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                "Get Started",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.046,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
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
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context, bool isDarkMode, double screenWidth, double screenHeight) {
    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1A1F2E) : Colors.white,
      child: Column(
        children: [
          // Enhanced Header with gradient
          Container(
            height: screenHeight * 0.22,
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: screenWidth * 0.08,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.068,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Customize your experience',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Enhanced Dark Mode Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Container(
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200]!,
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(
                    "Dark Mode",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.042,
                    ),
                  ),
                  subtitle: Text(
                    "Toggle app appearance",
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.teal.withOpacity(0.2)
                          : Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.dark_mode_rounded,
                      color: isDarkMode ? Colors.teal[300] : Colors.deepPurple,
                      size: 22,
                    ),
                  ),
                  activeColor: isDarkMode ? Colors.teal : Colors.deepPurple,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Enhanced Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.red.withOpacity(0.1)
                    : Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red[600],
                    size: 22,
                  ),
                ),
                title: Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.042,
                  ),
                ),
                subtitle: Text(
                  "Sign out of your account",
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                onTap: () => handleLogout(context),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}