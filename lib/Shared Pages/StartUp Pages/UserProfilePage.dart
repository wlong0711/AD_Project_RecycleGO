import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/welcome_page.dart';
import 'package:recycle_go/models/global_user.dart';
import 'edit_user_profile_page.dart'; // Ensure correct import path
import 'login.dart'; // Ensure correct import path
import 'welcome_page.dart'; // Ensure correct import path or your designated landing page post-logout

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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
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
