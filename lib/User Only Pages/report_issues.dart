import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recycle_go/Shared%20Pages/Transition%20Page/transition_page.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key, required String title});

  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  // String? _phoneNumber;
  File? _image;

  OverlayEntry? _overlayEntry;
  final int loadingTimeForOverlay = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOverlay();
      }
    });
  }

  @override
  void dispose() {
    // Dispose the controllers when the widget is removed from the widget tree
    titleController.dispose();
    descriptionController.dispose();
    // If you have any other controllers or listeners, dispose of them here as well
    super.dispose(); // Don't forget to call super.dispose() at the end
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => TransitionOverlay(
        iconData: Icons.report_problem, // The icon you want to show
        duration: Duration(seconds: loadingTimeForOverlay), // Duration for the transition
        pageName: "Preparing Report Form",
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(Duration(seconds: loadingTimeForOverlay), () {
      if (mounted) {
        _removeOverlay();
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Issue"),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              const SizedBox(height: 16),
              _buildImageUploadSection(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitReport,
                child: const Text("Submit Report"),
              ),
            ],
          ),
        ),
      ),
    );
  }

void _pickImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? pickedFile;

  // Show the option dialog
  final choice = await showDialog<ImageSource>(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('Select Image Source'),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, ImageSource.camera); },
            child: const Text('Camera'),
          ),
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, ImageSource.gallery); },
            child: const Text('Gallery'),
          ),
        ],
      );
    }
  );

  // Check the choice and act accordingly
  if (choice != null) {
    pickedFile = await picker.pickImage(source: choice);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile!.path);
      });
    }
  }
}


Future<void> _submitReport() async {
  if (_formKey.currentState!.validate()) {

    String title = titleController.text;
    String description = descriptionController.text;

    // Checking for user authentication
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog("No authenticated user found. Please login first.");
      return;
    }

    try {
      // Fetch user data from Firestore
      DocumentSnapshot userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

      String imageUrl = '';
      if (_image != null) {
        String fileName = Path.basename(_image!.path);
        Reference firebaseStorageRef = FirebaseStorage.instance.ref('uploads/$fileName');

        try {
          UploadTask uploadTask = firebaseStorageRef.putFile(_image!);
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
          imageUrl = await taskSnapshot.ref.getDownloadURL();
        } catch (e) {
          _showErrorDialog("Failed to upload image: $e");
          return;
        }
      }

      // Save report details to Firestore under "reports issues" collection
      await FirebaseFirestore.instance.collection('reports issues').add({
        'userId': user.uid,
        'username': userData['username'], // Assuming these fields exist in your documents
        'email': userData['email'],
        'title': title,
        'description': description,
        // 'phoneNumber': _phoneNumber,  // Uncomment if needed
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'to solve',
      });

      // Show a success message upon successful submission
      await _showSuccessDialog();
    } catch (e) {
      _showErrorDialog("Failed to submit report: $e");
    }
  }
}



Future<void> _showSuccessDialog() async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button to close
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Report Submitted'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Your report has been successfully submitted.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Back To Homepage'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Navigate back to the homepage
            },
          ),
        ],
      );
    },
  );
}

void _showErrorDialog(String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false, 
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(message),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}

Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitReport,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.green, // Button text color
      ),
      child: const Text("Submit Report"),
    );
  }

  Widget _buildImageUploadSection() {
    return _image == null
        ? ElevatedButton(
            onPressed: _pickImage,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.green, // Button text color
            ),
            child: const Text("Upload Image"),
          )
        : Column(
            children: [
              Image.file(_image!),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue,
                    ),
                    child: const Text("Re-upload Image"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _deleteImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.red,
                    ),
                    child: const Text("Delete Image"),
                  ),
                ],
              ),
            ],
          );
  }

  void _deleteImage() {
    setState(() {
      _image = null;
    });
  }

}