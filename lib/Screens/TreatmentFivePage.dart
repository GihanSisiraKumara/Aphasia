import 'package:flutter/material.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:audioplayers/audioplayers.dart';

class TreatmentFivePage extends StatefulWidget {
  final String description;
  const TreatmentFivePage({super.key, this.description = ''});

  @override
  State<TreatmentFivePage> createState() => _TreatmentFivePageState();
}

class _TreatmentFivePageState extends State<TreatmentFivePage> {
  List<Product> productList = [
    Product(
        'assets/images/play_ground.jpg',
        'Play Ground',
        100,
        " There are five people in the picture. Two boys are sitting on swings. A woman in a white dress is standing between the boys. She looks happy and is holding one swing chain. In the background, two people are sitting on a bench. The scene is outdoors on green grass. The sky is blue with some clouds. It appears to be a sunny day in a park or playground.",
        'play_ground.mp3'),
    Product(
        'assets/images/dog.png',
        'SS Gamage',
        100,
        " I'm highly motivated 25-year-old Computer Science undergraduate with a passion for full-stack development. Currently, we are developing a PDF converter app, showcasing skills in Flutter and Dart. Eager to refine our skills and make a meaningful impact, I'm aims to leverage our technical knowledge in professional settings.We hope that this app give you special features.",
        'gamage.mp3'),
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentlyPlayingIndex;
  bool _isPlaying = false;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.stopped || state == PlayerState.completed) {
            _currentlyPlayingIndex = null;
          }
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingIndex = null;
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  Future<void> _playAudio(String audioFileName, int index) async {
    try {
      if (_isPlaying && _currentlyPlayingIndex == index) {
        // If clicking the same audio that's playing, stop it
        await _audioPlayer.stop();
        return;
      }

      // Stop any currently playing audio
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      // Play the new audio - using just the filename since we'll put files in assets/voice/
      await _audioPlayer.play(AssetSource('voice/$audioFileName'));

      setState(() {
        _currentlyPlayingIndex = index;
        _isPlaying = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
      _showErrorSnackBar('Could not play audio: $audioFileName');
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentlyPlayingIndex = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
          'Level 5',
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
    bool isCurrentPlaying = _currentlyPlayingIndex == index;
    bool isThisPlaying = isCurrentPlaying && _isPlaying;

    return SizedBox(
      width: 350,
      height: 250,
      child: Card(
        elevation: 12,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
                child: Image.asset(
                  product.imagePath,
                  fit: BoxFit.cover,
                  width: 230,
                  height: 270,
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
                      'Try to describe the image',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (isThisPlaying) {
                              _stopAudio();
                            } else {
                              _playAudio(product.audioPath, index);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                isThisPlaying ? Colors.red : Colors.blue,
                            elevation: 5,
                            textStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          icon: Icon(
                            isThisPlaying ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(
                            isThisPlaying ? 'Stop Audio' : 'Play As Audio',
                          ),
                        ),
                        if (isThisPlaying) ...[
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _pauseAudio,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.orange,
                              elevation: 5,
                              textStyle: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                          ),
                        ],
                      ],
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
  final String imagePath;
  final String title;
  final double cost;
  final String description;
  final String audioPath;

  Product(
      this.imagePath, this.title, this.cost, this.description, this.audioPath);
}
