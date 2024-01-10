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

      // Get the drop point document by location name
      var dropPointSnapshot = await FirebaseFirestore.instance
          .collection('drop_points')
          .where('title', isEqualTo: widget.locationName)
          .limit(1)
          .get();

      if (dropPointSnapshot.docs.isEmpty) {
        throw Exception("Drop point not found");
      }

      var dropPointDocument = dropPointSnapshot.docs.first;
      int currentCapacity = dropPointDocument.data()['currentCapacity'] ?? 0;
      int maxCapacity = dropPointDocument.data()['maxCapacity'] ?? 0;

      // Check if max capacity is reached
      if (currentCapacity >= maxCapacity) {
        // Show dialog and navigate back without updating the current capacity
        _showBinFullDialog();
        return;
      }

      // Update current capacity in Firestore
      await dropPointDocument.reference.update({
        'currentCapacity': FieldValue.increment(1),
      });

      // Save the user name, location name and video URL in Firestore
      await FirebaseFirestore.instance.collection('uploads').add({
        'username' : GlobalUser.userName,
        'location': widget.locationName,
        'videoUrl': downloadUrl,
        'uploadedTime': FieldValue.serverTimestamp(),
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

  void _showBinFullDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Bin Full'),
          content: const Text('This bin is full already.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                Navigator.of(context).pop(); // Navigate back to the previous page
              },
            ),
          ],
        );
      },
    );
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
          onPressed: () => Navigator.of(context).pop(), // Go back on press
        ),
        title: Text(
          'Upload Video for ${widget.locationName}',
          style: const TextStyle(color: Colors.white),
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
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.blue, // Button text color
                      ),
                      child: Text(videoFile == null ? 'Select Video' : 'Reselect Video'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _uploadVideo,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.green, // Button text color
                      ),
                      child: const Text('Submit Video'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}