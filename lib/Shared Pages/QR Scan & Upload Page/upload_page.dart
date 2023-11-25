import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/home_page.dart';

class UploadPage extends StatefulWidget {
  final String locationName;

  const UploadPage({Key? key, required this.locationName}) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> images = [];
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null && images.length < 2) {
      setState(() {
        images.add(selected);
      });
    }
  }

  Future<void> _uploadImages() async {

    setState(() {
      _isUploading = true; // Start uploading
    });

    try {
      List<String> downloadUrls = [];

      for (var img in images) {
        String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}_${img.path.split('/').last}';
        firebase_storage.UploadTask uploadTask = 
            firebase_storage.FirebaseStorage.instance.ref(fileName).putFile(File(img.path));

        // Wait for the upload to complete
        await uploadTask.whenComplete(() {});
        String downloadUrl = await firebase_storage.FirebaseStorage.instance
            .ref(fileName)
            .getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      // Save the location name and image URLs in Firestore
      FirebaseFirestore.instance.collection('uploads').add({
        'location': widget.locationName,
        'images': downloadUrls,
      });

      // Notify user of success
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload successful!")));
      _showSuccessDialog(); // Show the success message and navigate
    } catch (e) {
      // Handle errors
      print('Error during upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    } finally {
      setState(() {
        _isUploading = false; // Stop uploading
      });
    }
  }

  Future<void> _reselectImage(int index) async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);

    if (selected != null) {
      setState(() {
        images[index] = selected; // Replace the image at the specified index
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
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
      Navigator.of(context).pop(); // Close the dialog
      _navigateToHomePage(); // Navigate to home page
    });
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()), // Replace with your HomePage widget
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Picture for ${widget.locationName}'),
      ),
      body : _isUploading 
                ? Center(child: CircularProgressIndicator()) // Show loading indicator
           : SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Image before throw:'),
              if (images.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Image.file(File(images[0].path), fit: BoxFit.cover),
                    ),
                    ElevatedButton(
                      onPressed: () => _reselectImage(0),
                      child: const Text('Reselect Image'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () => _pickImage(),
                  child: const Text('Select Image'),
                ),

              Text('Image after throw:'),
              if (images.length > 1)
                Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Image.file(File(images[1].path), fit: BoxFit.cover),
                    ),
                    ElevatedButton(
                      onPressed: () => _reselectImage(1),
                      child: const Text('Reselect Image'),
                    ),
                  ],
                )
              else if (images.length == 1)
                ElevatedButton(
                  onPressed: () => _pickImage(),
                  child: const Text('Select Image'),
                ),

              if (images.length == 2)
                ElevatedButton(
                  onPressed: _uploadImages,
                  child: const Text('Submit Images'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
