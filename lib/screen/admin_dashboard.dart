// AdminDashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import './ComplaintDetailPage.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int totalComplaints = 0;
  int pendingComplaints = 0;
  int inProgressComplaints = 0;
  int resolvedComplaints = 0;

  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];

  TextEditingController searchController = TextEditingController();
  StreamSubscription? _complaintsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    DatabaseReference complaintsRef = FirebaseDatabase.instance.ref('complaints');
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');

    _complaintsSubscription = complaintsRef.onValue.listen((complaintEvent) async {
      if (!mounted) return;

      final complaintData = complaintEvent.snapshot.value as Map<dynamic, dynamic>?;

      if (complaintData == null) {
        if (mounted) {
          setState(() {
            totalComplaints = pendingComplaints = inProgressComplaints = resolvedComplaints = 0;
            complaints = [];
            filteredComplaints = [];
          });
        }
        return;
      }

      List<Map<String, dynamic>> loadedComplaints = [];
      int pending = 0, inProgress = 0, resolved = 0, total = 0;

      for (var entry in complaintData.entries) {
        final complaint = entry.value as Map<dynamic, dynamic>;
        String userId = complaint["user_id"] ?? "Unknown";

        DataSnapshot userSnapshot = await usersRef.child(userId).get();
        Map<String, dynamic>? userData = userSnapshot.value != null
            ? Map<String, dynamic>.from(userSnapshot.value as Map)
            : null;

        String status = complaint["status"]?.toString() ?? "Pending";
        if (status == "Pending") pending++;
        if (status == "In Progress") inProgress++;
        if (status == "Resolved") resolved++;
        total++;

        String timestamp = complaint["timestamp"] ?? "Unknown";
        String date = "Unknown", time = "Unknown";

        if (timestamp != "Unknown") {
          DateTime dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
          date = "${dateTime.day}-${dateTime.month}-${dateTime.year}";
          time = "${dateTime.hour}:${dateTime.minute}";
        }

        String? mediaUrl = complaint["media_url"] ?? complaint["image_url"] ?? "";
        String mediaType = (complaint["media_type"] ??
            (complaint["image_url"] != null ? "image" : "video"))
            .toString()
            .toLowerCase();

        loadedComplaints.add({
          "id": entry.key,
          "issue_type": complaint["issue_type"] ?? "Unknown",
          "city": complaint["city"] ?? "Unknown",
          "state": complaint["state"] ?? "Unknown",
          "location": complaint["location"] ?? "Unknown",
          "description": complaint["description"] ?? "No description",
          "date": date,
          "time": time,
          "status": status,
          "media_url": (mediaUrl ?? '').isEmpty ? 'https://picsum.photos/250?image=9' : mediaUrl,
          "media_type": mediaType,
          "user_id": userId,
          "user_name": userData?["name"] ?? "Unknown",
          "user_email": userData?["email"] ?? "Unknown",
        });
      }

      if (mounted) {
        setState(() {
          totalComplaints = total;
          pendingComplaints = pending;
          inProgressComplaints = inProgress;
          resolvedComplaints = resolved;
          complaints = loadedComplaints;
          filteredComplaints = complaints;
        });
      }
    });
  }

  void _searchComplaints(String query) {
    setState(() {
      filteredComplaints = complaints.where((complaint) {
        return complaint.values.any((value) =>
            value.toString().toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  Route _createSlideRoute(Map<String, dynamic> complaint) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ComplaintDetailPage(complaintId: complaint["id"]),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Color.fromARGB(255, 10, 10, 10))),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 13, 13, 13)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(), // Cancel
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close the dialog
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text("Logout", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Search complaints...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), // updated
                ),
                onChanged: _searchComplaints,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredComplaints.length,
                itemBuilder: (ctx, index) {
                  final complaint = filteredComplaints[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: complaint["media_type"] == "image"
                          ? ClipOval(
                        child: Image.network(
                          complaint["media_url"],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 40),
                        ),
                      )
                          : const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.videocam, color: Colors.white),
                      ),
                      title: Text(
                        complaint["issue_type"] ?? "Unknown",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Status: ${complaint["status"]}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.of(context).push(
                        _createSlideRoute(complaint),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
