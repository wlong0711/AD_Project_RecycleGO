import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/welcome_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:recycle_go/models/company_logo.dart';
import 'firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  // Initialize the company logo here
  final CompanyLogo companyLogo = CompanyLogo(
    'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Company%20Logo%2FLogo.png?alt=media&token=d70a3db8-c0c0-4849-9aee-7ec04c4bbbd8', // Replace with your actual image URL
  );

  await companyLogo.preloadImage(); 

  runApp(MyApp(companyLogo: companyLogo));
}

class MyApp extends StatelessWidget {
  final CompanyLogo companyLogo;

  const MyApp({super.key, required this.companyLogo});

  @override
  Widget build(BuildContext context) {
    // Use Provider to make CompanyLogo available down the widget tree
    return Provider<CompanyLogo>(
      create: (_) => companyLogo,
      child: MaterialApp(
        title: 'RecycleGo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const WelcomePage(), // WelcomePage should be modified to use Provider if it needs CompanyLogo
      ),
    );
  }
}