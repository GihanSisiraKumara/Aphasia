import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordingPath;
  String? _transcribedText;
  String? _errorMessage;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    try {
      // For Android 10+ (API 29+), we need to request media permissions instead of storage
      final micStatus = await Permission.microphone.status;

      // Check if microphone permission is granted
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

      // For audio files, we don't need storage permission on newer Android versions
      // The app can use its own temporary directory without storage permission
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
      // Clear previous errors
      setState(() {
        _errorMessage = null;
        _transcribedText = null;
      });

      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        return;
      }

      // Check if recorder is already running
      if (await _audioRecorder.isRecording()) {
        await _stopRecording();
        return;
      }

      // Get directory for storing the recording - uses app's temp directory
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Start recording with path specified
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
      final storageRef = FirebaseStorage.instance.ref().child(
          'voice_recordings/${DateTime.now().millisecondsSinceEpoch}.aac');

      final uploadTask = storageRef.putFile(
        audioFile,
        SettableMetadata(
          contentType: 'audio/aac',
        ),
      );

      final uploadSnapshot = await uploadTask;
      final audioUrl = await uploadSnapshot.ref.getDownloadURL();

      // Step 2: Send audio URL to your Python backend for speech-to-text
      final transcribedText = await _transcribeAudio(audioUrl);

      // Step 3: Save transcribed text to Firestore
      await _saveTranscriptionToFirestore(transcribedText, audioUrl);

      setState(() {
        _transcribedText = transcribedText;
        _isProcessing = false;
        _errorMessage = null;
      });

      _showSnackBar('Voice recording processed successfully!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process recording: ${e.toString()}';
      });
    }
  }

  Future<String> _transcribeAudio(String audioUrl) async {
    const String pythonBackendUrl =
        'https://voice-tracer-3.onrender.com/transcribe';

    // Try multiple attempts with increasing timeouts
    final timeouts = [
      Duration(seconds: 45),
      Duration(seconds: 60),
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
        // Wait before retrying
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

  Future<void> _saveTranscriptionToFirestore(
      String transcription, String audioUrl) async {
    try {
      await FirebaseFirestore.instance.collection('voice_transcriptions').add({
        'transcription': transcription,
        'audio_url': audioUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'treatment_page': 'Treatment Eight',
      });
    } catch (e) {
      throw Exception('Failed to save to Firestore: ${e.toString()}');
    }
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

                // Error Message with improved styling
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

                      // Main Recording Button (keeping your existing design)
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

                // Processing Indicator with improved styling
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

                // Transcribed Text Result with improved styling
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
