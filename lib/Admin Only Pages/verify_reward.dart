import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class Upload {
  String locationName;
  List<String> imageUrls;
  String? userName;
  String? docId;

  Upload({
    required this.locationName, 
    required this.imageUrls, 
    this.userName,
    this.docId,
  });

  factory Upload.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Upload(
      locationName: data['location'] ?? '',
      imageUrls: List<String>.from(data['images'] ?? []),
      userName: data['username'] ?? '',
      docId: doc.id,
    );
  }
}

class VerifyRewardPage extends StatefulWidget {
  const VerifyRewardPage({super.key});

  @override
  _RewardPageState createState() => _RewardPageState();
}

class _RewardPageState extends State<VerifyRewardPage> {
  List<Upload> uploads = [];
  String? selectedLocation;
  Upload? selectedUpload;

  @override
  void initState() {
    super.initState();
    fetchUploads().then((data) {
      setState(() => uploads = data);
    });
  }

  Future<List<Upload>> fetchUploads() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('uploads').get();
    return querySnapshot.docs.map((doc) => Upload.fromFirestore(doc)).toList();
  }

  Future<String?> getDocumentIdForUpload(String username, String locationName, List<String> imageUrls) async {
    try {
      // Convert imageUrls to a set for easy comparison
      Set<String> imageUrlSet = imageUrls.toSet();

      // Query the uploads collection where the location and username match
      var querySnapshot = await FirebaseFirestore.instance
          .collection('uploads')
          .where('username', isEqualTo: username)
          .where('location', isEqualTo: locationName)
          .get();

      for (var doc in querySnapshot.docs) {
        // Convert document's imageUrls to a set and compare with the provided imageUrlSet
        var docImageUrls = Set<String>.from(doc.data()['images'] ?? []);
        if (docImageUrls.length == imageUrlSet.length && docImageUrls.every(imageUrlSet.contains)) {
          // If sets are equal, return the document ID
          return doc.id;
        }
      }
      // If no matching document is found
      return null;
    } catch (e) {
      print('Error getting document ID: $e');
      return null;
    }
  }


  void _verifyUpload(Upload upload) async {
  // Assuming you are adding a fixed number of points for a verified upload
  const int pointsToAdd = 100;

  // Retrieve the document ID for the specific upload
  String? uploadDocId = await getDocumentIdForUpload(upload.userName!, upload.locationName, upload.imageUrls);
  
  if (uploadDocId != null) {
    // Retrieve the user's current points and add the new points
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users')
          .where('username', isEqualTo: upload.userName)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
          var userRef = userDoc.docs.first.reference;
          var userData = userDoc.docs.first.data();
          var newPoints = (userData['points'] ?? 0) + pointsToAdd;

          // Update the user's points
          await userRef.update({'points': newPoints});

          // Delete images from Firebase Storage
          for (String imageUrl in upload.imageUrls) {
            await firebase_storage.FirebaseStorage.instance.refFromURL(imageUrl).delete();
          }

          // Delete the document from Firestore
          await FirebaseFirestore.instance.collection('uploads').doc(uploadDocId).delete();

          // Update the UI to remove the verified upload
          setState(() {
            uploads.removeWhere((u) => u.docId == uploadDocId); // Remove using docId
            selectedUpload = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Verification successful, points added!'),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('User not found.'),
            backgroundColor: Colors.red,
          ));
        }
      } catch (e) {
        print('Error during verification: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Verification failed. Error during deletion.'),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      // No document found for the given upload
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload document not found.'),
        backgroundColor: Colors.red,
      ));
    }
  }


  void _rejectUpload(Upload upload) async {
  // Retrieve the document ID for the specific upload
  String? uploadDocId = await getDocumentIdForUpload(upload.userName!, upload.locationName, upload.imageUrls);

  if (uploadDocId != null) {
      try {
        // Delete images from Firebase Storage
        for (String imageUrl in upload.imageUrls) {
          if (imageUrl.isNotEmpty) {
            await firebase_storage.FirebaseStorage.instance.refFromURL(imageUrl).delete();
          }
        }

        // Delete the document from Firestore
        await FirebaseFirestore.instance.collection('uploads').doc(uploadDocId).delete();

        // Update the UI to remove the rejected upload
        setState(() {
          uploads.removeWhere((u) => u.docId == uploadDocId);
          selectedUpload = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload rejected and deleted successfully.'),
          backgroundColor: Colors.green,
        ));

      } catch (e) {
        print('Error during rejection: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Rejection failed. Error during deletion.'),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload document not found.'),
        backgroundColor: Colors.red,
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (selectedUpload != null) {
      // Show selected upload images with a single set of verify and reject buttons
      return Scaffold(
        appBar: AppBar(title: Text(selectedUpload!.locationName)),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: selectedUpload!.imageUrls.length,
                itemBuilder: (context, index) {
                  String label = index == 0 ? 'Image before throw:' : 'Image after throw:';
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: MediaQuery.of(context).size.width,
                          child: Image.network(selectedUpload!.imageUrls[index], fit: BoxFit.contain),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _verifyUpload(selectedUpload!),
                  child: Text('Verify'),
                  style: ElevatedButton.styleFrom(primary: Colors.green),
                ),
                ElevatedButton(
                  onPressed: () => _rejectUpload(selectedUpload!),
                  child: Text('Reject'),
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 200),
          ],
        ),
      );
    } else if (selectedLocation != null) {
      // Show uploads for the selected location
      List<Upload> locationUploads = uploads.where((u) => u.locationName == selectedLocation).toList();
      return Scaffold(
        appBar: AppBar(title: Text("@" + selectedLocation!)),
        body: ListView.builder(
          itemCount: locationUploads.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('${locationUploads[index].userName}\'s upload'), // Display the user's name
              onTap: () => setState(() => selectedUpload = locationUploads[index]),
            );
          },
        ),
      );
    } else {
      // Show list of locations
      Set<String> locations = uploads.map((u) => u.locationName).toSet();
      return Scaffold(
        appBar: AppBar(title: Text('Select Location')),
        body: ListView(
          children: locations.map((location) => ListTile(
            title: Text(location),
            onTap: () => setState(() {
              selectedLocation = location;
              selectedUpload = null; // Reset selected upload
            }),
          )).toList(),
        ),
      );
    }
  }
}