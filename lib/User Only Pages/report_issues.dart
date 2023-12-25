import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key, required String title});

  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  String? _phoneNumber;
  File? _image;

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
                decoration: const InputDecoration(labelText: 'Title'),
                onSaved: (value) => _title = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone number'),
                onSaved: (value) => _phoneNumber = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number'; 
                  }
                  // Regex for validating phone number
                  String pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
                  RegExp regExp = RegExp(pattern);
                  if (!regExp.hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
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
    _formKey.currentState!.save();

    try {
      String imageUrl = '';
      if (_image != null) {
        // Upload image to Firebase Storage
        String fileName = Path.basename(_image!.path);  // Corrected this line
        Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');
        UploadTask uploadTask = firebaseStorageRef.putFile(_image!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
        imageUrl = await taskSnapshot.ref.getDownloadURL();
      }

      // Save report details to Firestore
      CollectionReference reports = FirebaseFirestore.instance.collection('reports issues');
      await reports.add({
        'title': _title,
        'description': _description,
        'phoneNumber': _phoneNumber,  // Ensure this matches your Firestore field name
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show a success message or navigate away
      await _showSuccessDialog();      // Navigator.of(context).pop();
    } catch (e) {
      // Log the error
      _showErrorDialog(e.toString());

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit report. Please try again later.')));
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
                      foregroundColor: Colors.white, backgroundColor: Colors.blue, // Button text color
                    ),
                    child: const Text("Re-upload Image"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _deleteImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.red, // Button text color
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
