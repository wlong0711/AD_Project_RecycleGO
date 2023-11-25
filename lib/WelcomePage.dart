import 'package:flutter/material.dart';
import 'register.dart'; // Import the RegisterPage
import 'login.dart'; // Import the LoginPage

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('RecycleGo'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Company logo centered at the top
          Center(
            child: Column(
              children: [
                Image.network(
                  'https://drive.google.com/your_company_logo_link',
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 10),
                Text(
                  'WELCOME',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue, // Customize the color as needed
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40),

          // Register Button
          _buildButton(
            "Register",
            Colors.white,
            () {
              // Navigate to the RegisterPage when the button is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
          ),

          SizedBox(height: 20),

          // Login Button
          _buildButton(
            "Login",
            Colors.white,
            () {
              // Navigate to the LoginPage when the button is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),

          SizedBox(height: 20),

          // RecycleGo and @2023AKA
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('RecycleGo'),
              SizedBox(width: 20),
              Text('@2023AKA'),
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
        border: Border.all(color: Colors.blue), // Add border for a cleaner look
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.blue, // Set text color to match the border
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: WelcomePage(),
  ));
}
