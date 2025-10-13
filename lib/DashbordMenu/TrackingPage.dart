import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordingPath;
  String? _transcribedText;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;
  String? _currentUserId;
  String? _currentUserEmail;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
        _currentUserId = user.uid;
        _currentUserEmail = user.email;
      });
    } else {
      setState(() {
        _errorMessage = 'User not authenticated. Please log in again.';
      });
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    try {
      final micStatus = await Permission.microphone.status;

      if (!micStatus.isGranted) {
        final micResult = await Permission.microphone.request();
        if (!micResult.isGranted) {
          setState(() {
            _errorMessage =
                'Microphone permission is required to record audio. '
                'Please grant microphone permission in your device settings.';
          });
          return false;
        }
      }

      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Permission request failed: $e';
      });
      return false;
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check if user is authenticated
      if (_currentUser == null) {
        _getCurrentUser();
        if (_currentUser == null) {
          setState(() {
            _errorMessage = 'Please log in to record audio.';
          });
          return;
        }
      }

      setState(() {
        _errorMessage = null;
        _transcribedText = null;
        _analysisResult = null;
      });

      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        return;
      }

      if (await _audioRecorder.isRecording()) {
        await _stopRecording();
        return;
      }

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingPath = filePath;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start recording: ${e.toString()}';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      final finalPath = path ?? _recordingPath;

      if (finalPath != null) {
        await _processVoiceRecording(finalPath);
      } else {
        setState(() {
          _errorMessage = 'Recording path is null';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to stop recording: ${e.toString()}';
      });
    }
  }

  Future<void> _processVoiceRecording(String audioPath) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Check authentication again before processing
      if (_currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Verify file exists and has content
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Recorded file does not exist');
      }

      final fileSize = await audioFile.length();
      if (fileSize == 0) {
        throw Exception('Recorded file is empty');
      }

      // Step 1: Upload audio file to Firebase Storage
      final String fileName =
          'recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_recordings')
          .child(_currentUserId!)
          .child(fileName);

      print('Uploading file to: voice_recordings/${_currentUserId!}/$fileName');

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(
        audioFile,
        SettableMetadata(
          contentType: 'audio/aac',
          customMetadata: {
            'userId': _currentUserId!,
            'userEmail': _currentUserEmail ?? '',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
            'Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      // Wait for upload to complete
      final TaskSnapshot uploadSnapshot = await uploadTask;

      if (uploadSnapshot.state == TaskState.success) {
        print('Upload completed successfully');
      } else {
        throw Exception('Upload failed with state: ${uploadSnapshot.state}');
      }

      final String audioUrl = await uploadSnapshot.ref.getDownloadURL();
      print('Audio URL: $audioUrl');

      // Step 2: Send audio URL to your Python backend for speech-to-text
      final String transcribedText = await _transcribeAudio(audioUrl);

      // Step 3: Analyze the transcribed text for grammar errors
      final Map<String, dynamic> analysisResult =
          await _analyzeText(transcribedText);

      // Step 4: Save transcribed text and analysis to Firestore WITH USER ID
      await _saveToFirestore(transcribedText, audioUrl, analysisResult);

      setState(() {
        _transcribedText = transcribedText;
        _analysisResult = analysisResult;
        _isProcessing = false;
        _errorMessage = null;
      });

      _showSnackBar('Voice recording processed and analyzed successfully!');
    } catch (e) {
      print('Error in _processVoiceRecording: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process recording: ${e.toString()}';
      });
    }
  }

  Future<Map<String, dynamic>> _analyzeText(String text) async {
    const String analysisUrl =
        'https://text-analysis-backend-4.onrender.com/analyze-text';

    final timeouts = [
      const Duration(seconds: 45),
      const Duration(seconds: 60),
      const Duration(seconds: 90),
    ];

    for (int attempt = 0; attempt < timeouts.length; attempt++) {
      try {
        print(
            'Text analysis attempt ${attempt + 1} with timeout: ${timeouts[attempt]}');

        final response = await http
            .post(
              Uri.parse(analysisUrl),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'text': text}),
            )
            .timeout(timeouts[attempt]);

        if (response.statusCode == 200) {
          print('Text analysis successful');
          return json.decode(response.body);
        } else {
          print(
              'Text analysis error: ${response.statusCode} - ${response.body}');
          throw Exception(
              'Analysis failed with status: ${response.statusCode}');
        }
      } on TimeoutException {
        print(
            'Text analysis attempt ${attempt + 1} timed out after ${timeouts[attempt]}');
        if (attempt == timeouts.length - 1) {
          throw TimeoutException(
              'Text analysis timed out after ${attempt + 1} attempts');
        }
        await Future.delayed(Duration(seconds: 5 * (attempt + 1)));
      } catch (e) {
        print('Text analysis attempt ${attempt + 1} failed: $e');
        if (attempt == timeouts.length - 1) {
          throw Exception('Text analysis error: $e');
        }
        await Future.delayed(Duration(seconds: 5 * (attempt + 1)));
      }
    }

    throw Exception('All text analysis attempts failed');
  }

  Future<String> _transcribeAudio(String audioUrl) async {
    const String pythonBackendUrl =
        'https://voice-tracer-3.onrender.com/transcribe';

    final timeouts = [
      const Duration(seconds: 45),
      const Duration(seconds: 60),
      Duration(seconds: 90)
    ];

    for (int attempt = 0; attempt < timeouts.length; attempt++) {
      try {
        print(
            'Transcription attempt ${attempt + 1} with timeout: ${timeouts[attempt]}');

        final response = await http
            .post(
              Uri.parse(pythonBackendUrl),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'audio_url': audioUrl}),
            )
            .timeout(timeouts[attempt]);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final transcription =
              data['transcription'] ?? 'No transcription available';
          print(
              'Transcription successful: ${transcription.substring(0, min(50, transcription.length))}...');
          return transcription;
        } else {
          print('Backend error: ${response.statusCode} - ${response.body}');
          throw Exception(
              'Backend returned status code: ${response.statusCode}');
        }
      } on TimeoutException {
        print('Attempt ${attempt + 1} timed out after ${timeouts[attempt]}');
        if (attempt == timeouts.length - 1) {
          throw TimeoutException(
              'Transcription request timed out after ${attempt + 1} attempts');
        }
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } on http.ClientException catch (e) {
        throw Exception('Network error: ${e.message}');
      } catch (e) {
        throw Exception('Transcription error: ${e.toString()}');
      }
    }

    throw Exception('All transcription attempts failed');
  }

  int min(int a, int b) => a < b ? a : b;

  // UPDATED: Save with user ID
  Future<void> _saveToFirestore(String transcription, String audioUrl,
      Map<String, dynamic> analysis) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('voice_transcriptions').add({
        'user_id': _currentUserId,
        'user_email': _currentUserEmail,
        'transcription': transcription,
        'audio_url': audioUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'treatment_page': 'Treatment Eight',
        'analysis_result': analysis,
      });

      print('Successfully saved to Firestore');
    } catch (e) {
      print('Error saving to Firestore: $e');
      throw Exception('Failed to save to Firestore: ${e.toString()}');
    }
  }

  Widget _buildAnalysisChart() {
    if (_analysisResult == null) return Container();

    final wrongWordCount = _analysisResult!['wrong_word_count'] ?? 0;
    final totalWords = _analysisResult!['total_words'] ?? 1;
    final correctWordCount = totalWords - wrongWordCount;
    final confidence = (_analysisResult!['confidence'] ?? 0.0) * 100;
    final correctedSentence = _analysisResult!['corrected_sentence'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Grammar Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pie Chart
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF4CAF50),
                          value: correctWordCount.toDouble(),
                          title: '$correctWordCount',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFF44336),
                          value: wrongWordCount.toDouble(),
                          title: '$wrongWordCount',
                          radius: 45,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Correct Words', const Color(0xFF4CAF50),
                          correctWordCount),
                      const SizedBox(height: 08),
                      _buildLegendItem('Wrong Words', const Color(0xFFF44336),
                          wrongWordCount),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${confidence.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const Text(
                              'Confidence',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1976D2),
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

          const SizedBox(height: 20),

          // Analysis Summary
          if (_analysisResult!['analysis_summary'] != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFF8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8F5E8),
                  width: 1,
                ),
              ),
              child: Text(
                _analysisResult!['analysis_summary'],
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // NEW: Display Full Corrected Sentence
          if (wrongWordCount > 0 && correctedSentence.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC8E6C9),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Full Corrected Sentence:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          correctedSentence,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2E7D32),
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

          // Corrections List
          if (_analysisResult!['corrections'] != null &&
              (_analysisResult!['corrections'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Detailed Corrections:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            ...(_analysisResult!['corrections'] as List).map((correction) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFECB3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.auto_fix_high,
                        size: 16,
                        color: Color(0xFFF57C00),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'From: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '"${correction['original']}"',
                                  style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const TextSpan(text: ' → '),
                                const TextSpan(
                                  text: 'To: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: '"${correction['corrected']}"',
                                  style: const TextStyle(
                                    color: Color(0xFF388E3C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (correction['message'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              correction['message'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      _showSnackBar('Cannot open settings: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearError() {
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'Tracking Your Voice',
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
      body: Container(
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
                const SizedBox(height: 20),

                // Header Card with Animation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                      // Animated Voice Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4CAF50),
                              Color(0xFF81C784),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.graphic_eq : Icons.mic,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Say something!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Let's see how well our speech is now!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF66BB6A),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFFFFCDD2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: Color(0xFFE57373),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Error',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE57373),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                                color: Color(0xFFE57373),
                              ),
                              onPressed: _clearError,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (_errorMessage?.contains('permission') ?? false) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openAppSettings,
                              icon: const Icon(Icons.settings, size: 18),
                              label: const Text('Open Settings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE57373),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Recording Control Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Recording Status Indicator
                      if (_isRecording) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFCDD2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Recording...',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Main Recording Button
                      ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : _isRecording
                                ? _stopRecording
                                : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(_isRecording
                            ? 'Stop Recording'
                            : 'Upload your voice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRecording ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          minimumSize: const Size(200, 50),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Processing Indicator
                if (_isProcessing) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Processing voice recording...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This may take a moment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64B5F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Transcribed Text Result
                if (_transcribedText != null && !_isProcessing) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Transcribed Text',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FFF8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE8F5E8),
                              width: 1,
                            ),
                          ),
                          child: SelectableText(
                            _transcribedText!,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Analysis Chart Section
                if (_analysisResult != null && !_isProcessing) ...[
                  _buildAnalysisChart(),
                  const SizedBox(height: 30),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
