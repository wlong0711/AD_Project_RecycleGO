import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/models/company_logo.dart';
import 'register.dart'; // Import the RegisterPage
import 'login.dart'; // Import the LoginPage

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    CompanyLogo companyLogo = Provider.of<CompanyLogo>(context, listen: false);
    
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/startup background.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView( // Added to ensure the content fits on all screen sizes
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: companyLogo.image,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'WELCOME',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildButton(
                    "Register",
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    "Login",
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('RecycleGo', style: TextStyle(color: Colors.green)),
                      SizedBox(width: 20),
                      Text('@2023AKA', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.white), // Changed border color to white for contrast
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white, // Changed text color to white for better visibility
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: WelcomePage(),
  ));
}