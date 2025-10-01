import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String username = '';
  String userEmail = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  // Get user data from Firestore
  Future<void> _getUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        userEmail = currentUser.email ?? '';

        // Get username from Firestore
        final querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          setState(() {
            username = userData['username'] ?? 'User';
            isLoading = false;
          });
        } else {
          setState(() {
            username = 'User';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
      setState(() {
        username = 'User';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'User Profile',
          style: TextStyle(
            fontSize: 22,
            color: Color.fromARGB(255, 244, 242, 242),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          style: ButtonStyle(
            iconSize: WidgetStateProperty.all<double>(30),
            iconColor: WidgetStateProperty.all<Color>(
                const Color.fromARGB(255, 252, 251, 251)),
            backgroundColor: WidgetStateProperty.all<Color>(
                const Color.fromARGB(255, 64, 183, 37)),
          ),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 216, 255, 166),
                Color.fromARGB(255, 33, 180, 82)
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FFFF),
                    Color(0xFFE8F8F5),
                    Color(0xFFF0FFF4),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Profile Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Image
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF4CAF50),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    spreadRadius: 0,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const CircleAvatar(
                                backgroundImage: NetworkImage(
                                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // User Name
                            Text(
                              username.isNotEmpty
                                  ? username.substring(0, 1).toUpperCase() +
                                      username.substring(1)
                                  : 'User',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // User Email
                            Text(
                              userEmail,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Divider
                            Container(
                              height: 1,
                              color: const Color(0xFFE8F5E8),
                            ),
                            const SizedBox(height: 25),

                            // User Info Sections
                            _buildInfoSection(
                              icon: Icons.person_outline,
                              title: 'Account Type',
                              value: 'Standard User',
                            ),
                            const SizedBox(height: 20),

                            _buildInfoSection(
                              icon: Icons.calendar_today_outlined,
                              title: 'Member Since',
                              value: 'Current User',
                            ),
                            const SizedBox(height: 20),

                            _buildInfoSection(
                              icon: Icons.verified_user_outlined,
                              title: 'Status',
                              value: 'Verified',
                              valueColor: const Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Stats Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: Color(0xFF4CAF50),
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Profile Summary',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            // Stats Grid
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              childAspectRatio: 1.5,
                              children: [
                                _buildStatCard(
                                  'Active Sessions',
                                  '8',
                                  Icons.track_changes_outlined,
                                  const Color(0xFF2196F3),
                                ),
                                _buildStatCard(
                                  'Progress Level',
                                  'Intermediate',
                                  Icons.trending_up_outlined,
                                  const Color(0xFF4CAF50),
                                ),
                                _buildStatCard(
                                  'Goals Completed',
                                  '12',
                                  Icons.flag_outlined,
                                  const Color(0xFFFF9800),
                                ),
                                _buildStatCard(
                                  'Streak Days',
                                  '5',
                                  Icons.local_fire_department_outlined,
                                  const Color(0xFFF44336),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // App Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF4CAF50),
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'About Aphasia Therapy',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'This application is designed to help individuals with aphasia improve their speech and language skills through personalized exercises and tracking.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.health_and_safety_outlined,
                                    color: Color(0xFF4CAF50),
                                    size: 40,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Keep Practicing!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Consistent practice leads to better results',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = const Color(0xFF666666),
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4CAF50),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
