import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/welcome_page.dart';
import 'edit_user_profile_page.dart'; // Ensure correct import path

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  DocumentSnapshot? userData;
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordValid = true; // To manage password validation state

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userInfo =
            await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        setState(() {
          userData = userInfo;
        });
      } catch (e) {
        print("Error loading user data: $e");
        // Handle or log error
      }
    }
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text("$title: $content"),
    );
  }

  Future<void> _deleteAccount() async {
    if (user == null) {
      setState(() => _isPasswordValid = false); // Indicate invalid password or user state
      return;
    }

    bool confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _isPasswordValid ? null : 'Invalid password.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: _passwordController.text,
        );
        await user!.reauthenticateWithCredential(credential);
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();
        await user!.delete();
        // Navigate to WelcomePage or your landing page post-account deletion
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomePage()));
      } catch (e) {
        print("Error deleting account: $e");
        setState(() => _isPasswordValid = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomePage()));
  }

  Future<void> _confirmDeleteAccount() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            child: Text('No'),
            onPressed: () => Navigator.of(context).pop(false), // User pressed No
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () => Navigator.of(context).pop(true), // User pressed Yes
          ),
        ],
      ),
    ) ?? false; // In case the user dismisses the dialog by tapping outside of it

    // If the user pressed "Yes", proceed with deleting the account
    if (confirm) {
      _deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditUserProfilePage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    userData!.get('username') ?? 'Not Available',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildInfoSection('Email', user!.email ?? 'Not Available', Icons.email),
                _buildInfoSection('Address', userData!.get('address') ?? 'Not Available', Icons.home),
                _buildInfoSection('Phone Number', userData!.get('phoneNumber') ?? 'Not Available', Icons.phone),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditUserProfilePage())),
                    child: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(primary: Colors.green),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  child: ElevatedButton(
                    onPressed: _deleteAccount,
                    child: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(primary: Colors.red),
                  ),
                ),
              ],
            ),
    );
  }
}
