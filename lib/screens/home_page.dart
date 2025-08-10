import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:skillcon/screens/analyze.dart'; // Import AnalyzeScreen
import 'package:skillcon/screens/forums.dart';
import 'package:skillcon/screens/login_screen.dart';
import 'package:skillcon/screens/maps.dart';
import 'package:skillcon/screens/resume.dart';
import 'package:skillcon/screens/roadmap.dart';
import 'package:skillcon/screens/stamp.dart';
import 'package:skillcon/service/auth_service.dart';

// DashboardBox widget
class DashboardBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const DashboardBox({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  String? userName;
  final TextEditingController searchController = TextEditingController();

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Container(), // Placeholder for Home main content
    // You can add other pages if needed here later
  ];

  List<dynamic> _jobData = [];
  List<dynamic> _searchResults = [];
  bool _showSearchResults = false;

  Future<void> _loadUserName() async {
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (doc.exists) {
      setState(() {
        userName = doc.data()?['name'] ?? 'User';
      });
    }
  }

  Future<void> _loadJobData() async {
    final jsonString = await rootBundle.loadString(
      'lib/dataset/job_dataset.json',
    );
    setState(() {
      _jobData = json.decode(jsonString);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadJobData();

    searchController.addListener(_onSearchChanged);
  }

  void _navigateToAnalyze(String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResumeAnalyzerScreen()),
    );
  }

  void _onNavBarTapped(int index) {
    if (index == 1) {
      // Upload file icon tapped
      _navigateToAnalyze("file");
    } else if (index == 2) {
      // Camera icon tapped
      _navigateToAnalyze("camera");
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    List<dynamic> matches = [];
    for (var job in _jobData) {
      final jobTitle = (job['job'] ?? '').toString().toLowerCase();
      final skills = List<String>.from(
        job['skillset'] ?? [],
      ).map((s) => s.toLowerCase()).toList();

      if (jobTitle.contains(query) ||
          skills.any((skill) => skill.contains(query))) {
        matches.add(job);
      }
    }

    setState(() {
      _searchResults = matches;
      _showSearchResults = true;
    });
  }

  void _onJobTap(dynamic job) {
    showDialog(
      context: context,
      builder: (context) {
        final primaryColor = Colors.blue.shade700;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            job['job'],
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Place: ${job['place']}'),
                const SizedBox(height: 8),
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(job['description']),
                const SizedBox(height: 8),
                Text(
                  'Skillset:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 6,
                  children: (job['skillset'] as List<dynamic>)
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text('Salary Range: ${job['salary-range']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Image.asset(
          'lib/assets/branding.png',
          height: 110,
          fit: BoxFit.contain,
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Logout'),
                        onTap: () async {
                          Navigator.of(context).pop(); // close the sheet first

                          // Optionally perform logout logic here
                          // e.g., await authService.logout();

                          // Then navigate to LoginScreen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.cancel),
                        title: const Text('Cancel'),
                        onTap: () {
                          Navigator.of(context).pop(); // just close the sheet
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${userName ?? 'Loading...'}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 18),
              // Search field + dropdown results
              Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search jobs, roadmaps, forums...',
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_showSearchResults)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final job = _searchResults[index];
                          return ListTile(
                            title: Text(job['job']),
                            subtitle: Text(job['place']),
                            onTap: () => _onJobTap(job),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  DashboardBox(
                    title: 'My Resume',
                    icon: Icons.description_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResumeHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardBox(
                    title: 'Active Roadmaps',
                    icon: Icons.map_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActiveRoadmapsScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardBox(
                    title: 'Digital Stamps',
                    icon: Icons.verified_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DigitalStampsScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardBox(
                    title: 'Forums',
                    icon: Icons.forum_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForumsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MapsWidget()),
                    );
                  },
                  child: const Text(
                    "Find Jobs Near Me",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'Camera',
          ),
        ],
      ),
    );
  }
}
