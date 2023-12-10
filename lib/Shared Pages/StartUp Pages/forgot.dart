// ForgotPasswordPage
import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginPage

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool _isNewPasswordVisible = false;
  //bool _isConfirmPasswordVisible = false; 
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Forgot Password'),
      ),
      body: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Company Logo at the top center
          Image.network(
            'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Company%20Logo%2FLogoWithSlogan.png?alt=media&token=5b939cb4-b9d8-42b5-adcb-8de58ee095e0',
            width: 100, // Set the width according to your design
            height: 100, // Set the height according to your design
          ),

          SizedBox(height: 20),

          // "Reset Account Password" text below the logo
          Text(
            'Reset Account Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          // Username Input Box
          _buildInputBox("Username", _usernameController, isPassword: false),

          // New Password Input Box
          _buildPasswordInputBox(_newPasswordController, 'New Password'),

          // Confirm Password Input Box
          _buildPasswordInputBox(
              _confirmPasswordController, 'Confirm Password'),

          SizedBox(height: 10),

          // Save Changes Button (formerly Login Button)
          _buildButton(
              "Save Changes", Colors.blue), // Change the color if needed
        ],
      ),
     )
    );
  }

  Widget _buildInputBox(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Container(
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
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPasswordInputBox(
    TextEditingController controller,
    String labelText,
  ) {
    return Container(
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
          border: OutlineInputBorder(),
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
                builder: (context) => LoginPage(),
              ),
            );
          },
          child: Text(
            label,
            style: TextStyle(
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
  runApp(MaterialApp(
    home: ForgotPasswordPage(),
  ));
}
