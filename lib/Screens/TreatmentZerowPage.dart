import 'package:flutter/material.dart';

class TreatmentZerowPage extends StatelessWidget {
  const TreatmentZerowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 250, 251),
        centerTitle: true,
        title: const Text(
          'Level 0',
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
            // Steps list
            Expanded(
              child: ListView(
                children: [
                  _buildStepCard(
                    context: context,
                    stepNumber: 1,
                    title: "FIRST STEP",
                    description: "Click to navigate first step instructions",
                    imagePath:
                        "assets/images/treatmentimg.png", // Your image_1.png
                    isHighlighted: true, // Blue highlight for first step
                    onTap: () {
                      Navigator.pushNamed(context, '/levelZeroFirst');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 2,
                    title: "SECOND STEP",
                    description: "Click to navigate second step instructions",
                    imagePath: "assets/images/treatmentimg.png",
                    isHighlighted: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/levelZeroSecond');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 3,
                    title: "THIRD STEP",
                    description: "Click to navigate third step instructions",
                    imagePath: "assets/images/treatmentimg.png",
                    isHighlighted: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/levelZeroThird');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 4,
                    title: "FOURTH STEP",
                    description: "Click to navigate fourth step instructions",
                    imagePath: "assets/images/treatmentimg.png",
                    isHighlighted: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/levelZeroFourth');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 5,
                    title: "FIFTH STEP",
                    description: "Click to navigate fifth step instructions",
                    imagePath: "assets/images/treatmentimg.png",
                    isHighlighted: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/levelZeroFifth');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 6,
                    title: "SIXTH STEP",
                    description: "Click to navigate sixth step instructions",
                    imagePath: "assets/images/treatmentimg.png",
                    isHighlighted: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/levelZeroSixth');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 7,
                    title: "SEVENTH STEP",
                    description: "Click to navigate seventh step instructions",
                    imagePath: "assets/images/treatmentimg.png",
                    isHighlighted: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/levelZeroSeventh');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context: context,
                    stepNumber: 8,
                    title: "EIGHTH STEP",
                    description: "Click to navigate eighth step instructions",
                    imagePath: "assets/images/treatmentimg.png",
                    isHighlighted: true,
                    onTap: () {
                      Navigator.pushNamed(context, '/levelZeroEighth');
                    },
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
    required VoidCallback onTap,
    bool isHighlighted = false,
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
                color: const Color(0xFF4CAF50), // Green color
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
                    // Fallback if image doesn't exist
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
            // Navigation arrow (yellow highlight for first step)
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), // Green background
                  borderRadius: BorderRadius.circular(20),
                  border: isHighlighted && stepNumber == 1
                      ? Border.all(
                          color: Colors.yellow, width: 3) // Yellow highlight
                      : null,
                ),
                child: const Icon(
                  Icons.arrow_forward,
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
