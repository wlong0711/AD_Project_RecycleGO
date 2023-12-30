import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/welcome_page.dart';
import 'package:recycle_go/models/global_user.dart';


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

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot userInfo = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        userData = userInfo;
      });
    }
  }

  // Logout function
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate back to the login page or another appropriate page
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const WelcomePage())); // Assuming LoginPage is the route you want to go back to
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

  Future<void> _deleteAccount() async {
    try {
      // Attempt to delete the user's Firestore document first
      String? username = GlobalUser.userName;
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (userQuery.docs.isNotEmpty) {
        String docId = userQuery.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      }

      // Attempt to delete the user's Firebase authentication record
      await user!.delete();

      // Navigate the user back to the Welcome Page or another appropriate page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle reauthentication or other Firebase auth errors
      if (e.code == 'requires-recent-login') {
        print('User needs to reauthenticate. ${e.message}');
        _promptReauthentication();
        // Prompt the user to reauthenticate
      } else {
        // Other errors
        print("Error deleting account: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete account: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error deleting account: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete account: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _promptReauthentication() async {
    // You can modify this to fit your UI needs
    String email = user!.email!;  // Assuming the user's email is not null
    TextEditingController passwordController = TextEditingController();

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reauthenticate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Please enter your password to confirm account deletion.'),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // User confirmed to reauthenticate, now call reauthenticateUser
      await reauthenticateUser(email, passwordController.text);
    }
  }

  Future<void> reauthenticateUser(String email, String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
          email: email, password: password);
      
      await user!.reauthenticateWithCredential(credential);

      // After reauthentication, attempt to delete the account again
      await _deleteAccount();
    } on FirebaseAuthException catch (e) {
      print("Error during reauthentication: $e");
      // Handle reauthentication errors here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reauthentication failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Adjust the space
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
                Expanded(
                  child: ListView(
                    // Use ListView for other details for better handling of overflow and larger amount of data
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text("Email: ${user!.email ?? 'Not available'}"),
                      ),
                      // ... Add more user details if needed ...
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 130),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.red, // White text color
                          ),
                          onPressed: _logout,
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Logout',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _confirmDeleteAccount(),
                        child: Text('Delete Account'),
                        style: ElevatedButton.styleFrom(primary: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}