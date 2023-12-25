import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/login.dart';


class UserProfilePage extends StatefulWidget {
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
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage())); // Assuming LoginPage is the route you want to go back to
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Adjust the space
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blueGrey,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        userData!['username'],
                        style: TextStyle(
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
                        leading: Icon(Icons.email),
                        title: Text("Email: ${user!.email ?? 'Not available'}"),
                      ),
                      // ... Add more user details if needed ...
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 130),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red, // Red background color
                            onPrimary: Colors.white, // White text color
                          ),
                          onPressed: _logout,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Logout',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

