import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class Result_review extends StatefulWidget {
  const Result_review({super.key});

  @override
  State<Result_review> createState() => _Result_reviewState();
}

class _Result_reviewState extends State<Result_review> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userId = '';
  List<Map<String, dynamic>> _allSessions = [];
  bool isLoading = true;
  String? _errorMessage;
  bool _indexBuilding = false;

  // Chart configuration
  int _selectedChartType = 0; // 0: Line, 1: Bar
  bool _showCorrectWords = true;
  bool _showWrongWords = true;
  bool _showConfidence = true;

  @override
  void initState() {
    super.initState();
    _getUserSessions();
  }

  Future<void> _getUserSessions() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        userId = currentUser.uid;

        // Try the original query first
        try {
          final querySnapshot = await _firestore
              .collection('voice_transcriptions')
              .where('user_id', isEqualTo: userId)
              .orderBy('timestamp', descending: false)
              .get();

          _processSessions(querySnapshot);
        } catch (e) {
          // If the ordered query fails, try without ordering first
          if (e.toString().contains('index') &&
              e.toString().contains('building')) {
            setState(() {
              _indexBuilding = true;
            });

            // Fallback: Get all documents and sort manually
            final querySnapshot = await _firestore
                .collection('voice_transcriptions')
                .where('user_id', isEqualTo: userId)
                .get();

            // Sort manually by timestamp
            var docs = querySnapshot.docs.toList();
            docs.sort((a, b) {
              final aTimestamp = a.data()['timestamp'] as Timestamp?;
              final bTimestamp = b.data()['timestamp'] as Timestamp?;
              return (aTimestamp?.millisecondsSinceEpoch ?? 0)
                  .compareTo(bTimestamp?.millisecondsSinceEpoch ?? 0);
            });

            _processSessionsFromList(docs);
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      print('Error getting user sessions: $e');
      setState(() {
        _errorMessage = 'Error loading session data: $e';
        isLoading = false;
      });
    }
  }

  void _processSessions(QuerySnapshot querySnapshot) {
    List<Map<String, dynamic>> sessions = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('analysis_result')) {
        final analysis = data['analysis_result'];
        final timestamp = data['timestamp'] as Timestamp?;

        sessions.add({
          'analysis': analysis,
          'timestamp': timestamp,
          'sessionId': doc.id,
        });
      }
    }

    setState(() {
      _allSessions = sessions;
      isLoading = false;
      _errorMessage = null;
      _indexBuilding = false;
    });

    print('Loaded ${_allSessions.length} sessions');
  }

  void _processSessionsFromList(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> sessions = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('analysis_result')) {
        final analysis = data['analysis_result'];
        final timestamp = data['timestamp'] as Timestamp?;

        sessions.add({
          'analysis': analysis,
          'timestamp': timestamp,
          'sessionId': doc.id,
        });
      }
    }

    setState(() {
      _allSessions = sessions;
      isLoading = false;
      _errorMessage = null;
    });

    print('Loaded ${_allSessions.length} sessions using fallback method');
  }

  // ... (Keep all the chart building methods the same as previous version)

  // Build the main chart
  Widget _buildChart() {
    if (_allSessions.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'No session data available',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Complete some voice sessions to see your progress',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Chart Title and Type Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Session Performance Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedChartType = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedChartType == 0
                              ? const Color.fromARGB(255, 33, 180, 82)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Line',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedChartType = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedChartType == 1
                              ? const Color.fromARGB(255, 33, 180, 82)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Bar',
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
              ],
            ),
            const SizedBox(height: 10),

            // Index Building Warning
            if (_indexBuilding)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Index is building - showing unsorted data',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Legend
            _buildChartLegend(),
            const SizedBox(height: 10),

            // Chart
            Expanded(
              child: _selectedChartType == 0
                  ? _buildLineChart()
                  : _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          'Correct Words',
          const Color.fromARGB(255, 33, 180, 82),
          _showCorrectWords,
          () {
            setState(() {
              _showCorrectWords = !_showCorrectWords;
            });
          },
        ),
        const SizedBox(width: 15),
        _buildLegendItem(
          'Wrong Words',
          const Color(0xFFF44336),
          _showWrongWords,
          () {
            setState(() {
              _showWrongWords = !_showWrongWords;
            });
          },
        ),
        const SizedBox(width: 15),
        _buildLegendItem(
          'Confidence %',
          const Color(0xFF2196F3),
          _showConfidence,
          () {
            setState(() {
              _showConfidence = !_showConfidence;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(
      String text, Color color, bool isVisible, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isVisible ? color : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: isVisible ? Colors.black87 : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getHorizontalInterval(),
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _allSessions.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'S${value.toInt() + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getHorizontalInterval(),
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        minX: 0,
        maxX:
            _allSessions.length > 0 ? (_allSessions.length - 1).toDouble() : 0,
        minY: 0,
        maxY: _getMaxYValue(),
        lineBarsData: _buildLineBarsData(),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxYValue(),
        minY: 0,
        groupsSpace: 12,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final session = _allSessions[groupIndex];
              final analysis = session['analysis'];
              final wrongWordCount = analysis['wrong_word_count'] ?? 0;
              final totalWords = analysis['total_words'] ?? 1;
              final correctWordCount = totalWords - wrongWordCount;
              final confidence =
                  ((analysis['confidence'] ?? 0.0) * 100).round();

              String text = '';
              switch (rodIndex) {
                case 0:
                  text = 'Correct: $correctWordCount';
                  break;
                case 1:
                  text = 'Wrong: $wrongWordCount';
                  break;
                case 2:
                  text = 'Confidence: $confidence%';
                  break;
              }

              return BarTooltipItem(
                text,
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _allSessions.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'S${value.toInt() + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getHorizontalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        barGroups: _buildBarGroups(),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    List<LineChartBarData> lineBars = [];

    if (_showCorrectWords) {
      lineBars.add(LineChartBarData(
        spots: _allSessions.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final analysis = session['analysis'];
          final wrongWordCount = analysis['wrong_word_count'] ?? 0;
          final totalWords = analysis['total_words'] ?? 1;
          final correctWordCount = totalWords - wrongWordCount;
          return FlSpot(index.toDouble(), correctWordCount.toDouble());
        }).toList(),
        isCurved: true,
        color: const Color.fromARGB(255, 33, 180, 82),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ));
    }

    if (_showWrongWords) {
      lineBars.add(LineChartBarData(
        spots: _allSessions.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final analysis = session['analysis'];
          final wrongWordCount = analysis['wrong_word_count'] ?? 0;
          return FlSpot(index.toDouble(), wrongWordCount.toDouble());
        }).toList(),
        isCurved: true,
        color: const Color(0xFFF44336),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ));
    }

    if (_showConfidence) {
      lineBars.add(LineChartBarData(
        spots: _allSessions.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final analysis = session['analysis'];
          final confidence = ((analysis['confidence'] ?? 0.0) * 100);
          return FlSpot(index.toDouble(), confidence);
        }).toList(),
        isCurved: true,
        color: const Color(0xFF2196F3),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ));
    }

    return lineBars;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return _allSessions.asMap().entries.map((entry) {
      final index = entry.key;
      final session = entry.value;
      final analysis = session['analysis'];
      final wrongWordCount = analysis['wrong_word_count'] ?? 0;
      final totalWords = analysis['total_words'] ?? 1;
      final correctWordCount = totalWords - wrongWordCount;
      final confidence = ((analysis['confidence'] ?? 0.0) * 100);

      List<BarChartRodData> rods = [];

      if (_showCorrectWords) {
        rods.add(BarChartRodData(
          toY: correctWordCount.toDouble(),
          color: const Color.fromARGB(255, 33, 180, 82),
          width: 8,
        ));
      }

      if (_showWrongWords) {
        rods.add(BarChartRodData(
          toY: wrongWordCount.toDouble(),
          color: const Color(0xFFF44336),
          width: 8,
        ));
      }

      if (_showConfidence) {
        rods.add(BarChartRodData(
          toY: confidence,
          color: const Color(0xFF2196F3),
          width: 8,
        ));
      }

      return BarChartGroupData(
        x: index,
        groupVertically: true,
        barRods: rods,
      );
    }).toList();
  }

  double _getMaxYValue() {
    double maxValue = 0;

    for (var session in _allSessions) {
      final analysis = session['analysis'];
      final wrongWordCount = analysis['wrong_word_count'] ?? 0;
      final totalWords = analysis['total_words'] ?? 1;
      final correctWordCount = totalWords - wrongWordCount;
      final confidence = ((analysis['confidence'] ?? 0.0) * 100);

      if (_showCorrectWords && correctWordCount > maxValue) {
        maxValue = correctWordCount.toDouble();
      }
      if (_showWrongWords && wrongWordCount > maxValue) {
        maxValue = wrongWordCount.toDouble();
      }
      if (_showConfidence && confidence > maxValue) {
        maxValue = confidence;
      }
    }

    // Add some padding to the max value
    return maxValue * 1.1;
  }

  double _getHorizontalInterval() {
    double maxY = _getMaxYValue();
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return 25;
  }

  // Build session details list
  Widget _buildSessionDetails() {
    if (_allSessions.isEmpty) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Session Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allSessions.length,
            itemBuilder: (context, index) {
              final session = _allSessions[index];
              final analysis = session['analysis'];
              final wrongWordCount = analysis['wrong_word_count'] ?? 0;
              final totalWords = analysis['total_words'] ?? 1;
              final correctWordCount = totalWords - wrongWordCount;
              final accuracy = ((correctWordCount / totalWords) * 100).round();
              final confidence =
                  ((analysis['confidence'] ?? 0.0) * 100).round();
              final timestamp = session['timestamp'] as Timestamp?;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
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
                  title: Text('Session ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Accuracy: $accuracy% • Confidence: $confidence%'),
                      if (timestamp != null)
                        Text(
                          '${timestamp.toDate().toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMiniStat('C', correctWordCount, Colors.green),
                      const SizedBox(width: 8),
                      _buildMiniStat('W', wrongWordCount, Colors.red),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  double _calculateAverageAccuracy() {
    if (_allSessions.isEmpty) return 0.0;

    double totalAccuracy = 0.0;
    for (var session in _allSessions) {
      final analysis = session['analysis'];
      final wrongWordCount = analysis['wrong_word_count'] ?? 0;
      final totalWords = analysis['total_words'] ?? 1;
      final accuracy = ((totalWords - wrongWordCount) / totalWords * 100);
      totalAccuracy += accuracy;
    }

    return totalAccuracy / _allSessions.length;
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'Performance Results',
          style: TextStyle(
              fontSize: 22,
              color: Color.fromARGB(255, 244, 242, 242),
              fontWeight: FontWeight.bold),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading your performance data...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _getUserSessions,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
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

                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Sessions',
                            _allSessions.length.toString(),
                            Icons.analytics,
                            const Color.fromARGB(255, 33, 180, 82),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Avg. Accuracy',
                            _allSessions.isEmpty
                                ? '0%'
                                : '${_calculateAverageAccuracy().round()}%',
                            Icons.trending_up,
                            const Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Chart
                    _buildChart(),

                    const SizedBox(height: 20),

                    // Session Details
                    _buildSessionDetails(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
