import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/home_page.dart';
import 'package:recycle_go/models/global_user.dart';
import 'forgot.dart';
import 'register.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;  // Flag for loading indicator

  @override
  void initState() {
    super.initState();
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
    if (!_rememberMe) {
      _clearAuthenticationState();
    }
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true); // Start loading

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // User's email is not verified
        _showErrorSnackBar('Please verify your email before logging in.');
        setState(() => _isLoading = false); // Stop loading
        return; // Stop further execution if email is not verified
      }

      // User's email is verified, proceed with login
      String userEmail = _usernameController.text.trim();
      var usersCollection = FirebaseFirestore.instance.collection('users');
      var querySnapshot = await usersCollection.where('email', isEqualTo: userEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDocument = querySnapshot.docs.first;
        GlobalUser.userName = userDocument['username'];
        GlobalUser.userLevel = userDocument['level'];
        GlobalUser.userPoints = userDocument['points'];

        if (_rememberMe) {
          _saveAuthenticationState();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException with code: ${e.code}');
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'The provided email is not registered.';
          break;
        case 'wrong-password':
          errorMessage = 'The password is invalid for the given email address.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again later.';
          break;
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Login failed. Please try again.');
      print(e);
    } finally {
      setState(() => _isLoading = false); // Stop loading
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
        title: const Text('Login'),
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
      body: Stack(
        children: [
          Center(child: _buildLoginForm()),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
  return SingleChildScrollView(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,  // Use min to fit content size
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Company%20Logo%2FLogo.png?alt=media&token=aac89fba-a30d-4a9a-8c39-d6cd85e1f4d5',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 20),
          _buildInputBox("Email", _usernameController, isPassword: false),
          _buildPasswordInputBox(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRememberMe(),
              _buildForgotPasswordLink(),
            ],
          ),
          const SizedBox(height: 10),
          _buildButton("Login", Colors.green, _login),
          const SizedBox(height: 20),
          // _buildOrSeparator(),
          // const SizedBox(height: 10),
          // _buildOtherLoginMethods(),
          // const SizedBox(height: 20),
          _buildCreateAccountText(),
        ],
      ),
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

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.green, // Changed button color to green
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white, // Set text color to white
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Modify _buildRememberMe and _buildForgotPasswordLink to match the green theme
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
          padding: EdgeInsets.only(right: 4.0),
          child: Text('Remember me', style: TextStyle(color: Colors.green)), // Green text color
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Padding(
      padding: const EdgeInsets.only(right: 35.0),
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
            color: Colors.green, // Green text color
            decoration: TextDecoration.underline,
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

  Widget _buildOrSeparator() {
    return const Row(
      children: [
        Expanded(
          child: Divider(thickness: 2),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('or'),
        ),
        Expanded(
          child: Divider(thickness: 2),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3, // Adjust the position from top
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 80, // Set the width of the overlay
              height: 80, // Set the height of the overlay
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ],
    );
  }

}



void main() {
  runApp(const MaterialApp(
    home: LoginPage(),
  ));
}
