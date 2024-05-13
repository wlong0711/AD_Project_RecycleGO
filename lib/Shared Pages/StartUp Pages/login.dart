import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/home_page.dart';
import 'package:recycle_go/models/company_logo.dart';
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
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

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

        if (userCredential.user != null) {
          // Fetch the user's data from Firestore
          DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

          if (!userDocSnapshot.exists) {
            _showErrorSnackBar('The provided email is not registered.');
            return;
          }

          Map<String, dynamic> userDoc = userDocSnapshot.data() as Map<String, dynamic>;

          // Get the user level and check if it's an admin
          int userLevel = userDoc['level'] ?? 0;

          // Allow admins to bypass email verification check
          if (userLevel == 1 || userCredential.user!.emailVerified) {
            // Admin or email verified, proceed with login
            // Set global user information
            GlobalUser.userName = userDoc['username'];
            GlobalUser.userLevel = userDoc['level'];
            GlobalUser.userPoints = userDoc['points'];
            GlobalUser.userID = userDocSnapshot.id;
            
            if (_rememberMe) {
              _saveAuthenticationState();
            }

            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => const HomePage()),
            // );
          } else {
            // Not an admin and email not verified
            _showErrorSnackBar('Please verify your email before logging in.');
          }
        }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException caught: ${e.code}");
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
          errorMessage = 'Login failed. Please check your email and your password.';
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
    if (_scaffoldKey.currentState != null) {
      _scaffoldKey.currentState!.showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white),),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, // optional: to float the snackbar
        ),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return ScaffoldMessenger(
    key: _scaffoldKey,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/startup background.png',
                fit: BoxFit.cover,
              ),
            ),
            Center(child: _buildLoginForm()),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
  );
  }

  Widget _buildLoginForm() {
    CompanyLogo companyLogo = Provider.of<CompanyLogo>(context, listen: false);
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
          SizedBox(
            width: 100,
            height: 100,
            child: companyLogo.image, // Use the provided CompanyLogo's image
          ),
          const SizedBox(height: 20),
          const Text(
            'Login',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          const SizedBox(height: 20),
          _buildInputBox("Email", _usernameController, isPassword: false),
          const SizedBox(height: 23),
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
          labelStyle: const TextStyle(color: Colors.grey), // Grey label text
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Grey border
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Grey border
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Grey border
          ),
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
          labelStyle: const TextStyle(color: Colors.grey), // Grey label text
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Grey border
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Grey border
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Grey border
          ),
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
            color: Colors.green,
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
        'Not a member? Create a new account',
        style: TextStyle(
          color: Colors.green,
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
        // Full screen semi-transparent overlay
        Positioned.fill(
          child: Container(
            color: Colors.grey.withOpacity(0.5), // Semi-transparent grey color
          ),
        ),
        // Centered loading indicator
        Center(
          child: Container(
            width: 80, // Set the width of the overlay
            height: 80, // Set the height of the overlay
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5), // Semi-transparent black for the loading box
              borderRadius: BorderRadius.circular(10), // Rounded corners for the loading box
            ),
            child: const Center(
              child: CircularProgressIndicator(),
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
