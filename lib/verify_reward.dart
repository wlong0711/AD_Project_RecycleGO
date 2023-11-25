import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Upload {
  String locationName;
  List<String> imageUrls;

  Upload({required this.locationName, required this.imageUrls});

  factory Upload.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Upload(
      locationName: data['location'] ?? '',
      imageUrls: List<String>.from(data['images'] ?? []),
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

  void _verifyUpload(Upload upload) {
    // Implement the logic for verifying the upload
    //print('Verified upload: ${upload.locationName}, Image: ${imageIndex + 1}');
  }

  void _rejectUpload(Upload upload) {
    // Implement the logic for rejecting the upload
    //print('Rejected upload: ${upload.locationName}, Image: ${imageIndex + 1}');
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
        appBar: AppBar(title: Text(selectedLocation!)),
        body: ListView.builder(
          itemCount: locationUploads.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('Upload ${index + 1}'),
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
