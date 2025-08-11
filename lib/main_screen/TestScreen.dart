import 'package:flutter/material.dart';

class Testscreen extends StatefulWidget {
  const Testscreen({super.key});

  @override
  State<Testscreen> createState() => _TestscreenState();
}

class _TestscreenState extends State<Testscreen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('Test Screen'),
      ),
      body: const Center(
        child: Text('This is the test screen'),
      ),
    );
  }
}