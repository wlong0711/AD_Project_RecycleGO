import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recycle_go/Component/dialogs.dart';
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
  bool _isSubmitting = false;

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
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop('refresh'),
            ),
            title: const Text(
              "Report Issue",
              style: TextStyle(color: Colors.white),
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
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
        if (_isSubmitting) _buildLoadingOverlay(),
      ],
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

    setState(() {
      _isSubmitting = true; // Show the loading overlay
    });

    String title = titleController.text;
    String description = descriptionController.text;

    // Checking for user authentication
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showErrorDialog(context, "No authenticated user found. Please login first.");
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
          showErrorDialog(context, "Failed to upload image: $e"); 
          return;
        }
      }

      // Save report details to Firestore under "reports issues" collection
      await FirebaseFirestore.instance.collection('issues').add({
        'userId': user.uid,
        'username': userData['username'], // Assuming these fields exist in your documents
        'email': userData['email'],
        'title': title,
        'description': description,
        // 'phoneNumber': _phoneNumber,  // Uncomment if needed
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Show a success message upon successful submission
      showSuccessDialog(context, 'Your report has been successfully submitted.', () {
        Navigator.of(context).pop('refresh');
      });
      setState(() {
        _isSubmitting = false; // Hide the loading overlay after submission is done
      });
    } catch (e) {
      showErrorDialog(context, 'Failed to submit report: $e');
    }
  }
}

Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.grey.withOpacity(0.5),
          ),
        ),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
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
              foregroundColor: Colors.white, backgroundColor: Colors.blue, // Button text color
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