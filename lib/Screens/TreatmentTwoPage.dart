import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';


class TreatmentTwoPage extends StatefulWidget {
  const TreatmentTwoPage({super.key});

  @override
  State<TreatmentTwoPage> createState() => _TreatmentTwoPageState();
}

class _TreatmentTwoPageState extends State<TreatmentTwoPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  

  // List of vowels with their corresponding audio file paths
  final List<Map<String, String>> vowels = [
    {'letter': 'A', 'audioPath': 'assets/voice/a.mp3'},
    {'letter': 'B', 'audioPath': 'assets/voice/b.mp3'},
    {'letter': 'C', 'audioPath': 'assets/voice/c.mp3'},
    {'letter': 'D', 'audioPath': 'assets/voice/d.mp3'},
    {'letter': 'E', 'audioPath': 'assets/voice/e.mp3'},
    {'letter': 'F', 'audioPath': 'assets/voice/f.mp3'},
    {'letter': 'G', 'audioPath': 'assets/voice/g.mp3'},
    {'letter': 'H', 'audioPath': 'assets/voice/h.mp3'},
    {'letter': 'I', 'audioPath': 'assets/voice/i.mp3'},
    {'letter': 'J', 'audioPath': 'assets/voice/j.mp3'},
    {'letter': 'K', 'audioPath': 'assets/voice/k.mp3'},
    {'letter': 'L', 'audioPath': 'assets/voice/l.mp3'},
    {'letter': 'M', 'audioPath': 'assets/voice/m.mp3'},
    {'letter': 'N', 'audioPath': 'assets/voice/n.mp3'},
    {'letter': 'O', 'audioPath': 'assets/voice/o.mp3'},
    {'letter': 'P', 'audioPath': 'assets/voice/p.mp3'},
    {'letter': 'Q', 'audioPath': 'assets/voice/q.mp3'},
    {'letter': 'R', 'audioPath': 'assets/voice/r.mp3'},
    {'letter': 'S', 'audioPath': 'assets/voice/s.mp3'},
    {'letter': 'T', 'audioPath': 'assets/voice/t.mp3'},
    {'letter': 'U', 'audioPath': 'assets/voice/u.mp3'},
    {'letter': 'V', 'audioPath': 'assets/voice/v.mp3'},
    {'letter': 'W', 'audioPath': 'assets/voice/w.mp3'},
    {'letter': 'X', 'audioPath': 'assets/voice/x.mp3'},
    {'letter': 'Y', 'audioPath': 'assets/voice/y.mp3'},
    {'letter': 'Z', 'audioPath': 'assets/voice/z.mp3'},
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Play vowel pronunciation
  Future<void> _playVowelSound(String audioPath) async {
    try {
      // Convert "assets/voice/a.mp3" → "voice/a.mp3"
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
          'Level 2',
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
                  'Do the sound for 10 rounds with the sound repeated 3 times in each rounds.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
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
                          onTap: () => _playVowelSound(vowel['audioPath']!),
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

