// ForgotPasswordPage
import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginPage

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool _isNewPasswordVisible = false;
  //bool _isConfirmPasswordVisible = false; 
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forget Password'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 10,
        shadowColor: Colors.greenAccent.withOpacity(0.5),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Company Logo at the top center
          Image.network(
            'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Company%20Logo%2FLogo.png?alt=media&token=aac89fba-a30d-4a9a-8c39-d6cd85e1f4d5',
            width: 100, // Set the width according to your design
            height: 100, // Set the height according to your design
          ),

          const SizedBox(height: 20),

          // "Reset Account Password" text below the logo
          const Text(
            'Reset Account Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Username Input Box
          _buildInputBox("Username", _usernameController, isPassword: false),

          // New Password Input Box
          _buildPasswordInputBox(_newPasswordController, 'New Password'),

          // Confirm Password Input Box
          _buildPasswordInputBox(
              _confirmPasswordController, 'Confirm Password'),

          const SizedBox(height: 10),

          // Save Changes Button (formerly Login Button)
          _buildButton(
              "Save Changes", Colors.green), // Change the color if needed
        ],
      ),
    );
  }

  Widget _buildInputBox(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isNewPasswordVisible,
        onChanged: (value) {
          // Handle the input change and update the state as needed
          setState(() {});
        },
        decoration: InputDecoration(
          labelText: controller.text.isEmpty ? label : '',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPasswordInputBox(
    TextEditingController controller,
    String labelText,
  ) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: !_isNewPasswordVisible,
        onChanged: (value) {
          // Handle the input change and update the state as needed
          setState(() {});
        },
        decoration: InputDecoration(
          labelText: controller.text.isEmpty ? labelText : '',
          border: const OutlineInputBorder(),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _isNewPasswordVisible = !_isNewPasswordVisible;
              });
            },
            child: Icon(
              _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String label, Color color) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () {
            // Implement the logic to save changes/reset password
            // After successful password reset, navigate to the newest LoginPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          },
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
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
    home: ForgotPasswordPage(),
  ));
}
