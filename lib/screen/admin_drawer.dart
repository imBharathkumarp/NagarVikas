// admin_drawer.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'discussion/banned_users_dashboard.dart';
import 'discussion/discussion.dart';
import 'favourites.dart';
import 'login_page.dart';
import 'package:nagarvikas/screen/analytics_dashboard.dart';

class AdminDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteComplaints;
  final Function(Map<String, dynamic>) onRemoveFavorite;

  const AdminDrawer({
    super.key,
    required this.favoriteComplaints,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Drawer(
          backgroundColor:
              themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF00BCD4),
                      Color(0xFF0097A7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.only(top: 50, bottom: 20),
                width: double.infinity,
                child: Column(
                  children: const [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                      ),
                      backgroundColor: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'amritsar.gov@gmail.com',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.analytics, color: Colors.teal),
                title: Text(
                  'Analytics',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AnalyticsDashboard(),
                  ));
                },
              ),
              Divider(
                  thickness: 1,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300]),
              ListTile(
                leading: Icon(Icons.forum, color: Colors.blue),
                title: Text(
                  'Discussion Forum',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const DiscussionForum(isAdmin: true),
                  ));
                },
              ),
              Divider(
                  thickness: 1,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300]),
              ListTile(
                leading: Icon(Icons.block, color: Colors.orange),
                title: Text(
                  'Banned Users',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const BannedUsersDashboard(),
                  ));
                },
              ),
              Divider(
                  thickness: 1,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300]),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: Text(
                  'Favorites',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => FavoritesPage(
                      favoriteComplaints: favoriteComplaints,
                      onRemoveFavorite: onRemoveFavorite,
                    ),
                  ));
                },
              ),
              Divider(
                  thickness: 1,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300]),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) => Dialog(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[850]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.isDarkMode
                                  ? Colors.black.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: themeProvider.isDarkMode
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated logout icon with gradient background
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF8787)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B6B)
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title with improved typography
                            Text(
                              "Logout Confirmation",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),

                            // Description text
                            Text(
                              "Are you sure you want to logout from your admin account? You'll need to sign in again to access the dashboard.",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Action buttons with modern styling
                            Row(
                              children: [
                                // Cancel button
                                Expanded(
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: themeProvider.isDarkMode
                                            ? Colors.grey[600]!
                                            : Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        onTap: () =>
                                            Navigator.of(context).pop(),
                                        child: Center(
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: themeProvider.isDarkMode
                                                  ? Colors.grey[200]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Logout button
                                Expanded(
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF6B6B),
                                          Color(0xFFFF5252)
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF6B6B)
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        onTap: () async {
                                          Navigator.of(context).pop();

                                          // Show loading dialog
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => Dialog(
                                              elevation: 0,
                                              backgroundColor:
                                                  Colors.transparent,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(24),
                                                margin: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 40),
                                                decoration: BoxDecoration(
                                                  color:
                                                      themeProvider.isDarkMode
                                                          ? Colors.grey[850]
                                                          : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const CircularProgressIndicator(
                                                      color:
                                                          Color(0xFF00BCD4),
                                                      strokeWidth: 3,
                                                    ),
                                                    const SizedBox(
                                                        height: 16),
                                                    Text(
                                                      "Signing out...",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: themeProvider
                                                                .isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );

                                          try {
                                            await FirebaseAuth.instance
                                                .signOut();
                                            if (!context.mounted) return;

                                            Navigator.of(context)
                                                .pop(); // Close loading dialog
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const LoginPage()),
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            Navigator.of(context)
                                                .pop(); // Close loading dialog

                                            // Show error dialog
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  AlertDialog(
                                                backgroundColor:
                                                    themeProvider.isDarkMode
                                                        ? Colors.grey[850]
                                                        : Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16),
                                                ),
                                                title: Text(
                                                  "Error",
                                                  style: TextStyle(
                                                    color: themeProvider
                                                            .isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                content: Text(
                                                  "Failed to logout. Please try again.",
                                                  style: TextStyle(
                                                    color: themeProvider
                                                            .isDarkMode
                                                        ? Colors.grey[300]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: const Text(
                                                      "OK",
                                                      style: TextStyle(
                                                          color: Color(
                                                              0xFF00BCD4)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                        child: const Center(
                                          child: Text(
                                            "Logout",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}