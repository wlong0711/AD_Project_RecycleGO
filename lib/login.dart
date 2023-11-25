import 'package:flutter/material.dart';
import 'package:recycle_go/wlcpage.dart';
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
          _buildButton("Login", Colors.blue),

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

  Widget _buildButton(String label, Color color) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: () {
          // Check if the username and password are not empty
          if (_usernameController.text.isNotEmpty &&
              _passwordController.text.isNotEmpty) {
            // Add your authentication logic here if needed

            // Navigate to WelcomePage when the login button is clicked
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      WelcomePage()), //change this to redirect to the homepage*********
            );
          } else {
            // Show a snackbar or any other feedback for empty fields
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please enter both username and password.'),
              ),
            );
          }
        },
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
