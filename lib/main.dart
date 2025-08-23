import 'package:finalproject/main_screen/LoginPage%20.dart';
import 'package:flutter/material.dart';
import 'main_screen/WelcomeScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Screens/TreatmentOnePage.dart'; // Import the file where TreatmentOnePage is defined
import 'Screens/TreatmentTwoPage.dart'; // Import the file where TreatmentTwoPage is defined
import 'Screens/TreatmentThreePage.dart'; // Import the file where TreatmentThreePage is defined
import 'Screens/TreatmentFourPage.dart'; // Import the file where TreatmentFourPage is defined
import 'Screens/TreatmentFivePage.dart'; // Import the file where TreatmentFivePage is defined
import 'Screens/TreatmentSixPage.dart'; // Import the file where TreatmentSixPage is defined
import 'Screens/TreatmentSevenPage.dart'; // Import the file where TreatmentSevenPage is defined
import 'Screens/TreatmentEightPage.dart'; // Import the file where TreatmentEightPage is defined
import 'Screens/TreatmentZerowPage.dart'; // Import the file where TreatmentZerowPage is defined


void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Required before calling Firebase.initializeApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const WelcomeScreen(),
        routes: {'/login': (context) => const LoginPage(),
          '/welcome': (context) => const WelcomeScreen(),
          '/treatmentZero': (context) => const TreatmentZerowPage(),
          '/treatmentOne': (context) => const TreatmentOnePage(),
          '/treatmentTwo': (context) => const TreatmentTwoPage(),
          '/treatmentThree': (context) => const TreatmentThreePage(),
          '/treatmentFour': (context) => const TreatmentFourPage(),
          '/treatmentFive': (context) => const TreatmentFivePage(),
          '/treatmentSix': (context) => const TreatmentSixPage(),
          '/treatmentSeven': (context) => const TreatmentSevenPage(),
          '/treatmentEight': (context) => const TreatmentEightPage(),
        },

        );
  }
}
