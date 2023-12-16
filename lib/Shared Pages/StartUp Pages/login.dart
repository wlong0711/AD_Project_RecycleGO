import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/home_page.dart';
import 'package:recycle_go/models/global_user.dart';
import 'forgot.dart';
import 'register.dart'; // Import the RegisterPage
import 'package:shared_preferences/shared_preferences.dart';
import 'remember_me.dart'; // Import the RememberMeWidget


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false; // Add this variable to store the state

  @override
  void initState() {
    super.initState();
    // Load saved authentication state
    _loadAuthenticationState();
  }

  void _loadAuthenticationState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = prefs.getString('username') ?? '';
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  void _login() async {
    // Clear saved authentication state when Remember Me is unchecked
  if (!_rememberMe) {
    _clearAuthenticationState();
  }
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

        // Fetch the username from Firestore using the email
        String userEmail = _usernameController.text.trim();
        var usersCollection = FirebaseFirestore.instance.collection('users');
        var querySnapshot = await usersCollection.where('email', isEqualTo: userEmail).get();

         if (querySnapshot.docs.isNotEmpty) {
          // Assuming 'username' is the field name in your Firestore collection
          var userDocument = querySnapshot.docs.first;
          GlobalUser.userName = userDocument['username'];
          GlobalUser.userLevel = userDocument['level'];
          GlobalUser.userPoints = userDocument['points'];

        // Save authentication state if "Remember Me" is checked
        if (_rememberMe) {
          _saveAuthenticationState();
        }

          // Navigate to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          _showErrorSnackBar('User data not found in database.');
        }
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

  void _clearAuthenticationState() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove('username');
  prefs.remove('password');
  }

  void _saveAuthenticationState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', _usernameController.text);
    prefs.setBool('rememberMe', _rememberMe);
    if (_rememberMe) {
      prefs.setString('password', _passwordController.text);
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
        title: const Text('Login'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Company Logo at the top center
          Image.network(
            'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Company%20Logo%2FLogoWithSlogan.png?alt=media&token=5b939cb4-b9d8-42b5-adcb-8de58ee095e0',
            width: 100, // Set the width according to your design
            height: 100, // Set the height according to your design
          ),

          const SizedBox(height: 20),

          // Username Input Box
          SizedBox(
            width: 330,
            child: TextField(
              controller: _usernameController,
              obscureText: _isPasswordVisible,
              onChanged: (value) {
                // Handle the input change and update the state as needed
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: _usernameController.text.isEmpty ? 'Email' : '',
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // Password Input Box
          SizedBox(
            width: 330,
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
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Remember Me Widget
          RememberMeWidget(
            usernameController: _usernameController,
            passwordController: _passwordController,
            onRememberMeChanged: (value) {
              setState(() {
                _rememberMe = value;
              });
            },
          ),

          const SizedBox(height: 10),

          // Login Button
          Container(
            width: 200,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: _login,
              child: Center(
                child: Text(
                  'Login',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Horizontal Bar and "or" text
          Row(
            children: [
              Expanded(
                child: Divider(
                  thickness: 2,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('or'),
              ),
              Expanded(
                child: Divider(
                  thickness: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Other Login Methods
          _buildOtherLoginMethods(),

          const SizedBox(height: 20),

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
    return SizedBox(
      width: 330,
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
      width: 330,
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
  
  Widget _buildRememberMe() {
  return Row(
    children: [
      const SizedBox(width: 22.0),
      Checkbox(
        value: _rememberMe,
        onChanged: (value) {
          setState(() {
            _rememberMe = value!;
          });
        },
      ),
      const Padding(
        padding: EdgeInsets.only(right: 4.0), // Adjust this value to control the spacing
        child: Text('Remember me'),
      ),
    ],
  );
}


  Widget _buildForgotPasswordLink() {
  return Padding(
    padding: const EdgeInsets.only(right: 35.0), // Adjust this value to control the left indentation
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
        );
      },
      child: const Text(
        'Forgot password?',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
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

  Widget _buildCreateAccountText() {
    return GestureDetector(
      onTap: () {
        // Navigate to the RegisterPage when the text is clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterPage()),
        );
      },
      child: const Text(
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
  runApp(const MaterialApp(
    home: LoginPage(),
  ));
}