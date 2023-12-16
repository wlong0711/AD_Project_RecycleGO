import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/home_page.dart';
import 'package:recycle_go/models/global_user.dart';

class UploadPage extends StatefulWidget {
  final String locationName;
  final VoidCallback onUploadCompleted;

  const UploadPage({super.key, required this.locationName, required this.onUploadCompleted});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? videoFile;
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    final XFile? selected = await _picker.pickVideo(source: ImageSource.gallery);
    if (selected != null) {
      setState(() {
        videoFile = selected;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select a video first."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _isUploading = true; // Start uploading
    });

    try {
      String fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}_${videoFile!.name}';
      firebase_storage.UploadTask uploadTask = 
          firebase_storage.FirebaseStorage.instance.ref(fileName).putFile(File(videoFile!.path));

      // Wait for the upload to complete
      await uploadTask.whenComplete(() {});
      String downloadUrl = await firebase_storage.FirebaseStorage.instance
          .ref(fileName)
          .getDownloadURL();

      // Save the user name, location name and video URL in Firestore
      await FirebaseFirestore.instance.collection('uploads').add({
        'username' : GlobalUser.userName,
        'location': widget.locationName,
        'videoUrl': downloadUrl,
      });

      // Notify user of success
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Upload successful!"),
        backgroundColor: Colors.green,
      ));

      widget.onUploadCompleted(); // Trigger the onUploadCompleted callback
      _navigateToHomePage(); // Navigate to home page
    } catch (e) {
      // Handle errors
      print('Error during video upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Upload error: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isUploading = false; // Stop uploading
      });
    }
  }

  void _showSuccessDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Upload Successful"),
            Text("Redirecting... Please wait"),
          ],
        ),
      );
    },
  );

  // Assuming you want to show the dialog for 2 seconds
  Future.delayed(const Duration(seconds: 2), () {
    widget.onUploadCompleted(); // Call the callback to set the flag
    Navigator.of(context).pop(); // Close the dialog
    _navigateToHomePage(); // Navigate to home page
  });
}


  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Video for ${widget.locationName}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
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
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (videoFile != null)
                      const Icon(Icons.video_library, size: 100),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickVideo,
                      child: Text(videoFile == null ? 'Select Video' : 'Reselect Video'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _uploadVideo,
                      child: const Text('Submit Video'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}