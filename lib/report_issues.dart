import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

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
        title: Text("Report Issue"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Title'),
                onSaved: (value) => _title = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
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
                decoration: InputDecoration(labelText: 'Phone number'),
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
              SizedBox(height: 16),
              _image == null
                  ? ElevatedButton(
                      child: Text("Upload Image"),
                      onPressed: _pickImage,
                    )
                  : Image.file(_image!),
              SizedBox(height: 16),
              ElevatedButton(
                child: Text("Submit Report"),
                onPressed: _submitReport,
              ),
            ],
          ),
        ),
      ),
    );
  }

void _pickImage() async {
  final ImagePicker _picker = ImagePicker();
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
    pickedFile = await _picker.pickImage(source: choice);

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report submitted successfully')));
      // Navigator.of(context).pop();
    } catch (e) {
      // Log the error
      print('Error submitting report: $e');

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit report. Please try again later.')));
    }
  }
}

}
