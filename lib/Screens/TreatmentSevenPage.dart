import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';

class TreatmentSevenPage extends StatefulWidget {
  const TreatmentSevenPage({super.key});

  @override
  State<TreatmentSevenPage> createState() => _TreatmentSevenPageState();
}

class _TreatmentSevenPageState extends State<TreatmentSevenPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingAudio;
  bool _isUploading = false;
  String? _transcriptionText;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioFileName) async {
    try {
      if (_currentlyPlayingAudio != null) {
        await _audioPlayer.stop();
      }

      setState(() {
        _currentlyPlayingAudio = audioFileName;
      });

      await _audioPlayer.play(AssetSource('voice/$audioFileName'));

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _currentlyPlayingAudio = null;
        });
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _currentlyPlayingAudio = null;
      });
    }
  }

  Future<void> _uploadVoiceRecord() async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Request permissions first
      bool hasPermission = await _requestPermissions();

      if (!hasPermission) {
        setState(() {
          _isUploading = false;
        });
        _showErrorDialog(
            'Permissions are required to upload voice records. Please grant the required permissions in app settings.');
        return;
      }

      // Pick audio file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', '3gp'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File audioFile = File(result.files.single.path!);
        String fileName = result.files.single.name;

        // Show progress dialog
        _showProgressDialog();

        try {
          // Upload to Firebase Storage
          String downloadUrl =
              await _uploadToFirebaseStorage(audioFile, fileName);

          // Convert voice to text using your API
          String transcriptionText = await _convertVoiceToText(audioFile);

          // Save transcription to Firestore
          await _saveTranscriptionToFirestore(
              downloadUrl, transcriptionText, fileName);

          if (mounted) {
            Navigator.pop(context); // Close progress dialog
          }

          setState(() {
            _transcriptionText = transcriptionText;
            _isUploading = false;
          });

          _showSuccessDialog(transcriptionText);
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close progress dialog
          }
          setState(() {
            _isUploading = false;
          });
          _showErrorDialog('Error processing file: $e');
        }
      } else {
        setState(() {
          _isUploading = false;
        });
        // User canceled file picking, no error needed
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog if open
      }
      setState(() {
        _isUploading = false;
      });
      _showErrorDialog('Error uploading file: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      // Request storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.audio,
        if (Platform.isAndroid) Permission.manageExternalStorage,
      ].request();

      // Check if permissions are granted
      bool allGranted = statuses.values.every((status) =>
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited);

      if (!allGranted) {
        // If permissions are permanently denied, open app settings
        bool shouldOpenSettings = statuses.values
            .any((status) => status == PermissionStatus.permanentlyDenied);

        if (shouldOpenSettings && mounted) {
          _showPermissionDialog();
        }

        return false;
      }

      return true;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Storage and audio permissions are required to upload voice records. '
            'Please grant the required permissions in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _uploadToFirebaseStorage(File file, String fileName) async {
    try {
      // Create a reference to Firebase Storage
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String uniqueFileName = '${timestamp}_$fileName';

      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_records')
          .child(uniqueFileName);

      // Upload file
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload to Firebase Storage: $e');
    }
  }

  Future<String> _convertVoiceToText(File audioFile) async {
    try {
      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://voice-tracer-3.onrender.com/transcribe'),
      );

      // Add audio file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
        ),
      );

      // Set timeout and send request
      var streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['transcription'] ??
            jsonResponse['text'] ??
            'No transcription available';
      } else {
        throw Exception(
            'API request failed with status: ${response.statusCode}. Response: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to convert voice to text: $e');
    }
  }

  Future<void> _saveTranscriptionToFirestore(
      String audioUrl, String transcription, String fileName) async {
    try {
      await FirebaseFirestore.instance.collection('voice_transcriptions').add({
        'fileName': fileName,
        'audioUrl': audioUrl,
        'transcription': transcription,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': 'user_id_here', // Replace with actual user ID if available
      });
    } catch (e) {
      throw Exception('Failed to save to Firestore: $e');
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Processing voice record...'),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String transcription) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Voice record uploaded and transcribed successfully!'),
                const SizedBox(height: 10),
                const Text('Transcription:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transcription.isEmpty
                        ? 'No transcription available'
                        : transcription,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'Level 7',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildStepCard(
                    context: context,
                    stepNumber: 1,
                    title: "FIRST QUESTION",
                    description: "What is your name?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "1.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "1.mp3",
                    onTap: () => _playAudio("1.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 2,
                    title: "SECOND QUESTION",
                    description: "Where are you from?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "2.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "2.mp3",
                    onTap: () => _playAudio("2.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 3,
                    title: "THIRD QUESTION",
                    description: "Do you have allergies?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "3.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "3.mp3",
                    onTap: () => _playAudio("3.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 4,
                    title: "FOURTH QUESTION",
                    description: "Are you currently taking medication?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "4.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "4.mp3",
                    onTap: () => _playAudio("4.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 5,
                    title: "FIFTH QUESTION",
                    description: "Do you smoke?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "5.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "5.mp3",
                    onTap: () => _playAudio("5.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 6,
                    title: "SIXTH QUESTION",
                    description: "Do you drink alcohol?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "6.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "6.mp3",
                    onTap: () => _playAudio("6.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 7,
                    title: "SEVENTH QUESTION",
                    description: "Do you exercise?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "7.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "7.mp3",
                    onTap: () => _playAudio("7.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 8,
                    title: "EIGHTH QUESTION",
                    description: "Are you diabetic?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "8.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "8.mp3",
                    onTap: () => _playAudio("8.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 9,
                    title: "NINTH QUESTION",
                    description: "Is your vision blurry?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "9.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "9.mp3",
                    onTap: () => _playAudio("9.mp3"),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 10,
                    title: "TENTH QUESTION",
                    description: "Do you have sisters or brothers?",
                    imagePath: "assets/images/treatmentimg.png",
                    audioFileName: "10.mp3",
                    isHighlighted: true,
                    isPlaying: _currentlyPlayingAudio == "10.mp3",
                    onTap: () => _playAudio("10.mp3"),
                  ),
                  const SizedBox(height: 20),
                  // Upload Button
                  _buildUploadButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Upload icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.cloud_upload,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            // Title and description
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "UPLOAD VOICE RECORD",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Upload your voice record for transcription",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Upload button
            GestureDetector(
              onTap: _isUploading ? null : _uploadVoiceRecord,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isUploading ? Colors.grey : const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required int stepNumber,
    required String title,
    required String description,
    required String imagePath,
    required String audioFileName,
    required VoidCallback onTap,
    bool isHighlighted = false,
    bool isPlaying = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Step number indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Profile image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Play button
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPlaying ? Colors.orange : const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                  border: isHighlighted && stepNumber == 1
                      ? Border.all(color: Colors.yellow, width: 3)
                      : null,
                ),
                child: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
