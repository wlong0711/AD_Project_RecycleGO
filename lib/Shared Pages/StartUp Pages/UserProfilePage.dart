import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/welcome_page.dart';
import 'edit_user_profile_page.dart'; // Import the EditUserProfilePage
import 'login.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  DocumentSnapshot? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
  return Column(
    children: [
      Divider(color: Colors.lightGreen, thickness: 2),
      ListTile(
        leading: Icon(icon),
        title: Text("$title: $content"),
      ),
    ],
  );
}

Future<void> _loadUserData() async {
  if (user != null) {
    await user!.reload(); // Reload the user to get the latest email verification status
    user = FirebaseAuth.instance.currentUser; // Update user variable

    if (!user!.emailVerified) {
      // User's email is not verified, show a dialog and navigate to the login page
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Email Not Verified'),
            content: const Text(
                'Please verify your email before accessing your profile.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to the LoginPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // User's email is verified, proceed to load user data
      DocumentSnapshot userInfo =
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        userData = userInfo;
      });
    }
  }
}


  // Logout function
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate back to the login page or another appropriate page
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const EditUserProfilePage())); // Assuming LoginPage is the route you want to go back to
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
      actions: [
        TextButton(
          onPressed: () {
            // Navigate to EditUserProfilePage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WelcomePage()),
            );
          },
          child: const Text('Logout', style: TextStyle(color: Colors.white)), //Logout
        ),
      ],
    ),
    body: userData == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blueGrey,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      userData!['username'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              _buildInfoSection('Email', user!.email ?? 'Not available', Icons.email),
              _buildInfoSection('Address', userData!['address'] ?? 'Not available', Icons.location_on),
              _buildInfoSection('Phone', userData!['phoneNumber'] ?? 'Not available', Icons.phone),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 130),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green,
                  ),
                  onPressed: _logout,
                  child: const Padding(
                    padding: EdgeInsets.all(7.0),
                    child: Text(
                      'Edit',//Edit
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
  );
}
}

        // actions: [
        //   // Text Button for logout
        //   TextButton.icon(
        //     icon: Icon(Icons.logout, color: Colors.white), // Change color to match appBar theme
        //     label: Text(
        //       'Logout',
        //       style: TextStyle(color: Colors.white), // Change color to match appBar theme
        //     ),
        //     onPressed: _logout,
        //   ),
        // ],
