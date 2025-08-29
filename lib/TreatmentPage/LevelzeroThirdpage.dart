import 'package:flutter/material.dart';

class Levelzerothirdpage extends StatefulWidget {
  const Levelzerothirdpage({super.key});

  @override
  State<Levelzerothirdpage> createState() => _LevelzerothirdpageState();
}

class _LevelzerothirdpageState extends State<Levelzerothirdpage> {
  bool isPlaying = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'Third Step',
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular image/GIF container
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 33, 180, 82),
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: isPlaying
                    ? Image.asset(
                        'assets/jif/circular_motion.png',
                        fit: BoxFit.cover,
                        width: 200,
                        height: 200,
                      )
                    : Image.asset(
                        'assets/jif/circular_motion.png',
                        fit: BoxFit.cover,
                        width: 200,
                        height: 200,
                        // This shows the first frame when not playing
                        gaplessPlayback: true,
                      ),
              ),
            ),
            const SizedBox(height: 30),

            // Play button
            Container(
              child: const Text(
                'Third Step Instructions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(137, 17, 17, 17),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Instruction text
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 224, 222, 222),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                ' Rotate the tongue along the lips in a circular motion. Do this for 5 times in the clockwise and 5 in anticlockwise.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}