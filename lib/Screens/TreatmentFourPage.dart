import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TreatmentFourPage extends StatefulWidget {
  const TreatmentFourPage({super.key});

  @override
  State<TreatmentFourPage> createState() => _TreatmentFourPageState();
}

class _TreatmentFourPageState extends State<TreatmentFourPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // List of animals with their corresponding audio file paths and images
  final List<Map<String, String>> animals = [
    {
      'name': 'Dog',
      'audioPath': 'assets/voice/dog.mp3',
      'imagePath': 'assets/images/dog.png',
    },
    {
      'name': 'Chicken',
      'audioPath': 'assets/voice/chicken.mp3',
      'imagePath': 'assets/images/chicken.png',
    },
    {
      'name': 'Bird',
      'audioPath': 'assets/voice/bird.mp3',
      'imagePath': 'assets/images/bird.png',
    },
    {
      'name': 'Sheep',
      'audioPath': 'assets/voice/sheep.mp3',
      'imagePath': 'assets/images/sheep.png',
    },
    {
      'name': 'Goat',
      'audioPath': 'assets/voice/goat.mp3',
      'imagePath': 'assets/images/goat.png',
    },
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Play animal pronunciation
  Future<void> _playAnimalSound(String audioPath) async {
    try {
      // Convert "assets/voice/dog.mp3" → "voice/dog.mp3"
      final assetPath = audioPath.replaceFirst('assets/', '');

      await _audioPlayer.setSourceAsset(assetPath);
      await _audioPlayer.resume();
    } catch (e) {
      _showSnackBar('Error playing sound: $e');
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
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'Level 4',
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
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Instruction text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Do the sound for 10 rounds with the sound repeated 3 times in each round.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Animal buttons
              Expanded(
                child: ListView.builder(
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    final name = animal['name'] ?? 'Unknown';
                    final audioPath = animal['audioPath'];
                    final imagePath = animal['imagePath'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (audioPath != null && audioPath.isNotEmpty) {
                              _playAnimalSound(audioPath);
                            } else {
                              _showSnackBar('No audio file for $name');
                            }
                          },
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                // Animal image
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: (imagePath != null &&
                                            imagePath.isNotEmpty)
                                        ? Image.asset(
                                            imagePath,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              // Fallback if image doesn't exist
                                              return const Icon(
                                                Icons.pets,
                                                size: 30,
                                                color: Colors.grey,
                                              );
                                            },
                                          )
                                        : const Icon(
                                            Icons.pets,
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Animal name
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                ),
                                // Play button
                                const Icon(
                                  Icons.play_arrow,
                                  size: 30,
                                  color: Color(0xFF666666),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
