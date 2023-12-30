import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'UserProfilePage.dart'; // Import the UserProfilePage

class EditUserProfilePage extends StatefulWidget {
  const EditUserProfilePage({super.key});

  @override
  _EditUserProfilePageState createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends State<EditUserProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot userInfo =
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        _usernameController.text = userInfo['username'];
        _addressController.text = userInfo['address'];
      });
    }
  }

  // Save changes function
  Future<void> _saveChanges() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'username': _usernameController.text,
      'address': _addressController.text,
    });

    // Navigate back to the user profile page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const UserProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate back to the user profile page without saving changes
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const UserProfilePage()),
              );
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}