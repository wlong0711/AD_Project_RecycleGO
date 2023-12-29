import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/models/company_logo.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorSnackBar("Please enter your email address");
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      _showSuccessDialog();
    } catch (e) {
      if (mounted) _showErrorSnackBar("An error occurred, please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Reset'),
        content: Text(
            'A password reset link has been sent to ${_emailController.text}. Please check your email.'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the AlertDialog
              Navigator.of(context).pop(); // Go back to the previous screen
            },
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Reset Password'),
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
          Center(child: _buildForgetForm()),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: _buildLoadingOverlay(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForgetForm() {
    CompanyLogo companyLogo = Provider.of<CompanyLogo>(context, listen: false);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 100,
                height: 100,
                child: companyLogo.image, // Use the provided CompanyLogo's image
              ),
            
            const SizedBox(height: 20),
            const Text(
              'Enter your email and we will send you a password reset link.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildResetPasswordButton(),
          ],
        ),
        ),
    );
  }

  Widget _buildResetPasswordButton() {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: _resetPassword,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child:
          const Text(
                'Send Password Reset Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
          ),
      ),
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
    home: ForgotPasswordPage(),
  ));
}