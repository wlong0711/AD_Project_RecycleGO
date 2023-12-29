// RegisterPage
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // Import the LoginPage

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  Future<void> _register() async {
    try {
      // Create a new user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Add additional user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text,
        'username': _usernameController.text,
        'points': 0,
        'level' :0, //0 for user, 1 for admin
      });

      // Registration successful, navigate to the next screen
      // (you can replace this with your own logic)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print("Error during registration: $e");
      // Handle registration failure (show a snackbar, etc.)
    }
  }

  Widget _buildLoginText(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the LoginPage when the text is clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      child: const Text(
        'Already a member? Login.',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
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
      body: SingleChildScrollView( // Added SingleChildScrollView for better UX on smaller devices
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Company Logo
              Image.network(
                'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Company%20Logo%2FLogo.png?alt=media&token=d70a3db8-c0c0-4849-9aee-7ec04c4bbbd8',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),

              // Input Boxes and Buttons
              _buildInputBox("Email", _emailController, isPassword: false),
              _buildInputBox("Username", _usernameController, isPassword: false),
              _buildPasswordInputBox(),
              _buildConfirmPasswordInputBox(),
              const SizedBox(height: 10),
              _buildButton("Register", Colors.green),
              const SizedBox(height: 20),
              _buildOrSeparator(),
              const SizedBox(height: 10),
              _buildOtherLoginMethods(),
              const SizedBox(height: 20),
              _buildLoginText(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrSeparator() {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.green, // Adjust the color to match the theme
            thickness: 2,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'or',
            style: TextStyle(color: Colors.green), // Adjust the text color to match the theme
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.green, // Adjust the color to match the theme
            thickness: 2,
          ),
        ),
      ],
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
        obscureText: isPassword && !_isPasswordVisible,
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

  Widget _buildPasswordInputBox() {
    return SizedBox(
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
          border: const OutlineInputBorder(),
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

  Widget _buildConfirmPasswordInputBox() {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: _confirmPasswordController,
        obscureText: !_isConfirmPasswordVisible,
        onChanged: (value) {
          // Handle the input change and update the state as needed
          setState(() {});
        },
        decoration: InputDecoration(
          labelText:
              _confirmPasswordController.text.isEmpty ? 'Confirm Password' : '',
          border: const OutlineInputBorder(),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
            child: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
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
      child: TextButton(
        onPressed: _register,
        child: Center(
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

  Widget _buildOtherLoginMethods() {
    return const Row(
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
}

void main() {
  runApp(const MaterialApp(
    home: RegisterPage(),
  ));
}
