import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/theme_provider.dart';

class ReportIssueService {
  static const String _supportEmail = "prateekch4653@gmail.com";

  static void showReportIssueDialog(BuildContext context, ThemeProvider themeProvider) {
    final TextEditingController issueController = TextEditingController();
    String selectedIssueType = 'Bug Report';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor:
          themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.report_problem, color: Color(0xFFE91E63)),
              const SizedBox(width: 12),
              Text(
                "Report Issue",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Issue Type",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                    themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedIssueType,
                  dropdownColor: themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.white,
                  style: TextStyle(
                    color:
                    themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey,
                      ),
                    ),
                  ),
                  items: [
                    'Bug Report',
                    'Feature Request',
                    'Login Issue',
                    'App Crash',
                    'Performance Issue',
                    'Other'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedIssueType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  "Describe the Issue",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                    themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: issueController,
                  maxLines: 4,
                  style: TextStyle(
                    color:
                    themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Please describe the issue in detail...',
                    hintStyle: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (issueController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _sendReportEmail(
                      context,
                      selectedIssueType,
                      issueController.text.trim()
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please describe the issue'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63)),
              child: const Text("Submit Report",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _sendReportEmail(
      BuildContext context,
      String issueType,
      String description
      ) async {
    final String subject = Uri.encodeComponent('App Issue Report: $issueType');
    final String body = Uri.encodeComponent(
        'Issue Type: $issueType\n\n'
            'Description:\n$description\n\n'
            '--- Additional Info ---\n'
            'App: NagarVikas\n'
            'Platform: Mobile\n'
            'Timestamp: ${DateTime.now().toIso8601String()}'
    );

    final Uri emailUri = Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening email app to send report...'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open email app. Please send manually to $_supportEmail'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
