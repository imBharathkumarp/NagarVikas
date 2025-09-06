import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../admin/complaint_detail_page.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final String category; // 'total', 'resolved', 'pending', 'inprogress'
  final String title;
  final Color color;
  final IconData icon;

  const ComplaintDetailsPage({
    super.key,
    required this.category,
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> totalComplaints = [];
  List<Map<String, dynamic>> resolvedComplaints = [];
  List<Map<String, dynamic>> pendingComplaints = [];
  List<Map<String, dynamic>> inProgressComplaints = [];

  final List<String> categories = [
    'Total',
    'Resolved',
    'Pending',
    'In Progress'
  ];
  final List<Color> categoryColors = [
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.blue
  ];
  final List<IconData> categoryIcons = [
    Icons.all_inbox,
    Icons.check_circle,
    Icons.timelapse,
    Icons.hourglass_empty
  ];

  @override
  void initState() {
    super.initState();
    _setInitialPage();
    fetchComplaintsByCategory();
  }

  void _setInitialPage() {
    switch (widget.category.toLowerCase()) {
      case 'total':
        _currentPage = 0;
        break;
      case 'resolved':
        _currentPage = 1;
        break;
      case 'pending':
        _currentPage = 2;
        break;
      case 'inprogress':
        _currentPage = 3;
        break;
    }
    _pageController = PageController(initialPage: _currentPage);
  }

  Future<void> fetchComplaintsByCategory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final complaintsRef = FirebaseDatabase.instance.ref('complaints');
      final usersRef = FirebaseDatabase.instance.ref('users');
      final snapshot = await complaintsRef.get();

      if (snapshot.exists) {
        List<Map<String, dynamic>> total = [];
        List<Map<String, dynamic>> resolved = [];
        List<Map<String, dynamic>> pending = [];
        List<Map<String, dynamic>> inProgress = [];

        final data = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in data.entries) {
          final complaint = Map<String, dynamic>.from(entry.value);
          String userId = complaint["user_id"] ?? "Unknown";

          DataSnapshot userSnapshot = await usersRef.child(userId).get();
          Map<String, dynamic>? userData = userSnapshot.value != null
              ? Map<String, dynamic>.from(userSnapshot.value as Map)
              : null;

          String status = (complaint["status"] ?? "Pending").toString();
          String timestamp = complaint["timestamp"] ?? "Unknown";
          String date = "Unknown", time = "Unknown";

          if (timestamp != "Unknown") {
            DateTime dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
            date = "${dateTime.day}-${dateTime.month}-${dateTime.year}";
            time =
                "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
          }

          String? mediaUrl =
              complaint["media_url"] ?? complaint["image_url"] ?? "";
          String mediaType = (complaint["media_type"] ??
                  (complaint["image_url"] != null ? "image" : "video"))
              .toString()
              .toLowerCase();

          Map<String, dynamic> complaintData = {
            "id": entry.key,
            "issue_type": complaint["issue_type"] ?? "Unknown",
            "city": complaint["city"] ?? "Unknown",
            "state": complaint["state"] ?? "Unknown",
            "location": complaint["location"] ?? "Unknown",
            "description": complaint["description"] ?? "No description",
            "date": date,
            "time": time,
            "status": status,
            "media_url": (mediaUrl ?? '').isEmpty
                ? 'https://picsum.photos/250?image=9'
                : mediaUrl,
            "media_type": mediaType,
            "user_id": userId,
            "user_name": userData?["name"] ?? "Unknown",
            "user_email": userData?["email"] ?? "Unknown",
          };

          total.add(complaintData);

          switch (status.toLowerCase()) {
            case 'resolved':
            case 'completed':
              resolved.add(complaintData);
              break;
            case 'pending':
              pending.add(complaintData);
              break;
            case 'in progress':
              inProgress.add(complaintData);
              break;
          }
        }

        setState(() {
          totalComplaints = total;
          resolvedComplaints = resolved;
          pendingComplaints = pending;
          inProgressComplaints = inProgress;
          isLoading = false;
        });
      } else {
        setState(() {
          totalComplaints = [];
          resolvedComplaints = [];
          pendingComplaints = [];
          inProgressComplaints = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching complaints: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getComplaintsForCategory(int index) {
    switch (index) {
      case 0:
        return totalComplaints;
      case 1:
        return resolvedComplaints;
      case 2:
        return pendingComplaints;
      case 3:
        return inProgressComplaints;
      default:
        return [];
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in progress':
        return const Color(0xFF2196F3);
      case 'resolved':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFE57373);
      default:
        return Colors.grey[600]!;
    }
  }

  Route _createSlideRoute(Map<String, dynamic> complaint) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ComplaintDetailPage(complaintId: complaint["id"]),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

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
                  : [const Color.fromARGB(255, 21, 172, 241), const Color.fromARGB(255, 21, 172, 241)],
            ),
          ),
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(themeProvider),

              // Main Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[900] : const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: isLoading
                      ? _buildComplaintsShimmer(themeProvider)
                      : Column(
                          children: [
                            const SizedBox(height: 20),

                            // Category Selection Header
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(6),
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
                                children: List.generate(categories.length, (index) {
                                  bool isSelected = _currentPage == index;
                                  List<Map<String, dynamic>> complaints =
                                      _getComplaintsForCategory(index);

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.all(3),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? categoryColors[index]
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: categoryColors[index].withOpacity(0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.white.withOpacity(0.2)
                                                    : categoryColors[index].withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                categoryIcons[index],
                                                color: isSelected
                                                    ? Colors.white
                                                    : categoryColors[index],
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${complaints.length}',
                                              style: GoogleFonts.urbanist(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (themeProvider.isDarkMode ? Colors.white : categoryColors[index]),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              categories[index],
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (themeProvider.isDarkMode ? Colors.grey[400] : categoryColors[index]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Page Indicator
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(categories.length, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    height: 6,
                                    width: _currentPage == index ? 28 : 10,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index
                                          ? categoryColors[_currentPage]
                                          : (themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300]),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Swipeable Content Area
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemCount: categories.length,
                                itemBuilder: (context, pageIndex) {
                                  List<Map<String, dynamic>> complaints =
                                      _getComplaintsForCategory(pageIndex);
                                  return _buildComplaintsList(complaints, pageIndex, themeProvider);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),

      );
    });
  }

  Widget _buildCustomAppBar(ThemeProvider themeProvider) {
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
              'Complaint Details',
              style: GoogleFonts.poppins(
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
                Icons.refresh_rounded,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: fetchComplaintsByCategory,
              tooltip: 'Refresh Data',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsShimmer(ThemeProvider themeProvider) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Header shimmer
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
            children: List.generate(
                4,
                (index) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        height: 90,
                      ),
                    )),
          ),
        ),

        const SizedBox(height: 16),

        // Page indicator shimmer
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                4,
                (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: 10,
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
          ),
        ),

        const SizedBox(height: 20),

        // List shimmer
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 6,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 18,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 14,
                              width: 120,
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 28,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintsList(
      List<Map<String, dynamic>> complaints, int categoryIndex, ThemeProvider themeProvider) {
    if (complaints.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchComplaintsByCategory,
        color: categoryColors[categoryIndex],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: categoryColors[categoryIndex].withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: categoryColors[categoryIndex].withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      categoryIcons[categoryIndex],
                      size: 48,
                      color: categoryColors[categoryIndex],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No ${categories[categoryIndex].toLowerCase()} complaints found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull to refresh and check for updates',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchComplaintsByCategory,
      color: categoryColors[categoryIndex],
      child: AnimationLimiter(
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            // Scroll to bottom to refresh functionality
            if (scrollInfo is ScrollUpdateNotification) {
              // Check if user has scrolled to the bottom and then scrolled a bit more (overscroll)
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent + 50) {
                fetchComplaintsByCategory();
              }
            }
            return false;
          },
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 300),
                child: SlideAnimation(
                  verticalOffset: 30.0,
                  child: FadeInAnimation(
                    child: _buildComplaintCard(complaints[index], categoryIndex, themeProvider),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(
      Map<String, dynamic> complaint, int categoryIndex, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(complaint["status"]).withOpacity(0.3),
          width: 1.5,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(_createSlideRoute(complaint));
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Enhanced Media preview
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _getStatusColor(complaint["status"]).withOpacity(0.1),
                        border: Border.all(
                          color: _getStatusColor(complaint["status"]).withOpacity(0.3),
                        ),
                      ),
                      child: complaint["media_type"] == "image"
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                complaint["media_url"],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.broken_image_rounded,
                                  color: _getStatusColor(complaint["status"]),
                                  size: 28,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.videocam_rounded,
                                color: Colors.blue[600],
                                size: 28,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint["issue_type"] ?? "Unknown Issue",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 14, color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  "${complaint["city"]}, ${complaint["state"]}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Enhanced Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(complaint["status"]).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(complaint["status"]).withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(complaint["status"]).withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        complaint["status"] ?? "Unknown",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(complaint["status"]),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description with better styling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    complaint["description"] ?? "No description",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 16),

                // Enhanced Footer info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline,
                                size: 14, color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              complaint["user_name"] ?? "Unknown",
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "${complaint["date"]} ${complaint["time"]}",
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
