import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TreatmentOnePage extends StatefulWidget {
  const TreatmentOnePage({super.key});

  @override
  State<TreatmentOnePage> createState() => _TreatmentOnePageState();
}

class _TreatmentOnePageState extends State<TreatmentOnePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // List of vowels with their corresponding audio and animation paths
  final List<Map<String, String>> vowels = [
    {
      'letter': 'A',
      'audioPath': 'assets/voice/a.mp3',
      'animationPath': 'assets/animations/A.gif'
    },
    {
      'letter': 'E',
      'audioPath': 'assets/voice/e.mp3',
      'animationPath': 'assets/animations/E.gif'
    },
    {
      'letter': 'I',
      'audioPath': 'assets/voice/i.mp3',
      'animationPath': 'assets/animations/I.gif'
    },
    {
      'letter': 'O',
      'audioPath': 'assets/voice/o.mp3',
      'animationPath': 'assets/animations/O.gif'
    },
    {
      'letter': 'U',
      'audioPath': 'assets/voice/u.mp3',
      'animationPath': 'assets/animations/U.gif'
    },
  ];

  String? _currentAnimationPath; // Track current animation

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Play vowel pronunciation and show animation
  Future<void> _playVowelSound(String audioPath, String animationPath) async {
    try {
      setState(() {
        _currentAnimationPath = animationPath; // Set current animation
      });

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
          'Level 1',
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

              // Lip Animation Display
              Container(
                height: 200, // Adjust height as needed
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _currentAnimationPath != null
                    ? Image.asset(
                        _currentAnimationPath!,
                        fit: BoxFit.contain,
                      )
                    : const Center(
                        child: Text(
                          'Tap a vowel to see pronunciation',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
              ),

              // Vowel buttons
              Expanded(
                child: ListView.builder(
                  itemCount: vowels.length,
                  itemBuilder: (context, index) {
                    final vowel = vowels[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _playVowelSound(
                              vowel['audioPath']!, vowel['animationPath']!),
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  vowel['letter']!,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    color: Color(0xFF333333),
                                  ),
                                ),
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
