import 'package:flutter/material.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:audioplayers/audioplayers.dart';

class TreatmentSixPage extends StatefulWidget {
  final String description;
  const TreatmentSixPage({super.key, this.description = ''});

  @override
  State<TreatmentSixPage> createState() => _TreatmentSixPageState();
}

class _TreatmentSixPageState extends State<TreatmentSixPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<int, bool> playingStates = {}; // Track playing state for each item
  Map<int, Duration> durations = {}; // Track duration for each item
  Map<int, Duration> positions = {}; // Track position for each item

  List<Product> productList = [
    Product('musick/Shape_of_You.mp3', 'Sisira Kumara', 100,
        " I'm highly motivated 24-year-old Computer Science undergraduate with a passion for full-stack development. Currently, we are developing a PDF converter app, showcasing skills in Flutter and Dart. Eager to refine our skills and make a meaningful impact, I'm aims to leverage our technical knowledge in professional settings.We hope that this app give you special features."),
    Product('musick/Shape_of_You.mp3', 'SS Gamage', 100,
        " I'm highly motivated 25-year-old Computer Science undergraduate with a passion for full-stack development. Currently, we are developing a PDF converter app, showcasing skills in Flutter and Dart. Eager to refine our skills and make a meaningful impact, I'm aims to leverage our technical knowledge in professional settings.We hope that this app give you special features."),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize playing states
    for (int i = 0; i < productList.length; i++) {
      playingStates[i] = false;
      durations[i] = Duration.zero;
      positions[i] = Duration.zero;
    }

    // Listen to audio player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      // Update UI when player state changes
      setState(() {});
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        // Update position for currently playing item
        int? currentIndex = _getCurrentPlayingIndex();
        if (currentIndex != null) {
          positions[currentIndex] = position;
        }
      });
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        // Update duration for currently playing item
        int? currentIndex = _getCurrentPlayingIndex();
        if (currentIndex != null) {
          durations[currentIndex] = duration;
        }
      });
    });
  }

  int? _getCurrentPlayingIndex() {
    return playingStates.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .firstOrNull;
  }

  Future<void> _playAudio(String audioPath, int index) async {
    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Reset all playing states
      for (int i = 0; i < productList.length; i++) {
        playingStates[i] = false;
      }

      // Play the selected audio
      await _audioPlayer.play(AssetSource(audioPath));

      setState(() {
        playingStates[index] = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  Future<void> _stopAudio(int index) async {
    try {
      await _audioPlayer.stop();
      setState(() {
        playingStates[index] = false;
        positions[index] = Duration.zero;
      });
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> _pauseAudio(int index) async {
    try {
      await _audioPlayer.pause();
      setState(() {
        playingStates[index] = false;
      });
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> _resumeAudio(int index) async {
    try {
      await _audioPlayer.resume();
      setState(() {
        playingStates[index] = true;
      });
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'Level 6',
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
            _audioPlayer.stop(); // Stop audio when leaving page
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
      body: SizedBox(
        height: 730,
        child: ScrollSnapList(
          itemBuilder: _buildListItem,
          itemCount: productList.length,
          itemSize: 350,
          onItemFocus: (index) {},
          dynamicItemSize: true,
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    Product product = productList[index];
    bool isPlaying = playingStates[index] ?? false;
    Duration duration = durations[index] ?? Duration.zero;
    Duration position = positions[index] ?? Duration.zero;

    return SizedBox(
      width: 350,
      height: 250,
      child: Card(
        elevation: 12,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Column(
            children: [
              // Audio Player UI replacing the image
              Container(
                width: 230,
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade100,
                      Colors.blue.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Music icon
                    Icon(
                      Icons.music_note,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),

                    // Song title (extracted from file path)
                    Text(
                      product.audioPath
                          .split('/')
                          .last
                          .replaceAll('.mp3', '')
                          .replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Progress bar
                    if (duration.inSeconds > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: duration.inSeconds > 0
                                  ? position.inSeconds / duration.inSeconds
                                  : 0.0,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stop button
                        IconButton(
                          onPressed: isPlaying ? () => _stopAudio(index) : null,
                          icon: const Icon(Icons.stop),
                          color: Colors.white,
                          iconSize: 30,
                        ),
                        const SizedBox(width: 20),
                        // Play/Pause button
                        IconButton(
                          onPressed: () {
                            if (isPlaying) {
                              _pauseAudio(index);
                            } else {
                              // Check if this audio was paused or needs to start fresh
                              if (positions[index]?.inSeconds == 0) {
                                _playAudio(product.audioPath, index);
                              } else {
                                _resumeAudio(index);
                              }
                            }
                          },
                          icon:
                              Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                          color: Colors.white,
                          iconSize: 40,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      'BSc (Hons) in Computer Science',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        product.description,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) => const FeedbackBord(
                        //             title: '',
                        //           )),
                        // );
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          disabledForegroundColor:
                              Colors.grey.withOpacity(0.38),
                          shadowColor: Colors.red,
                          elevation: 5,
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      child: const Text('Get in Touch'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Product {
  final String audioPath; // Changed from imagePath to audioPath
  final String title;
  final double cost;
  final String description;

  Product(this.audioPath, this.title, this.cost, this.description);
}
