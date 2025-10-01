import 'package:flutter/material.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'About Us',
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

                // App Logo/Image Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
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
                      // App Image
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              spreadRadius: 0,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/treatmentimg.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.health_and_safety,
                                  size: 60,
                                  color: Color(0xFF4CAF50),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Aphasia Speech Therapy',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your Companion in Speech Recovery',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // About App Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'About Our App',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Aphasia Speech Therapy is a comprehensive mobile application designed to support individuals with aphasia in their journey towards improved communication and speech recovery.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Our app provides personalized speech therapy exercises, real-time voice analysis, and progress tracking to help users regain their communication abilities. With advanced AI-powered grammar analysis and voice recognition, we offer instant feedback and customized treatment plans.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Whether you\'re dealing with expressive aphasia, receptive aphasia, or global aphasia, our app adapts to your specific needs and provides a supportive environment for practice and improvement.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Features Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.star_outline,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Key Features',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureItem(
                        'Voice Recording & Analysis',
                        'Record your speech and get instant grammar analysis',
                        Icons.mic_outlined,
                      ),
                      const SizedBox(height: 15),
                      _buildFeatureItem(
                        'Progress Tracking',
                        'Monitor your improvement with detailed analytics',
                        Icons.analytics_outlined,
                      ),
                      const SizedBox(height: 15),
                      _buildFeatureItem(
                        'Personalized Exercises',
                        'Custom treatment plans based on your progress',
                        Icons.assignment_outlined,
                      ),
                      const SizedBox(height: 15),
                      _buildFeatureItem(
                        'Multi-level Therapy',
                        'Structured levels from beginner to advanced',
                        Icons.layers_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Mission Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Our Mission',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.health_and_safety_outlined,
                              color: Color(0xFF4CAF50),
                              size: 40,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Empowering individuals with aphasia to regain their voice and confidence through innovative technology and compassionate care.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2E7D32),
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4CAF50),
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
