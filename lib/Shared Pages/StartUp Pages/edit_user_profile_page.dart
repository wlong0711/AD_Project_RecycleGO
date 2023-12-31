import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'UserProfilePage.dart';  // Ensure this is the correct path for your UserProfilePage.

class EditUserProfilePage extends StatefulWidget {
  const EditUserProfilePage({super.key});

  @override
  _EditUserProfilePageState createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends State<EditUserProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _passwordError = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'username': _usernameController.text,
        'address': _addressController.text,
      });
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const UserProfilePage()));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    _passwordController.clear();
    _passwordError = '';

    bool confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,  // User must tap a button to close the dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please confirm your password to delete your account. This action cannot be undone.'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: _passwordError.isEmpty ? null : _passwordError,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                try {
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: user!.email!,
                    password: _passwordController.text,
                  );
                  await user!.reauthenticateWithCredential(credential);
                  await _deleteAccount();
                  Navigator.of(dialogContext).pop(true);
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'wrong-password') {
                    setState(() => _passwordError = 'Incorrect password.');
                  } else {
                    setState(() => _passwordError = 'An unexpected error occurred.');
                  }
                }
              },
            ),
          ],
        );
      },
    ) ?? false;  // Default to false if dialog is dismissed without tapping Confirm or Cancel

    // Proceed with deletion if confirmed
    if (confirmed) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (user == null || user!.uid.isEmpty) {
      setState(() => _passwordError = 'No authenticated user found.');
      return;
    }

    try {
      // Delete user data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();
      // Delete user from Firebase Auth
      await user!.delete();
      // Navigate to UserProfileLoginPage or equivalent
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserProfilePage()));  // Make sure to have a proper landing page
    } on FirebaseAuthException catch (e) {
      setState(() => _passwordError = e.message ?? 'Failed to delete user.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
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
        actions: [
          TextButton(
            onPressed: _confirmDeleteAccount,
            child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const UserProfilePage()));
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
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
    );
  }
}
