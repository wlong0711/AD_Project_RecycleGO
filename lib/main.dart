import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/welcome_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

Future main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Ensure plugin services are initialized
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecycleGo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      home: const WelcomePage(),
    );
  }
}