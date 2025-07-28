import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8), // Light green background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Status bar with time and battery
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '9:41',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      // Signal bars
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 6,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 8,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      // WiFi icon
                      const Icon(Icons.wifi, size: 18),
                      const SizedBox(width: 4),
                      // Battery icon
                      Container(
                        width: 22,
                        height: 12,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 16,
                              height: 8,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              top: 4,
                              child: Container(
                                width: 2,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(1),
                                    bottomRight: Radius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // App title
              const Text(
                'Aphasia',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 60),

              // Lottie Animation
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(
                        0xFFD4EDD4), // Slightly darker green for illustration background
                    borderRadius: BorderRadius.all(Radius.circular(120)),
                  ),
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/prueba - doctores-freepik.json',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title and description
              const Text(
                'Begin Your Treatments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Lorem Ipsum is simply dummy text\nof the printing and typesetting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              // Page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Bottom buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // Handle skip action
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle next action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloud(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    );
  }

  Widget _buildPerson(Color shirtColor, Color hairColor,
      {required bool isCustomer}) {
    return SizedBox(
      width: 80,
      height: 100,
      child: Stack(
        children: [
          // Body
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 40,
              height: 60,
              decoration: BoxDecoration(
                color: shirtColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),

          // Head
          Positioned(
            top: 10,
            left: 25,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDBB5), // Skin color
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Hair
          Positioned(
            top: 5,
            left: isCustomer ? 20 : 22,
            child: Container(
              width: isCustomer ? 40 : 36,
              height: 25,
              decoration: BoxDecoration(
                color: hairColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isCustomer
                      ? const Radius.circular(15)
                      : const Radius.circular(8),
                  bottomRight: isCustomer
                      ? const Radius.circular(15)
                      : const Radius.circular(8),
                ),
              ),
            ),
          ),

          // Arms
          if (isCustomer) ...[
            // Left arm reaching out
            Positioned(
              top: 35,
              left: 5,
              child: Container(
                width: 25,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDBB5),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ] else ...[
            // Right arm reaching out
            Positioned(
              top: 35,
              right: 5,
              child: Container(
                width: 25,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDBB5),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ],

          // Legs
          Positioned(
            bottom: 0,
            left: 22,
            child: Container(
              width: 12,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF4A4A4A), // Dark pants
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 36,
            child: Container(
              width: 12,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF4A4A4A), // Dark pants
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
