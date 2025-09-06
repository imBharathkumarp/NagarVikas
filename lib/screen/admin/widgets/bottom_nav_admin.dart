import 'package:flutter/material.dart';
import 'package:nagarvikas/screen/admin/admin_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nagarvikas/theme/theme_provider.dart';
import '../analytics_dashboard.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const MainNavigationWrapper({
    super.key,
    this.initialIndex = 0, // Analytics Dashboard is the default (index 0)
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _selectedIndex;
  late PageController _pageController;

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    const AdminDashboard(),
    const AnalyticsDashboard(),
  ];

  // Bottom navigation items
  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode
                      ? Colors.black26
                      : Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              items: _bottomNavItems,
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.teal,
              unselectedItemColor: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: themeProvider.isDarkMode
                  ? const Color(0xFF1F1F1F)
                  : Colors.white,
              elevation: 0,
              selectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
              selectedFontSize: 12,
              unselectedFontSize: 11,
            ),
          ),
        );
      },
    );
  }
}
