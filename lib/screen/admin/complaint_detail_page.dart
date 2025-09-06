import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../service/local_status_storage.dart';
import '../../service/notification_service.dart';
import '../../theme/theme_provider.dart';
import 'widgets/bottom_nav_admin.dart';
import 'admin_dashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ComplaintDetailPage extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailPage({super.key, required this.complaintId});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> with TickerProviderStateMixin {
  Map<String, dynamic>? complaint;
  late String selectedStatus;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isMuted = true;
  late AnimationController _deleteButtonAnimationController;
  late Animation<double> _deleteButtonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetails();

    // Initialize animation controllers
    _deleteButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _deleteButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _deleteButtonAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _deleteButtonAnimationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaintDetails() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('complaints/${widget.complaintId}')
        .get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Fetch user data
      String userId = data['user_id'] ?? '';
bool isAnonymous = data['is_anonymous'] ?? false;

if (isAnonymous || userId == 'anonymous') {
  data['user_name'] = 'Anonymous';
  data['user_email'] = 'Hidden';
  data['user_phone'] = 'Hidden';
} else {
  final userSnapshot = await FirebaseDatabase.instance.ref('users/$userId').get();
  if (userSnapshot.exists) {
    final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
    data['user_name'] = userData['name'] ?? 'Unknown';
    data['user_email'] = userData['email'] ?? 'N/A';
    data['user_phone'] = userData['phone'] ?? 'Not Provided';
  } else {
    data['user_name'] = 'Unknown';
    data['user_email'] = 'N/A';
    data['user_phone'] = 'Not Provided';
  }
}


      setState(() {
        complaint = data;
        selectedStatus = data["status"] ?? "Pending";
      });
      _initMedia(data);
    }
  }

  void _initMedia(Map<String, dynamic> data) {
    final type = data["media_type"]?.toLowerCase();
    final url = (data["media_url"] ?? '').toString();

    if (type == "video" && url.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          _videoController!.setVolume(_isMuted ? 0 : 1);
          setState(() => _videoInitialized = true);
        }).catchError((e) {
          debugPrint("Video init failed: $e");
        });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseDatabase.instance
        .ref('complaints/${widget.complaintId}')
        .update({"status": newStatus});

    // Fetch complaint details for notification
    final snapshot = await FirebaseDatabase.instance
        .ref('complaints/${widget.complaintId}')
        .get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final String userId = data['user_id'] ?? '';
      final String issueType = data['issue_type'] ?? 'Complaint';
      final String status = data['status'] ?? newStatus;

      // Save notification in local storage for user
      await LocalStatusStorage.saveNotification({
        'message':
        'Your $issueType complaint from ${data['city'] ?? 'Unknown City'}, ${data['state'] ?? 'Unknown State'} has been updated to $status.',
        'timestamp': DateTime.now().toIso8601String(),
        'complaint_id': widget.complaintId,
        'status': status,
        'issue_type': issueType,
      });

      // Optionally show a local notification immediately
      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Complaint Status Updated',
        body:
        'Your $issueType complaint from ${data['city'] ?? 'Unknown City'}, ${data['state'] ?? 'Unknown State'} is now $status.',
        payload: widget.complaintId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      if (complaint == null) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
          appBar: _buildAppBar(themeProvider, "Loading...", true),
          body: _buildDetailShimmer(themeProvider, screenHeight, screenWidth),
        );
      }

      final String mediaType = complaint!["media_type"]?.toLowerCase() ?? "image";
      final String mediaUrl = (complaint!["media_url"] ?? '').toString().isEmpty
          ? 'https://picsum.photos/250?image=9'
          : complaint!["media_url"];

      return Scaffold(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : const Color.fromARGB(255, 21, 172, 241),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: themeProvider.isDarkMode
                  ? [Colors.grey[800]!, Colors.grey[800]!]
                  : [const Color.fromARGB(255, 21, 172, 241), const Color.fromARGB(255, 21, 172, 241)],
            ),
          ),
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(themeProvider, complaint!["issue_type"] ?? "Complaint"),

              // Main Content - Scrollable
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Media Container
                        Container(
                          width: double.infinity,
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _buildMediaPreview(mediaType, mediaUrl, themeProvider),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Details Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
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
                              // Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: themeProvider.isDarkMode
                                          ? Colors.teal.withOpacity(0.2)
                                          : const Color(0xFF1565C0).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: themeProvider.isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Complaint Details",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Review and manage complaint information",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Information Grid
                              _buildInfoGrid(themeProvider),

                              const SizedBox(height: 24),

                              // Status Update Section
                              _buildStatusUpdateSection(themeProvider),

                              const SizedBox(height: 32),

                              // Delete Button
                              _buildDeleteButton(themeProvider),
                            ],
                          ),
                        ),

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

  Widget _buildCustomAppBar(ThemeProvider themeProvider, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 46, 20, 16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : const Color.fromARGB(255, 21, 172, 241),
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
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider themeProvider, String title, bool isShimmer) {
    return AppBar(
      title: isShimmer
          ? Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            )
          : Text(title, style: const TextStyle(color: Colors.white)),
      backgroundColor: themeProvider.isDarkMode ? Colors.teal : const Color(0xFF1565C0),
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
    );
  }

  Widget _buildInfoGrid(ThemeProvider themeProvider) {
    final List<Map<String, dynamic>> infoItems = [
      {
        'icon': Icons.location_on_outlined,
        'title': 'Location',
        'value': complaint!["location"],
        'color': Colors.red,
      },
      {
        'icon': Icons.location_city_outlined,
        'title': 'City',
        'value': complaint!["city"],
        'color': Colors.blue,
      },
      {
        'icon': Icons.map_outlined,
        'title': 'State',
        'value': complaint!["state"],
        'color': Colors.green,
      },
      {
        'icon': Icons.access_time_outlined,
        'title': 'Date & Time',
        'value': _formatTimestamp(complaint!["timestamp"]),
        'color': Colors.orange,
      },
      {
        'icon': Icons.person_outline,
        'title': 'Reporter',
        'value': "${complaint!["user_name"]} (${complaint!["user_email"]})",
        'color': Colors.purple,
      },
      {
        'icon': Icons.phone_outlined,
        'title': 'Phone',
        'value': complaint!["user_phone"],
        'color': Colors.teal,
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Description',
        'value': complaint!["description"] ?? "No description provided",
        'color': Colors.indigo,
      },
    ];

    return Column(
      children: infoItems.map((item) => _buildModernInfoItem(
        item['icon'] as IconData,
        item['title'] as String,
        item['value'] as String?,
        item['color'] as Color,
        themeProvider,
      )).toList(),
    );
  }

  Widget _buildModernInfoItem(
    IconData icon,
    String title,
    String? value,
    Color iconColor,
    ThemeProvider themeProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'Not provided',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:                 Icon(
                  Icons.update_outlined,
                  color: themeProvider.isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Update Status",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
              ),
              dropdownColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.white,
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
              items: [
                _buildDropdownItem("Pending", Icons.schedule, Colors.orange, themeProvider),
                _buildDropdownItem("In Progress", Icons.work_outline, Colors.blue, themeProvider),
                _buildDropdownItem("Resolved", Icons.check_circle_outline, Colors.green, themeProvider),
              ],
              onChanged: (newStatus) {
                if (newStatus != null) {
                  _updateStatus(newStatus);
                  setState(() {
                    selectedStatus = newStatus;
                  });
                  Fluttertoast.showToast(msg: "Status updated to $newStatus");
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    String status,
    IconData icon,
    Color color,
    ThemeProvider themeProvider
  ) {
    return DropdownMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            status,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(ThemeProvider themeProvider) {
    return AnimatedBuilder(
      animation: _deleteButtonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _deleteButtonScaleAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeProvider.isDarkMode
                    ? [Colors.red[400]!, Colors.red[600]!]
                    : [Colors.red[500]!, Colors.red[700]!],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                _deleteButtonAnimationController.forward().then((_) {
                  _deleteButtonAnimationController.reverse();
                });
                _showDeleteDialog(themeProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
              label: const Text(
                "Delete Complaint",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_outlined,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Confirm Deletion",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Are you sure you want to delete this complaint? This action cannot be undone.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: themeProvider.isDarkMode ? Colors.grey[500]! : Colors.grey[400]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      Navigator.pop(context); // Close dialog

                      await FirebaseDatabase.instance
                          .ref('complaints/${widget.complaintId}')
                          .remove();

                      if (!mounted) return;
                      navigator.pushReplacement(
                        MaterialPageRoute(builder: (context) => MainNavigationWrapper()),
                      );
                      Fluttertoast.showToast(msg: "Complaint deleted successfully!");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailShimmer(ThemeProvider themeProvider, double screenHeight, double screenWidth) {
    return Column(
      children: [
        // Custom App Bar Shimmer
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: screenWidth * 0.4,
                height: 20,
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Content
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Media shimmer
                  Container(
                    height: screenHeight * 0.25,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Details shimmer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
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
                      children: [
                        // Header shimmer
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 20,
                                    width: screenWidth * 0.4,
                                    decoration: BoxDecoration(
                                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 14,
                                    width: screenWidth * 0.6,
                                    decoration: BoxDecoration(
                                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Info items shimmer
                        ...List.generate(7, (index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 14,
                                        width: screenWidth * 0.2,
                                        decoration: BoxDecoration(
                                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 16,
                                        width: screenWidth * 0.5,
                                        decoration: BoxDecoration(
                                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Status update shimmer
                        Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Delete button shimmer
                        Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview(String type, String url, ThemeProvider themeProvider) {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.isAbsolute) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 64,
              color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              "No media available",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (type == "video") {
      if (_videoController != null && _videoInitialized) {
        return Container(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),

              // Center play/pause button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                        _videoController!.setVolume(_isMuted ? 0 : 1);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          height: 250,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: themeProvider.isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading video...",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        url,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 250,
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: themeProvider.isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  "Loading image...",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint("Image load failed: $error");
          return Container(
            height: 250,
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  "Failed to load image",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(String? isoTimestamp) {
    if (isoTimestamp == null) return "Not specified";
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inDays > 0) {
        return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago";
      } else {
        return "Just now";
      }
    } catch (_) {
      return isoTimestamp;
    }
  }
}
