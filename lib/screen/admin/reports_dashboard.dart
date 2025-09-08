import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/theme_provider.dart';

class ReportsDashboard extends StatefulWidget {
  const ReportsDashboard({super.key});

  @override
  ReportsDashboardState createState() => ReportsDashboardState();
}

class ReportsDashboardState extends State<ReportsDashboard>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> filteredReports = [];
  bool isLoading = true;
  String selectedStatus = 'All';
  final TextEditingController searchController = TextEditingController();

  final DatabaseReference _reportsRef =
      FirebaseDatabase.instance.ref("message_reports");
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref("discussion");
  final DatabaseReference _bannedUsersRef =
      FirebaseDatabase.instance.ref("banned_users");

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _listAnimationController;

  late Animation<double> _headerOpacityAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _listOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchReports();
    searchController.addListener(_applyFilters);
  }

  void _initAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _headerAnimationController, curve: Curves.easeOut));

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _headerAnimationController, curve: Curves.easeOutBack));

    _cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _cardAnimationController, curve: Curves.elasticOut));

    _listOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _listAnimationController, curve: Curves.easeIn));

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _listAnimationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _fetchReports() {
    _reportsRef.orderByChild('reportedAt').onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      List<Map<String, dynamic>> loadedReports = [];

      if (data != null) {
        data.forEach((reportId, reportData) {
          loadedReports.add({
            "id": reportId,
            "messageId": reportData["messageId"] ?? "",
            "messageContent": reportData["messageContent"] ?? "",
            "reportedUserId": reportData["reportedUserId"] ?? "",
            "reportedUserName":
                reportData["reportedUserName"] ?? "Unknown User",
            "reporterId": reportData["reporterId"] ?? "",
            "reporterName": reportData["reporterName"] ?? "Unknown User",
            "reportReason": reportData["reportReason"] ?? "",
            "additionalDetails": reportData["additionalDetails"] ?? "",
            "reportedAt": reportData["reportedAt"] ?? 0,
            "status": reportData["status"] ?? "pending",
            "reviewedAt": reportData["reviewedAt"],
            "reviewedBy": reportData["reviewedBy"],
            "adminNote": reportData["adminNote"] ?? "",
          });
        });

        // Sort by report date (newest first)
        loadedReports
            .sort((a, b) => b["reportedAt"].compareTo(a["reportedAt"]));
      }

      if (mounted) {
        setState(() {
          reports = loadedReports;
          isLoading = false;
        });
        _applyFilters();
        _cardAnimationController.forward();
        _listAnimationController.forward();
      }
    });
  }

  void _applyFilters() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredReports = reports.where((report) {
        final matchesStatus = selectedStatus == 'All' ||
            report['status'].toString().toLowerCase() ==
                selectedStatus.toLowerCase();
        final matchesQuery = query.isEmpty ||
            report.values
                .any((value) => value.toString().toLowerCase().contains(query));
        return matchesStatus && matchesQuery;
      }).toList();
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is int && timestamp > 0) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateFormat('MMM d, y • h:mm a').format(date);
      }
      return 'Unknown time';
    } catch (e) {
      return 'Unknown time';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'reviewed':
        return const Color(0xFF2196F3);
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'dismissed':
        return const Color(0xFF9E9E9E);
      default:
        return Colors.grey;
    }
  }

  String _getReasonDisplayName(String reason) {
    switch (reason) {
      case 'inappropriate_content':
        return 'Inappropriate Content';
      case 'harassment':
        return 'Harassment or Bullying';
      case 'spam':
        return 'Spam or Advertisement';
      case 'hate_speech':
        return 'Hate Speech';
      case 'misinformation':
        return 'False Information';
      case 'privacy_violation':
        return 'Privacy Violation';
      case 'other':
        return 'Other';
      default:
        return reason;
    }
  }

  Future<void> _updateReportStatus(String reportId, String newStatus,
      {String? adminNote}) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'reviewedAt': ServerValue.timestamp,
        'reviewedBy': 'admin', // You can replace with actual admin ID
      };

      if (adminNote != null && adminNote.isNotEmpty) {
        updateData['adminNote'] = adminNote;
      }

      await _reportsRef.child(reportId).update(updateData);

      Fluttertoast.showToast(
        msg: "Report status updated to $newStatus",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error updating report status: $e');
      Fluttertoast.showToast(
        msg: "Failed to update report status",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _deleteMessage(String messageId, String reportId) async {
    try {
      // Delete the message
      await _messagesRef.child(messageId).remove();

      // Update report status
      await _updateReportStatus(reportId, 'resolved',
          adminNote: 'Message deleted by admin');

      Fluttertoast.showToast(
        msg: "Message deleted successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error deleting message: $e');
      Fluttertoast.showToast(
        msg: "Failed to delete message",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _banUser(String userId, String userName, String reportId) async {
    try {
      await _bannedUsersRef.child(userId).set({
        "banned_by": "admin",
        "banned_at": ServerValue.timestamp,
        "user_name": userName,
        "reason": "Reported message violation",
      });

      await _updateReportStatus(reportId, 'resolved',
          adminNote: 'User banned for violation');

      Fluttertoast.showToast(
        msg: "$userName has been banned",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error banning user: $e');
      Fluttertoast.showToast(
        msg: "Failed to ban user",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showReportActions(
      Map<String, dynamic> report, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Report Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // Mark as Reviewed
            if (report['status'] == 'pending')
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.visibility, color: Color(0xFF2196F3)),
                ),
                title: Text(
                  'Mark as Reviewed',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateReportStatus(report['id'], 'reviewed');
                },
              ),

            // Delete Message
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete, color: Colors.red),
              ),
              title: Text(
                'Delete Message',
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(report);
              },
            ),

            // Ban User
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.block, color: Colors.orange),
              ),
              title: Text(
                'Ban User',
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBanConfirmation(report);
              },
            ),

            // Dismiss Report
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.close, color: Colors.grey),
              ),
              title: Text(
                'Dismiss Report',
                style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _updateReportStatus(report['id'], 'dismissed',
                    adminNote: 'Report dismissed - no violation found');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Delete Message',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this reported message? This action cannot be undone.',
              style: TextStyle(
                color:
                    themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteMessage(report['messageId'], report['id']);
                },
                child: Text(
                  'Delete',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBanConfirmation(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Ban User',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to ban ${report['reportedUserName']}? They will not be able to send messages until unbanned.',
              style: TextStyle(
                color:
                    themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _banUser(report['reportedUserId'], report['reportedUserName'],
                      report['id']);
                },
                child: Text(
                  'Ban User',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFF8F9FA),
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Column(
              children: [
                Text(
                  "Message Reports",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "${filteredReports.length} report${filteredReports.length == 1 ? '' : 's'}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
            iconTheme: IconThemeData(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeProvider.isDarkMode
                      ? [Colors.grey[800]!, Colors.grey[700]!]
                      : [Colors.white, const Color(0xFFF8F9FA)],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Search and Filter Section
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[700]!
                        : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode
                          ? Colors.black26
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: searchController,
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        hintText: "Search reports...",
                        hintStyle: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey[300]!,
                          ),
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
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: themeProvider.isDarkMode
                            ? Colors.grey[700]
                            : Colors.grey[50],
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Status Filter
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[700]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[600]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          dropdownColor: themeProvider.isDarkMode
                              ? Colors.grey[800]
                              : Colors.white,
                          items: [
                            'All',
                            'Pending',
                            'Reviewed',
                            'Resolved',
                            'Dismissed'
                          ]
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: status == 'All'
                                                ? Colors.grey
                                                : _getStatusColor(status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: themeProvider.isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedStatus = value;
                              });
                              _applyFilters();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Reports List
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF2196F3),
                        ),
                      )
                    : filteredReports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeProvider.isDarkMode
                                            ? Colors.black26
                                            : Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    size: 48,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No reports found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "All messages are being discussed respectfully",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[200]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeProvider.isDarkMode
                                          ? Colors.black26
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header with status and timestamp
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      report['status'])
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getStatusColor(
                                                        report['status'])
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                        report['status']),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  report['status']
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusColor(
                                                        report['status']),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            _formatTimestamp(
                                                report['reportedAt']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: themeProvider.isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),

                                      // Report reason
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.flag,
                                                color: Colors.red, size: 16),
                                            SizedBox(width: 8),
                                            Text(
                                              _getReasonDisplayName(
                                                  report['reportReason']),
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 12),

                                      // Reported message content
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: themeProvider.isDarkMode
                                              ? Colors.grey[750]
                                                  ?.withOpacity(0.5)
                                              : Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: themeProvider.isDarkMode
                                                ? Colors.grey[600]!
                                                : Colors.grey[200]!,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Reported Message:",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: themeProvider.isDarkMode
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              report['messageContent']
                                                      .isNotEmpty
                                                  ? report['messageContent']
                                                  : "Media or Poll content",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: themeProvider.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 12),

                                      // Reporter and reported user info
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Reported User:",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        themeProvider.isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  report['reportedUserName'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        themeProvider.isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Reported By:",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        themeProvider.isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  report['reporterName'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        themeProvider.isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Additional details if provided
                                      if (report['additionalDetails']
                                          .isNotEmpty) ...[
                                        SizedBox(height: 12),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.orange.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.orange
                                                  .withOpacity(0.2),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Additional Details:",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                report['additionalDetails'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      themeProvider.isDarkMode
                                                          ? Colors.grey[300]
                                                          : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      // Admin note if exists
                                      if (report['adminNote'].isNotEmpty) ...[
                                        SizedBox(height: 12),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF2196F3)
                                                .withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Color(0xFF2196F3)
                                                  .withOpacity(0.2),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Admin Note:",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2196F3),
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                report['adminNote'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      themeProvider.isDarkMode
                                                          ? Colors.grey[300]
                                                          : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      // Action buttons
                                      if (report['status'] == 'pending' ||
                                          report['status'] == 'reviewed') ...[
                                        SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _showReportActions(
                                                        report, themeProvider),
                                                icon: Icon(
                                                    Icons.admin_panel_settings,
                                                    size: 18),
                                                label: Text("Take Action"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Color(0xFF2196F3),
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
