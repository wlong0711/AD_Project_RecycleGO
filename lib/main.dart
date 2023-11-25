import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'home_page.dart';
=======
import 'package:recycle_go/register.dart';
import 'package:recycle_go/wlcpage.dart';
import 'forgot.dart';
import 'login.dart';
import 'map_screen.dart';
>>>>>>> 9dbba3958e5927b8d2b446ae8abeb0ebb2465aa0
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure plugin services are initialized
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
<<<<<<< HEAD

      home: const HomePage(),
    );
  }
}
=======
      home: WelcomePage(),
    );
  }
}
>>>>>>> 9dbba3958e5927b8d2b446ae8abeb0ebb2465aa0
