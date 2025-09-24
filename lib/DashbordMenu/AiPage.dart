import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ikchatbot/ikchatbot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with TickerProviderStateMixin {
  late IkChatBotConfig chatBotConfig;
  bool _showChatBot = false;

  // FIX: Initialize animations to null and use null checks
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  bool _isVoiceMode = true;

  // Voice functionality
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  final List<Map<String, String>> _voiceConversation = [];
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeChatBot();
    _initializeAnimations(); // This should complete before build is called
    _initializeVoice();
  }

  void _initializeVoice() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    await _initSpeech();
    await _initTts();
  }

  Future<void> _initSpeech() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print('❌ Microphone permission denied');
      return;
    }

    _speechEnabled = await _speech.initialize(
      onError: (error) {
        print('❌ Speech recognition error: $error');
        setState(() {
          _isListening = false;
        });
        // Show a helpful message to the user
        if (error.errorMsg.contains('timeout')) {
          _showErrorDialog('Speech timeout',
              'Please try speaking louder and clearer. Make sure you start speaking immediately after tapping the microphone.');
        }
      },
      onStatus: (status) {
        print('📱 Speech recognition status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
          // Process the final result when done
          if (status == 'done' && _wordsSpoken.isNotEmpty) {
            print('✅ Processing final speech result: "$_wordsSpoken"');
            _processVoiceInput(_wordsSpoken);
          }
        }
      },
      debugLogging: true, // Enable debug logging
    );

    print('🎤 Speech recognition initialized: $_speechEnabled');

    // Check if speech recognition is available on this device
    bool available = await _speech.hasPermission;
    print('🔐 Speech permission: $available');

    setState(() {});
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
      print('TTS Error: $msg');
    });
  }

  void _initializeAnimations() {
    try {
      // FIX: Added try-catch and null checks
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(
        begin: 1.0,
        end: 1.1,
      ).animate(CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      ));

      _pulseController!.repeat(reverse: true);
    } catch (e) {
      print('❌ Error initializing animations: $e');
      // Initialize with fallback values to prevent null issues
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _pulseAnimation = const AlwaysStoppedAnimation(1.0);
    }
  }

  void _initializeChatBot() {
    chatBotConfig = IkChatBotConfig(
      // SMTP Rating settings (optional)
      ratingIconYes: const Icon(Icons.star),
      ratingIconNo: const Icon(Icons.star_border),
      ratingIconColor: Colors.black,
      ratingBackgroundColor: Colors.white,
      ratingButtonText: 'Submit Rating',
      thankyouText: 'Thanks for your rating!',
      ratingText: 'Rate your experience:',
      ratingTitle: 'Thank you for using the chatbot!',
      body: 'Voice chat feedback',
      subject: 'Voice Chat Rating',
      recipient: 'recipient@example.com',
      isSecure: false,
      senderName: 'Voice Assistant',
      smtpUsername: 'Your Email',
      smtpPassword: 'your password',
      smtpServer: 'stmp.gmail.com',
      smtpPort: 587,

      // Core chatbot UI settings
      sendIcon: const Icon(Icons.send, color: Colors.black),
      userIcon: const Icon(Icons.person, color: Colors.white),
      botIcon: const Icon(Icons.smart_toy, color: Colors.white),
      botChatColor: const Color(0xFF6366F1),
      delayBot: 100,
      closingTime: 1,
      delayResponse: 1,
      userChatColor: const Color.fromARGB(255, 103, 0, 0),
      waitingTime: 1,

      // Keywords and responses
      keywords: _getKeywords(),
      responses: _getResponses(),

      // Visual settings
      backgroundColor: Colors.white,
      backgroundImage: "assets/images/treatmentimg.png",
      backgroundAssetimage: "assets/images/treatmentimg.png",
      initialGreeting:
          "Hello! 👋\nWelcome to AI Assistant.\nI'm ready to help you with your questions!",
      defaultResponse:
          "I'm sorry, I didn't quite understand that. Could you please rephrase your question?",
      inactivityMessage: "Is there anything else I can help you with?",
      closingMessage: "Thank you for using AI Assistant. Have a great day!",
      inputHint: 'Type your message here...',
      waitingText: 'AI is thinking...',
      useAsset: true,
    );
  }

  List<String> _getKeywords() {
    return [
      'hello',
      'hi',
      'hey',
      'help',
      'what',
      'how',
      'weather',
      'time',
      'date',
      'thanks',
      'bye',
      'goodbye',
      'ai',
      'artificial intelligence',
      'features',
      'capabilities',
      'voice',
      'speak',
      'listen',
      'hear',
      'talk',
      'chat',
      'treatment',
      'medical',
      'health',
      'doctor',
      'medicine',
      'therapy',
      'appointment',
      'symptoms',
      'diagnosis',
      'prescription',
      'wellness',
    ];
  }

  List<String> _getResponses() {
    return [
      'Hello there! How can I assist you today?',
      'Hi! Nice to meet you. What would you like to know?',
      'Hey! I\'m here to help. What\'s on your mind?',
      'I\'m here to help! You can ask me about various topics.',
      'I can help you with information, answer questions, and have conversations.',
      'I can assist you with various tasks and answer your questions.',
      'I don\'t have access to current weather data, but you can check your local weather app!',
      'I don\'t have access to real-time data, but you can check your device\'s clock.',
      'I don\'t have access to real-time data, but you can check your device\'s calendar.',
      'You\'re very welcome! Happy to help anytime.',
      'Goodbye! Feel free to come back if you need any assistance.',
      'See you later! Have a wonderful day!',
      'I\'m an AI assistant designed to help answer questions and have conversations.',
      'AI stands for Artificial Intelligence - computer systems that can perform tasks that typically require human intelligence.',
      'I can help answer questions, provide information, and have conversations on various topics.',
      'I can assist with information, answer questions, help with basic tasks, and engage in conversations.',
      'I\'m designed to understand and respond to your questions effectively.',
      'I can communicate through text and voice to help you with various inquiries.',
      'I can process your questions and provide helpful responses.',
      'I love having conversations! It helps me assist you better.',
      'Voice chat allows for natural communication and hands-free interaction.',
      'I can provide general information about treatments, but please consult healthcare professionals for medical advice.',
      'For medical advice, always consult with qualified healthcare providers.',
      'I can share general health information, but professional medical advice is important.',
      'Doctors and medical professionals are the best source for treatment advice.',
      'Medicine and therapy should always be supervised by healthcare experts.',
      'Treatment plans should be developed with your healthcare provider.',
      'I can help you prepare questions for your medical appointments.',
      'I can provide general information about symptoms, but please see a doctor for proper diagnosis.',
      'For prescription information, always consult with your doctor or pharmacist.',
      'I can share general wellness tips, but personalized health advice should come from professionals.',
    ];
  }

  String _generateResponse(String input) {
    input = input.toLowerCase();
    List<String> keywords = _getKeywords();
    List<String> responses = _getResponses();

    for (int i = 0; i < keywords.length; i++) {
      if (input.contains(keywords[i])) {
        return responses[i % responses.length];
      }
    }

    return "I'm sorry, I didn't quite understand that. Could you please rephrase your question?";
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      print('❌ Speech recognition not enabled');
      return;
    }

    setState(() {
      _isListening = true;
      _wordsSpoken = "";
      _confidenceLevel = 0;
    });

    print('🎤 Starting to listen...');

    try {
      await _speech.listen(
        onResult: (result) {
          print(
              '🗣️ Speech result: "${result.recognizedWords}" (confidence: ${result.confidence})');
          setState(() {
            _wordsSpoken = result.recognizedWords;
            _confidenceLevel = result.confidence;
          });

          // If this is a final result, process it
          if (result.finalResult) {
            print('✅ Final result received: "$_wordsSpoken"');
            _processVoiceInput(_wordsSpoken);
          }
        },
        listenFor: const Duration(seconds: 10), // Reduced from 30 to 10 seconds
        pauseFor: const Duration(seconds: 2), // Reduced from 3 to 2 seconds
        partialResults: true,
        cancelOnError: true, // Changed to true to handle errors better
        listenMode: stt.ListenMode
            .deviceDefault, // Changed from confirmation to deviceDefault
        sampleRate: 16000, // Added explicit sample rate
      );
    } catch (e) {
      print('❌ Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    print('🛑 Stopping listening...');
    await _speech.stop();
    setState(() {
      _isListening = false;
    });

    if (_wordsSpoken.isNotEmpty) {
      print('📝 Processing speech: "$_wordsSpoken"');
      _processVoiceInput(_wordsSpoken);
    } else {
      print('❌ No speech detected');
    }
  }

  Future<void> _processVoiceInput(String input) async {
    if (input.isEmpty) {
      print('❌ Empty input, skipping processing');
      return;
    }

    print('🧠 Processing input: "$input"');

    // Add user message to conversation
    setState(() {
      _voiceConversation.add({
        'sender': 'user',
        'message': input,
      });
    });

    // Generate AI response
    String response = _generateResponse(input);
    print('🤖 Generated response: "$response"');

    setState(() {
      _voiceConversation.add({
        'sender': 'ai',
        'message': response,
      });
    });

    // Speak the response
    print('🔊 Speaking response...');
    await _speak(response);
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      print('🛑 Stopping current TTS...');
      await _flutterTts.stop();
    }
    print('🔊 Speaking: "$text"');
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  void _toggleChatMode() {
    setState(() {
      _showChatBot = !_showChatBot;
      _isVoiceMode = !_isVoiceMode;
    });
  }

  void _activateVoiceMode() {
    setState(() {
      _isVoiceMode = true;
      _showChatBot = false;
    });
  }

  void _clearVoiceConversation() {
    setState(() {
      _voiceConversation.clear();
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // FIX: Added null check before disposing
    _pulseController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isVoiceMode ? 'Voice AI Assistant' : 'AI Chat Assistant'),
        backgroundColor: const Color.fromARGB(255, 254, 254, 255),
        foregroundColor: Colors.white,
        elevation: 0,
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
                Color.fromARGB(255, 199, 238, 148),
                Color.fromARGB(255, 33, 180, 82)
              ],
            ),
          ),
        ),
        actions: [
          if (_isVoiceMode && _voiceConversation.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearVoiceConversation,
              tooltip: 'Clear conversation',
            ),
          if (_isVoiceMode)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () =>
                  _speak("Hello! This is a test of the text to speech system."),
              tooltip: 'Test TTS',
            ),
          IconButton(
            icon: Icon(_isVoiceMode ? Icons.chat : Icons.mic),
            onPressed: _toggleChatMode,
            tooltip:
                _isVoiceMode ? 'Switch to Text Chat' : 'Switch to Voice Mode',
          ),
        ],
      ),
      body: _showChatBot
          ? ikchatbot(config: chatBotConfig)
          : _isVoiceMode
              ? _buildVoiceChatInterface()
              : _buildWelcomeScreen(),
    );
  }

  Widget _buildVoiceChatInterface() {
    // FIX: Added null check for pulse animation
    final pulseAnimation = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromARGB(255, 199, 238, 148),
            Color.fromARGB(255, 33, 180, 82)
          ],
        ),
      ),
      child: Column(
        children: [
          // Conversation History
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _voiceConversation.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.record_voice_over,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start speaking to begin conversation',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _voiceConversation.length,
                      itemBuilder: (context, index) {
                        final message = _voiceConversation[index];
                        final isUser = message['sender'] == 'user';

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFF6366F1),
                                  child: Icon(Icons.smart_toy,
                                      size: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    message['message']!,
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              if (isUser) ...[
                                const SizedBox(width: 8),
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      Color.fromARGB(255, 103, 0, 0),
                                  child: Icon(Icons.person,
                                      size: 16, color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Voice Input Section
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Status Text
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 254, 251, 251).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      _isListening
                          ? 'Listening... "$_wordsSpoken"'
                          : _isSpeaking
                              ? 'AI is speaking...'
                              : _speechEnabled
                                  ? 'Tap the microphone to speak'
                                  : 'Voice recognition not available',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 251, 250, 250),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Voice Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Stop Speaking Button
                      if (_isSpeaking)
                        GestureDetector(
                          onTap: _stopSpeaking,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.stop,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // Microphone Button
                      AnimatedBuilder(
                        animation:
                            pulseAnimation, // FIX: Use the safe animation
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isListening ? pulseAnimation.value : 1.0,
                            child: GestureDetector(
                              onTap: _speechEnabled
                                  ? (_isListening
                                      ? _stopListening
                                      : _startListening)
                                  : null,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening
                                      ? Colors.red
                                      : _speechEnabled
                                          ? Colors.white
                                          : Colors.grey,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isListening
                                              ? Colors.red
                                              : Colors.white)
                                          .withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  size: 40,
                                  color: _isListening
                                      ? Colors.white
                                      : const Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Instructions
                  Text(
                    _isListening
                        ? 'Listening... Tap again to stop'
                        : _isSpeaking
                            ? 'AI is speaking... Tap stop to interrupt'
                            : 'Tap microphone to start speaking',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    // FIX: Added null check for pulse animation
    final pulseAnimation = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      size: 50,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Your intelligent companion for questions, information, and conversations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Voice Button
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: pulseAnimation, // FIX: Use the safe animation
                      builder: (context, child) {
                        return Transform.scale(
                          scale: pulseAnimation.value,
                          child: GestureDetector(
                            onTap: _activateVoiceMode,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mic,
                                size: 35,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Voice Chat',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Available Now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                // Text Chat Button
                Column(
                  children: [
                    GestureDetector(
                      onTap: _toggleChatMode,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 35,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Text Chat',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Available Now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Features List
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text(
                    'What I can help with:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeatureItem(Icons.help_outline, 'Questions'),
                      _buildFeatureItem(Icons.info_outline, 'Information'),
                      _buildFeatureItem(Icons.chat, 'Conversations'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
