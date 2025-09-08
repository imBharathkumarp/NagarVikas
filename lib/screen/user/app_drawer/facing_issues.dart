import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/theme_provider.dart';

class FacingIssuesPage extends StatelessWidget {
  const FacingIssuesPage({super.key});

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
                  ? [Colors.grey[800]!, Colors.grey[800]!]
                  : [
                      const Color.fromARGB(255, 21, 172, 241),
                      const Color.fromARGB(255, 21, 172, 241)
                    ],
            ),
          ),
          child: Column(
            children: [
              // Custom App Bar - Pass context here
              _buildCustomAppBar(context, themeProvider),

              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[900]
                        : const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _buildHeaderSection(themeProvider),

                        const SizedBox(height: 32),

                        // Common Issues Section
                        _buildSectionCard(
                          context, // Pass context here too
                          themeProvider,
                          'Common Issues',
                          Icons.error_outline,
                          Colors.red,
                          [
                            _buildIssueTile(
                              context, // And here
                              themeProvider,
                              'App not opening',
                              'If the app is not opening, try restarting your phone or reinstalling the app. Ensure you have a stable internet connection.',
                              Icons.phone_android,
                              Colors.orange,
                            ),
                            _buildIssueTile(
                              context,
                              themeProvider,
                              'Login issues',
                              'If you\'re facing issues with logging in, make sure your internet connection is stable and you are using the correct login credentials. If you forgot your password, use the "Forgot Password" option.',
                              Icons.login,
                              Colors.blue,
                            ),
                            _buildIssueTile(
                              context,
                              themeProvider,
                              'Error in submitting complaint',
                              'If the complaint submission fails, please check your internet connection and ensure all required fields are filled. Try restarting the app and submitting again.',
                              Icons.error,
                              Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Troubleshooting Steps Section
                        _buildSectionCard(
                          context,
                          themeProvider,
                          'Troubleshooting Steps',
                          Icons.build_circle_outlined,
                          Colors.green,
                          [
                            _buildStepTile(
                              themeProvider,
                              'Step 1: Restart the app',
                              'Close the app completely and reopen it. This can resolve most of the temporary issues.',
                              '1',
                              Colors.blue,
                            ),
                            _buildStepTile(
                              themeProvider,
                              'Step 2: Check your internet connection',
                              'Ensure you are connected to a stable internet connection (WiFi or mobile data) to avoid connectivity-related issues.',
                              '2',
                              Colors.green,
                            ),
                            _buildStepTile(
                              themeProvider,
                              'Step 3: Clear app cache',
                              'Sometimes clearing the app\'s cache can solve performance issues. Go to your phone\'s settings, find the app, and clear the cache.',
                              '3',
                              Colors.orange,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Contact Support Section
                        _buildContactCard(themeProvider),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Add BuildContext parameter here
  Widget _buildCustomAppBar(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 46, 20, 16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? Colors.grey[800]
            : const Color.fromARGB(255, 21, 172, 241),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey[700]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Facing Issues?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey[700]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.help_outline,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
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

  Widget _buildHeaderSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.support_agent,
              color: Colors.blue,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find solutions to common problems and troubleshooting steps',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add BuildContext parameter here
  Widget _buildSectionCard(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    IconData icon,
    Color iconColor,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Add BuildContext parameter here
  Widget _buildIssueTile(
    BuildContext context,
    ThemeProvider themeProvider,
    String issue,
    String solution,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          title: Text(
            issue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          iconColor: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          collapsedIconColor:
              themeProvider.isDarkMode ? Colors.white : Colors.black87,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    themeProvider.isDarkMode ? Colors.grey[600] : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                solution,
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[300]
                      : Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTile(
    ThemeProvider themeProvider,
    String step,
    String description,
    String number,
    Color numberColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: numberColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: numberColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: numberColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[300]
                        : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode
              ? [Colors.teal[700]!, Colors.teal[600]!]
              : [Colors.blue[600]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.teal.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Open contact support page (or email)
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Still Need Help?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact our support team for personalized assistance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
