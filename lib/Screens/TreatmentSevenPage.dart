import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TreatmentSevenPage extends StatefulWidget {
  const TreatmentSevenPage({super.key});

  @override
  State<TreatmentSevenPage> createState() => _TreatmentSevenPageState();
}

class _TreatmentSevenPageState extends State<TreatmentSevenPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingAudio; // Track which audio file is currently playing

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioFileName) async {
    try {
      // Stop currently playing audio if any
      if (_currentlyPlayingAudio != null) {
        await _audioPlayer.stop();
      }

      setState(() {
        _currentlyPlayingAudio = audioFileName;
      });

      // Play the specific audio file
      await _audioPlayer.play(AssetSource('voice/$audioFileName'));

      // Reset when audio completes
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
                    audioFileName: "1.mp3", // Direct audio file name
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
                ],
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
    required String audioFileName, // New parameter for audio file name
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
