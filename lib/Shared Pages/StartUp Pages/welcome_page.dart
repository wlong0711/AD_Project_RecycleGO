import 'package:flutter/material.dart';
import 'register.dart'; // Import the RegisterPage
import 'login.dart'; // Import the LoginPage

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RecycleGo"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Image.network(
                  'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Company%20Logo%2FLogo.png?alt=media&token=aac89fba-a30d-4a9a-8c39-d6cd85e1f4d5',
                  width: 150,
                  height: 150,
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
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Register Button
          _buildButton(
            "Register",
            Colors.green, // Changed button color to green
            () {
              // Navigate to the RegisterPage when the button is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
          ),

          const SizedBox(height: 20),

          // Login Button
          _buildButton(
            "Login",
            Colors.green, // Changed button color to green
            () {
              // Navigate to the LoginPage when the button is clicked
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
              Text(
                'RecycleGo',
                style: TextStyle(color: Colors.green), // Text color changed to green
              ),
              SizedBox(width: 20),
              Text(
                '@2023AKA',
                style: TextStyle(color: Colors.green), // Text color changed to green
              ),
            ],
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

// This is testing pushing

void main() {
  runApp(const MaterialApp(
    home: WelcomePage(),
  ));
}
