import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recycle_go/Component/dialogs.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/login.dart';

class EditUserProfilePage extends StatefulWidget {
  const EditUserProfilePage({super.key});

  @override
  _EditUserProfilePageState createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends State<EditUserProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String? _validateField(String value, String fieldName) {
    if (value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot userInfo = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        _usernameController.text = userInfo.get('username');
        _addressController.text = userInfo.get('address');
      });
    }
  }

  Future<void> _saveChanges() async {

    if (_validateField(_usernameController.text, 'Username') != null || 
        _validateField(_addressController.text, 'Address') != null) {

      showErrorDialog(context, 'Please fill all the fields');
      return;
    }

    setState(() {
      _isSaving = true; // Show loading overlay
    });

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'username': _usernameController.text,
          'address': _addressController.text,
        });

        showSuccessDialog(
                context, 
                'Your profile changes have been saved. Please login again.', 
                () {
                    Navigator.of(context).pop(); // Close the dialog
                    _logoutUser(); // Call the logout function
                }
            );
      } catch (e) {
        showErrorDialog(context, 'Error saving changes: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false; // Hide loading overlay
          });
        }
      }
    }
  }

  void _logoutUser() {
    FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.grey.withOpacity(0.5),
          ),
        ),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              "Edit Profile",
              style: TextStyle(color: Colors.white),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            elevation: 10,
            shadowColor: Colors.green.withOpacity(0.5),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    errorText: _validateField(_usernameController.text, 'Username'),
                  ),
                  onEditingComplete: () => setState(() {}),
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    errorText: _validateField(_addressController.text, 'Address'),
                  ),
                  onEditingComplete: () => setState(() {}),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
        if (_isSaving) _buildLoadingOverlay(), // Show loading overlay when saving
      ],
    );
  }
}
