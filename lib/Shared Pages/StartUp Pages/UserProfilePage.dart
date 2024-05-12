import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recycle_go/Admin%20Only%20Pages/register_admin.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/home_page.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/welcome_page.dart';
import 'package:recycle_go/models/global_user.dart';
import 'edit_user_profile_page.dart'; // Ensure correct import path

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

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

  Future<void> _confirmLogout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      _logout();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        // Navigate to the HomePage when the back button is pressed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return false; // return false to cancel the default back button action
      },
      child: Scaffold(
        appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
          onPressed: () => Navigator.of(context).pop('refresh'), // Go back on press
        ),
        title: const Text(
          "User Profile",
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
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _confirmLogout,
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
                  const SizedBox(height: 10),
                  if (GlobalUser.userLevel == 1) // Conditionally display 'Admin Account' text
                    Center(
                      child: Text(
                        'Admin Account',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 10),
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
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.green, // Button text color
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  if (GlobalUser.userLevel == 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to RegisterAdminPage
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterAdminPage()));
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.blue,
                        ),
                        child: const Text('Register for Admin'),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    child: ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.red, // Button text color
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
