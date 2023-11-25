import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/home_page.dart';
import 'forgot.dart';
import 'register.dart'; // Import the RegisterPage

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      // Show a snackbar for empty fields
      _showErrorSnackBar('Please enter both email and password.');
      return;
    }
    
    try {
      // Sign in with email and password
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );

      // If the signIn is successful, navigate to HomePage
      if (userCredential.user != null) {
        Navigator.pushReplacement( // Use pushReplacement to prevent going back to login screen
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // HomePage should be the landing page after login
        );
      }
    } on FirebaseAuthException catch (e) {
      // Log the error code for debugging
      print('FirebaseAuthException with code: ${e.code}');
      // Match the error code and display an appropriate error message
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'There is no user corresponding to the email address.';
          break;
        case 'invalid-credential':
          errorMessage = 'The password is invalid for the given email address.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again later.';
          break;
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      // General error handling
      _showErrorSnackBar('Login failed. Please try again.');
      print(e); // For debugging purposes
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Login'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Company Logo at the top center
          Image.network(
            'https://example.com/your-company-logo-url.png',
            width: 100, // Set the width according to your design
            height: 100, // Set the height according to your design
          ),

          SizedBox(height: 20),

          // Username Input Box
          _buildInputBox("Username", _usernameController, isPassword: false),

          // Password Input Box
          _buildPasswordInputBox(),

          SizedBox(height: 10),

          // Remember Me Checkbox and Forgot Password Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember Me Checkbox
              _buildRememberMe(),

              // Forgot Password Link
              _buildForgotPasswordLink(),
            ],
          ),

          SizedBox(height: 10),

          // Login Button
          _buildButton("Login", Colors.blue, _login),

          SizedBox(height: 20),

          // Horizontal Bar and "or" text
          Row(
            children: [
              Expanded(
                child: Divider(
                  thickness: 2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('or'),
              ),
              Expanded(
                child: Divider(
                  thickness: 2,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          // Other Login Methods
          _buildOtherLoginMethods(),

          SizedBox(height: 20),

          // "Not a member, create a new account" Text
          _buildCreateAccountText(),
        ],
      ),
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
        obscureText: isPassword && !_isPasswordVisible,
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

  Widget _buildPasswordInputBox() {
    return Container(
      width: 300,
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        onChanged: (value) {
          // Handle the input change and update the state as needed
          setState(() {});
        },
        decoration: InputDecoration(
          labelText: _passwordController.text.isEmpty ? 'Password' : '',
          border: OutlineInputBorder(),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            child: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
          ),
        ),
      ),
    );
  }

  bool _rememberMe = false; // Add this variable to store the state

  Widget _buildRememberMe() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value!;
            });
          },
        ),
        Text('Remember me'),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return GestureDetector(
      onTap: () {
        // Navigate to the ForgotPasswordPage when the text is clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
        );
      },
      child: Text(
        'Forgot password?',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: onPressed, // Use the provided onPressed function
        child: Center(
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

  Widget _buildOtherLoginMethods() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.facebook, size: 40),
        SizedBox(width: 20),
        Icon(Icons.mail, size: 40),
        SizedBox(width: 20),
        Icon(Icons.phone, size: 40),
      ],
    );
  }

  Widget _buildCreateAccountText() {
    return GestureDetector(
      onTap: () {
        // Navigate to the RegisterPage when the text is clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RegisterPage()),
        );
      },
      child: Text(
        'Not a member? Create a new account.',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: LoginPage(),
  ));
}
