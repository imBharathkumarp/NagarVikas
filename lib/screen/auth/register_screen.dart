/// RegisterScreen with Optional Phone OTP Verification
/// A comprehensive registration screen that includes:
/// - Name, email, password, and phone number input
/// - Optional phone number OTP verification using Firebase Auth
/// - Email verification
/// - Password validation
/// - Guest login option
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nagarvikas/screen/auth/login_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../user/widgets/bottom_nav_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("users");

  // Text field controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // State variables
  bool _obscurePassword = true;
  bool isLoading = false;
  bool isPhoneVerifying = false;
  bool isPhoneVerified = false;
  bool showPasswordRequirements = false;
  bool showOtpField = false;

  // NEW: Control whether phone verification is enabled
  static const bool ENABLE_PHONE_VERIFICATION =
      false; // Set to true when you have billing

  // Password validation flags
  bool hasUppercase = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;

  // Phone verification variables
  String verificationId = '';
  int? resendToken;

  // Animation controllers
  late AnimationController _registerButtonAnimationController;
  late AnimationController _guestButtonAnimationController;
  late Animation<double> _registerButtonScaleAnimation;
  late Animation<double> _guestButtonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupNameCapitalization();
  }

  void _initAnimations() {
    _registerButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _guestButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _registerButtonScaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
          parent: _registerButtonAnimationController, curve: Curves.easeInOut),
    );
    _guestButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
          parent: _guestButtonAnimationController, curve: Curves.easeInOut),
    );
  }

  void _setupNameCapitalization() {
    _nameController.addListener(() {
      final text = _nameController.text;
      final capitalized = text
          .split(' ')
          .map((word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
          .join(' ');

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Password validation
  void _validatePassword(String password) {
    setState(() {
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasMinLength = password.length >= 8;
    });
  }

  // Phone number validation
  bool _isValidPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return phone.length == 10 && RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  // Send OTP to phone number
  Future<void> _sendOtp() async {
    if (!ENABLE_PHONE_VERIFICATION) {
      Fluttertoast.showToast(msg: "Phone verification is currently disabled");
      return;
    }

    String phone = _phoneController.text.trim();

    if (!_isValidPhoneNumber(phone)) {
      Fluttertoast.showToast(msg: "Please enter a valid 10-digit phone number");
      return;
    }

    setState(() {
      isPhoneVerifying = true;
    });

    // Add +91 country code for India
    String phoneWithCountryCode = '+91$phone';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneWithCountryCode,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          setState(() {
            isPhoneVerified = true;
            showOtpField = false;
            isPhoneVerifying = false;
          });
          Fluttertoast.showToast(msg: "Phone number verified automatically!");
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            isPhoneVerifying = false;
            showOtpField = false;
          });

          String errorMessage = "Verification failed. Please try again.";
          if (e.code == 'invalid-phone-number') {
            errorMessage = "Invalid phone number format.";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Too many requests. Please try again later.";
          }

          Fluttertoast.showToast(msg: errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            this.resendToken = resendToken;
            showOtpField = true;
            isPhoneVerifying = false;
          });
          Fluttertoast.showToast(msg: "OTP sent to $phoneWithCountryCode");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
      );
    } catch (e) {
      setState(() {
        isPhoneVerifying = false;
        showOtpField = false;
      });
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  // Verify OTP
  Future<void> _verifyOtp() async {
    String otp = _otpController.text.trim();

    if (otp.length != 6) {
      Fluttertoast.showToast(msg: "Please enter a valid 6-digit OTP");
      return;
    }

    setState(() {
      isPhoneVerifying = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Verify the credential without signing in
      await _auth.signInWithCredential(credential);
      await _auth.signOut(); // Sign out immediately after verification

      setState(() {
        isPhoneVerified = true;
        showOtpField = false;
        isPhoneVerifying = false;
      });

      Fluttertoast.showToast(msg: "Phone number verified successfully!");
    } catch (e) {
      setState(() {
        isPhoneVerifying = false;
      });
      Fluttertoast.showToast(msg: "Invalid OTP. Please try again.");
    }
  }

  // Resend OTP
  Future<void> _resendOtp() async {
    await _sendOtp();
  }

  // Register user
  Future<void> _registerUser() async {
    _registerButtonAnimationController.forward().then((_) {
      _registerButtonAnimationController.reverse();
    });

    // Validation checks
    if (_nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your full name");
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your email address");
      return;
    }

    // MODIFIED: Only validate phone number if verification is enabled AND phone is provided
    if (ENABLE_PHONE_VERIFICATION && _phoneController.text.trim().isNotEmpty) {
      if (!_isValidPhoneNumber(_phoneController.text.trim())) {
        Fluttertoast.showToast(
            msg: "Please enter a valid phone number or leave it empty");
        return;
      }

      if (!isPhoneVerified) {
        Fluttertoast.showToast(msg: "Please verify your phone number first");
        return;
      }
    }

    String password = _passwordController.text.trim();
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
      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: password,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // MODIFIED: Save user details with optional phone verification status
      Map<String, dynamic> userData = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "registrationDate": DateTime.now().toIso8601String(),
      };

      // Add phone data only if provided
      if (_phoneController.text.trim().isNotEmpty) {
        userData["phone"] = _phoneController.text.trim();
        userData["phoneVerified"] =
            ENABLE_PHONE_VERIFICATION ? isPhoneVerified : false;
      }

      await _dbRef.child(userCredential.user!.uid).set(userData);

      String successMessage =
          "Registration successful! Please verify your email before logging in.";
      if (!ENABLE_PHONE_VERIFICATION &&
          _phoneController.text.trim().isNotEmpty) {
        successMessage += " Phone verification is currently disabled.";
      }

      Fluttertoast.showToast(
        msg: successMessage,
        toastLength: Toast.LENGTH_LONG,
      );

      await _auth.signOut();
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
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

  // Continue as guest
  Future<void> _continueAsGuest() async {
    _guestButtonAnimationController.forward().then((_) {
      _guestButtonAnimationController.reverse();
    });

    try {
      await _auth.signInAnonymously();
      Fluttertoast.showToast(msg: "Signed in as Guest");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

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
                      // Welcome Section
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
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Create your account to start making a difference",
                              textAlign: TextAlign.center,
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

                      SizedBox(height: screenHeight * 0.03),

                      // Registration illustration
                      ZoomIn(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          height: screenHeight * 0.15,
                          width: screenHeight * 0.15,
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
                              "assets/register.png",
                              height: screenHeight * 0.1,
                              width: screenHeight * 0.1,
                              fit: BoxFit.contain,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.9)
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Input Fields
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

                            // Phone Field with OTP verification
                            _buildPhoneField(isDarkMode),

                            // OTP Field (shown only after OTP is sent)
                            if (showOtpField && ENABLE_PHONE_VERIFICATION) ...[
                              const SizedBox(height: 16),
                              _buildOtpField(isDarkMode),
                            ],

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
                          ],
                        ),
                      ),

                      // Password Requirements
                      if (showPasswordRequirements)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildPasswordRequirements(themeProvider),
                        ),

                      SizedBox(height: screenHeight * 0.03),

                      // Register Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 1200),
                        child: _buildRegisterButton(isDarkMode),
                      ),

                      const SizedBox(height: 16),

                      // Guest Login Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 1400),
                        child: _buildGuestButton(isDarkMode),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Login Navigation
                      FadeInUp(
                        duration: const Duration(milliseconds: 1600),
                        child: _buildLoginNavigation(isDarkMode),
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

  Widget _buildPhoneField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _phoneController,
                hint: "Phone Number (10 digits) - Optional",
                icon: Icons.phone_outlined,
                isDarkMode: isDarkMode,
                keyboardType: TextInputType.phone,
                enabled: !isPhoneVerified,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isPhoneVerified
                    ? Colors.green.withOpacity(0.1)
                    : ENABLE_PHONE_VERIFICATION
                        ? (isDarkMode
                            ? Colors.teal.withOpacity(0.1)
                            : const Color(0xFF1565C0).withOpacity(0.1))
                        : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                border: Border.all(
                  color: isPhoneVerified
                      ? Colors.green
                      : ENABLE_PHONE_VERIFICATION
                          ? (isDarkMode ? Colors.teal : const Color(0xFF1565C0))
                          : (isDarkMode
                              ? Colors.grey[600]!
                              : Colors.grey[400]!),
                ),
              ),
              child: MaterialButton(
                onPressed: !ENABLE_PHONE_VERIFICATION
                    ? null
                    : (isPhoneVerified
                        ? null
                        : (isPhoneVerifying ? null : _sendOtp)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: isPhoneVerifying && ENABLE_PHONE_VERIFICATION
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.teal : const Color(0xFF1565C0),
                          ),
                        ),
                      )
                    : isPhoneVerified && ENABLE_PHONE_VERIFICATION
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 24)
                        : Text(
                            ENABLE_PHONE_VERIFICATION ? "Send OTP" : "Disabled",
                            style: TextStyle(
                              color: ENABLE_PHONE_VERIFICATION
                                  ? (isDarkMode
                                      ? Colors.teal
                                      : const Color(0xFF1565C0))
                                  : (isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[500]),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
              ),
            ),
          ],
        ),
        if (!ENABLE_PHONE_VERIFICATION)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Phone verification is currently disabled. You can still add your phone number.",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOtpField(bool isDarkMode) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactTextField(
                controller: _otpController,
                hint: "Enter 6-digit OTP",
                icon: Icons.security_outlined,
                isDarkMode: isDarkMode,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.green),
              ),
              child: MaterialButton(
                onPressed: isPhoneVerifying ? null : _verifyOtp,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: isPhoneVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : const Text(
                        "Verify",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive OTP? ",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: isPhoneVerifying ? null : _resendOtp,
              child: Text(
                "Resend",
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(ThemeProvider themeProvider) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Password Requirements:",
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.grey[300]
                    : Colors.grey[700],
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
    );
  }

  Widget _buildRegisterButton(bool isDarkMode) {
    return AnimatedBuilder(
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
                    borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildGuestButton(bool isDarkMode) {
    return AnimatedBuilder(
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
                    borderRadius: BorderRadius.circular(12)),
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
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF1565C0),
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
    );
  }

  Widget _buildLoginNavigation(bool isDarkMode) {
    return Row(
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
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      enabled: enabled,
      style: TextStyle(
        color: enabled
            ? (isDarkMode ? Colors.white : Colors.black87)
            : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: enabled
              ? (isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0))
              : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
        ),
        filled: true,
        fillColor: enabled
            ? (isDarkMode ? Colors.grey[800] : Colors.white)
            : (isDarkMode ? Colors.grey[850] : Colors.grey[50]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
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

  Widget buildPasswordValidationItem(
      String text, bool isValid, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isValid
                ? Colors.green
                : (themeProvider.isDarkMode
                    ? Colors.grey[500]
                    : Colors.grey[400]),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isValid
                    ? Colors.green
                    : (themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600]),
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
