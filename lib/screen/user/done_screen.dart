import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

import '../../theme/theme_provider.dart';

class DoneScreen extends StatelessWidget {
  final bool isAnonymous;

  const DoneScreen({Key? key, required this.isAnonymous}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    OneSignal.InAppMessages.addTrigger("complaint_done", "true");
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/done.png', width: 350, height: 350),
                const SizedBox(height: 20),
                Text(
                  "Done!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isAnonymous
                      ? "Your complaint was submitted anonymously.\nIt will not show in 'My Complaints'."
                      : "We will get in touch with you if more information is required.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isAnonymous
                      ? "Admins will process your anonymous complaint. You can’t track it in 'My Complaints'."
                      : "You can check your issue status in the My Complaints tab.\n\n"
                          "Estimated resolution time: 10–12 hours (complaints between 12PM–8AM will be processed after 8AM).",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
