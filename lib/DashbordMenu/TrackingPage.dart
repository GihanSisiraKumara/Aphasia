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

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();

    return microphoneStatus == PermissionStatus.granted &&
        storageStatus == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      _showSnackBar('Microphone permission is required');
      return;
    }

    try {
      // Get directory for storing the recording
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
      });
    } catch (e) {
      _showSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      // Use the path we stored when starting, or the returned path
      final finalPath = path ?? _recordingPath;

      if (finalPath != null) {
        await _processVoiceRecording(finalPath);
      }
    } catch (e) {
      _showSnackBar('Failed to stop recording: $e');
    }
  }

  Future<void> _processVoiceRecording(String audioPath) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Upload audio file to Firebase Storage
      final audioFile = File(audioPath);
      final storageRef = FirebaseStorage.instance.ref().child(
          'voice_recordings/${DateTime.now().millisecondsSinceEpoch}.aac');

      final uploadTask = await storageRef.putFile(audioFile);
      final audioUrl = await uploadTask.ref.getDownloadURL();

      // Step 2: Send audio URL to your Python backend for speech-to-text
      final transcribedText = await _transcribeAudio(audioUrl);

      // Step 3: Save transcribed text to Firestore
      await _saveTranscriptionToFirestore(transcribedText, audioUrl);

      setState(() {
        _transcribedText = transcribedText;
        _isProcessing = false;
      });

      _showSnackBar('Voice recording processed successfully!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Failed to process recording: $e');
    }
  }

  Future<String> _transcribeAudio(String audioUrl) async {
    // Updated to use your local Python backend
    const String pythonBackendUrl = 'https://voice-tracer-3.onrender.com/transcribe';

    try {
      final response = await http.post(
        Uri.parse(pythonBackendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'audio_url': audioUrl}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['transcription'] ?? 'No transcription available';
      } else {
        throw Exception('Failed to transcribe audio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calling transcription service: $e');
    }
  }

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
      throw Exception('Failed to save to Firestore: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Treatment Eight"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "This is Treatment Eight Page",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),

            // Recording Button
            ElevatedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : _isRecording
                      ? _stopRecording
                      : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label:
                  Text(_isRecording ? 'Stop Recording' : 'Upload your voice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Processing indicator
            if (_isProcessing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Processing voice recording...'),
                ],
              ),

            // Show transcribed text
            if (_transcribedText != null && !_isProcessing) ...[
              const SizedBox(height: 20),
              const Text(
                'Transcribed Text:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _transcribedText!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
