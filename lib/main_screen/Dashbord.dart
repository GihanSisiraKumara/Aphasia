import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Dashbord extends StatefulWidget {
  const Dashbord({super.key});

  @override
  State<Dashbord> createState() => _DashbordState();
}

class _DashbordState extends State<Dashbord> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String username = '';
  String userEmail = '';
  String userId = '';
  bool isLoading = true;
  Map<String, dynamic>? _latestAnalysis;
  List<Map<String, dynamic>> _recentAnalyses = [];
  int _totalSessions = 0;
  double _overallAccuracy = 0.0;
  String? _errorMessage;

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
        userId = currentUser.uid;

        print('Dashboard: User ID: $userId');
        print('Dashboard: User Email: $userEmail');

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
          });
          print('Dashboard: Username found: $username');
        } else {
          setState(() {
            username = 'User';
          });
          print('Dashboard: No username found, using default');
        }

        // Now get the analysis data for this specific user
        await _getUserAnalysisData();
      } else {
        setState(() {
          _errorMessage = 'User not authenticated';
          isLoading = false;
        });
        print('Dashboard: User not authenticated');
      }
    } catch (e) {
      print('Error getting user data: $e');
      setState(() {
        _errorMessage = 'Error loading user data: $e';
        username = 'User';
        isLoading = false;
      });
    }
  }

  // Get user-specific grammar analysis from Firestore
  Future<void> _getUserAnalysisData() async {
    try {
      print('Dashboard: Fetching analysis data for user: $userId');

      // Get the latest analyses for this specific user
      final querySnapshot = await _firestore
          .collection('voice_transcriptions')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      print('Dashboard: Found ${querySnapshot.docs.length} documents');

      // Get total sessions count
      final countSnapshot = await _firestore
          .collection('voice_transcriptions')
          .where('user_id', isEqualTo: userId)
          .get();

      setState(() {
        _totalSessions = countSnapshot.docs.length;
      });

      print('Dashboard: Total sessions: $_totalSessions');

      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> analyses = [];
        double totalAccuracy = 0.0;
        int validAnalyses = 0;

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          print('Dashboard: Document data: ${doc.id}');
          print(
              'Dashboard: Has analysis_result: ${data.containsKey('analysis_result')}');

          if (data.containsKey('analysis_result')) {
            final analysis = data['analysis_result'];
            analyses.add(analysis);

            // Calculate accuracy for overall average
            final wrongWordCount = analysis['wrong_word_count'] ?? 0;
            final totalWords = analysis['total_words'] ?? 1;
            if (totalWords > 0) {
              final accuracy =
                  ((totalWords - wrongWordCount) / totalWords * 100);
              totalAccuracy += accuracy;
              validAnalyses++;
              print('Dashboard: Analysis accuracy: $accuracy%');
            }
          }
        }

        print('Dashboard: Valid analyses found: $validAnalyses');

        setState(() {
          _latestAnalysis = analyses.isNotEmpty ? analyses.first : null;
          _recentAnalyses = analyses;
          _overallAccuracy =
              validAnalyses > 0 ? totalAccuracy / validAnalyses : 0.0;
          isLoading = false;
          _errorMessage = null;
        });

        print('Dashboard: Latest analysis: $_latestAnalysis');
        print('Dashboard: Overall accuracy: $_overallAccuracy%');
      } else {
        print('Dashboard: No analysis data found for user');
        setState(() {
          _latestAnalysis = null;
          _recentAnalyses = [];
          _overallAccuracy = 0.0;
          isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error getting analysis data: $e');
      setState(() {
        _errorMessage = 'Error loading analysis data: $e';
        isLoading = false;
      });
    }
  }

  // Refresh data
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });
    await _getUserAnalysisData();
  }

  // Build mini analysis chart for main card
  Widget _buildMiniChart() {
    if (_latestAnalysis == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 30, color: Colors.white70),
          SizedBox(height: 8),
          Text(
            'No Data',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    final wrongWordCount = _latestAnalysis!['wrong_word_count'] ?? 0;
    final totalWords = _latestAnalysis!['total_words'] ?? 1;
    final correctWordCount = totalWords - wrongWordCount;
    final accuracy = ((correctWordCount / totalWords) * 100).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Accuracy percentage and label
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$accuracy%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Last Session',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 254, 254),
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12), // Space between text and chart
        // Right side: Mini pie chart
        SizedBox(
          height: 70,
          width: 70,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: const Color.fromARGB(255, 43, 151, 37),
                  value: correctWordCount.toDouble(),
                  radius: 30,
                  showTitle: false,
                ),
                PieChartSectionData(
                  color: const Color(0xFFF44336),
                  value: wrongWordCount.toDouble(),
                  radius: 20,
                  showTitle: false,
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 10,
              startDegreeOffset: -90,
            ),
          ),
        ),
      ],
    );
  }

  // Build analysis details for secondary card
  Widget _buildAnalysisDetails() {
    if (_latestAnalysis == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record your',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            'first voice!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    final wrongWordCount = _latestAnalysis!['wrong_word_count'] ?? 0;
    final totalWords = _latestAnalysis!['total_words'] ?? 0;
    final correctWordCount = totalWords - wrongWordCount;
    final confidence = ((_latestAnalysis!['confidence'] ?? 0.0) * 100).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Correct: $correctWordCount',
              style: const TextStyle(
                color: Color.fromARGB(249, 255, 255, 255),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF44336),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Wrong: $wrongWordCount',
              style: const TextStyle(
                color: Color.fromARGB(253, 255, 255, 255),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Confidence: $confidence%',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Navigation function for bottom navigation bar
  void _navigateToPage(String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading your data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(232, 245, 232, 1),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Top Header Section
              Container(
                height: 400,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 216, 255, 166),
                      Color.fromARGB(255, 33, 180, 82),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with Username and Profile
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome',
                                style: TextStyle(
                                  color: Color.fromARGB(179, 18, 18, 18),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                username.isNotEmpty
                                    ? username.substring(0, 1).toUpperCase() +
                                        username.substring(1)
                                    : 'User',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 114, 114, 114),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              _showProfileOptions();
                            },
                            child: const CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(
                                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Error Message
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Stats Section - Updated with Analysis Data
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Overall Accuracy',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_overallAccuracy.round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Sessions',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _totalSessions.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/tracking');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'New Test',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Card Section - Updated with Analysis Charts
                      Row(
                        children: [
                          // Main Card - Analysis Chart
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: _buildMiniChart(),
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          // Secondary Card - Analysis Details
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _buildAnalysisDetails(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Recent Sessions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshData,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildRecentSessionsList(),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Treatment Levels Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Continue Your Treatment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Follow the instructions to improve!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Profile Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 1.0,
                      children: [
                        _buildProfileCard("0", "Level 0", '/treatmentZero'),
                        _buildProfileCard("1", "Level 1", '/treatmentOne'),
                        _buildProfileCard("2", "Level 2", '/treatmentTwo'),
                        _buildProfileCard("3", "Level 3", '/treatmentThree'),
                        _buildProfileCard("4", "Level 4", '/treatmentFour'),
                        _buildProfileCard("5", "Level 5", '/treatmentFive'),
                        _buildProfileCard("6", "Level 6", '/treatmentSix'),
                        _buildProfileCard("7", "Level 7", '/treatmentSeven'),
                        _buildProfileCard("8", "Level 8", '/treatmentEight'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, 'Dashboard', true, null),
            _buildNavItem(Icons.language, 'AI chat', false, '/aiChat'),
            _buildNavItem(Icons.credit_card, 'About Us', false, '/send'),
            _buildNavItem(Icons.track_changes, 'Tracking', false, '/tracking'),
            _buildNavItem(Icons.person, 'Profile', false, '/profile'),
          ],
        ),
      ),
    );
  }

  // Build recent sessions list
  Widget _buildRecentSessionsList() {
    if (_recentAnalyses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              'No sessions yet',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tracking');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 33, 180, 82),
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Your First Session'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentAnalyses.length,
        itemBuilder: (context, index) {
          final analysis = _recentAnalyses[index];
          final wrongWordCount = analysis['wrong_word_count'] ?? 0;
          final totalWords = analysis['total_words'] ?? 1;
          final accuracy =
              ((totalWords - wrongWordCount) / totalWords * 100).round();
          final confidence = ((analysis['confidence'] ?? 0.0) * 100).round();

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAccuracyColor(accuracy),
              child: Text(
                '$accuracy%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('Session ${_recentAnalyses.length - index}'),
            subtitle: Text('Accuracy: $accuracy% • Confidence: $confidence%'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Could navigate to detailed view
            },
          );
        },
      ),
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildProfileCard(String number, String subtitle, String routeName) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 186, 183, 183),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 30, 29, 29),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, String? routeName) {
    return GestureDetector(
      onTap: () {
        if (routeName != null) {
          _navigateToPage(routeName);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color:
                isActive ? const Color.fromARGB(255, 33, 180, 82) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? const Color.fromARGB(255, 33, 180, 82)
                  : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('View All Sessions'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to detailed analysis page
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
