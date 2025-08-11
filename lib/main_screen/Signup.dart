import 'package:finalproject/main_screen/LoginPage%20.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password validation (minimum 6 characters)
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  // Username validation (minimum 3 characters, no spaces)
  bool _isValidUsername(String username) {
    return username.length >= 3 && !username.contains(' ');
  }

  // Check if username already exists
  Future<bool> _isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Show alert dialog
  void _showAlert(String title, String message, {bool isSuccess = false}) {
    if (!mounted) return; // Check if widget is still mounted

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Sign up function
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String username = _usernameController.text.trim();

    // Validate inputs
    if (!_isValidEmail(email)) {
      _showAlert('Invalid Email', 'Please enter a valid email address.');
      return;
    }

    if (!_isValidPassword(password)) {
      _showAlert(
          'Invalid Password', 'Password must be at least 6 characters long.');
      return;
    }

    if (!_isValidUsername(username)) {
      _showAlert('Invalid Username',
          'Username must be at least 3 characters long and contain no spaces.');
      return;
    }

    if (!mounted) return; // Check if widget is still mounted

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if username is available
      bool usernameAvailable = await _isUsernameAvailable(username);
      if (!usernameAvailable) {
        if (mounted) {
          _showAlert('Username Taken',
              'This username is already taken. Please choose another one.');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      print('Creating user with email: $email'); // Debug log

      // Create user with Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
          'User created successfully: ${userCredential.user?.uid}'); // Debug log

      // Verify user creation was successful
      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(username);
        print('Display name updated to: $username'); // Debug log

        // Save user data to Firestore
        try {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'uid': userCredential.user!.uid,
            'username': username.toLowerCase(),
            'displayName': username,
            'email': email.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

          print('User data saved to Firestore successfully'); // Debug log
        } catch (firestoreError) {
          print('Firestore error: $firestoreError'); // Debug log
          // Even if Firestore fails, we don't want to delete the user account
          // Just show a warning but continue with success flow
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showAlert(
              'Warning',
              'Account created successfully, but there was an issue saving additional user data. You can still sign in with your credentials.',
              isSuccess: true,
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show success message and navigate to login
          _showAlert(
            'Success',
            'Account created successfully! Please sign in with your credentials.',
            isSuccess: true,
          );
        }
      } else {
        throw Exception('User creation failed - userCredential.user is null');
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}'); // Debug log

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage;
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists with this email.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled.';
            break;
          case 'network-request-failed':
            errorMessage =
                'Network error. Please check your connection and try again.';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }

        _showAlert('Registration Failed', errorMessage);
      }
    } catch (e) {
      print('Unexpected error details: $e'); // Enhanced debug log
      print('Error type: ${e.runtimeType}'); // Debug log

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // More specific error message
        String errorMessage = 'An unexpected error occurred: ${e.toString()}';
        if (e.toString().contains('permission')) {
          errorMessage =
              'Permission denied. Please check your Firestore security rules.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        }

        _showAlert('Error', errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(232, 245, 232, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lottie Animation
                Container(
                  width: 300,
                  height: 270,
                  child: Lottie.asset(
                    'assets/animations/Appointment booking with smartphone.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),

                const SizedBox(height: 20),

                // Title Text
                const Text(
                  'Welcome you\'ve been missed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 20),

                // Email TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!_isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Username TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (!_isValidUsername(value)) {
                        return 'Username must be 3+ characters, no spaces';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Username',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Password TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (!_isValidPassword(value)) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // Ready to Sign Up text
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Ready to Sign Up?',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 0),

                // Sign Up Button
                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 109, 240, 168),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // Or continue with
                Text(
                  'Or continue with',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 10),

                // Social Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google Button
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Handle Google sign in
                        },
                        icon: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                  'https://developers.google.com/identity/images/g-logo.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Apple Button
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Handle Apple sign in
                        },
                        icon: const Icon(
                          Icons.apple,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF8B4513),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
