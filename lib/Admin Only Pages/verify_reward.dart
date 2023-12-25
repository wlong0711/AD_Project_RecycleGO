import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class Upload {
  String locationName;
  String videoUrl;
  String? userName;
  String? docId;

  Upload({
    required this.locationName,
    required this.videoUrl,
    this.userName,
    this.docId,
  });

  factory Upload.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Upload(
      locationName: data['location'] ?? '',
      videoUrl: data['videoUrl'] ?? '', // Assuming there is a single 'video' field
      userName: data['username'] ?? '',
      docId: doc.id,
    );
  }
}

class VerifyRewardPage extends StatefulWidget {
  const VerifyRewardPage({super.key});

  @override
  _VerifyRewardPageState createState() => _VerifyRewardPageState();
}

class _VerifyRewardPageState extends State<VerifyRewardPage> {
  List<Upload> uploads = [];
  String? selectedLocation;
  Upload? selectedUpload;

  @override
  void initState() {
    super.initState();
    fetchUploads();
  }

  Future<void> fetchUploads() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('uploads').get();
    List<Upload> fetchedUploads = querySnapshot.docs.map((doc) => Upload.fromFirestore(doc)).toList();
    setState(() => uploads = fetchedUploads);
  }

  void _verifyUpload(Upload upload) async {
  // Assuming you are adding a fixed number of points for a verified upload
  const int pointsToAdd = 100;

  // Retrieve the document ID for the specific upload
  String? uploadDocId = upload.docId; // Directly using the document ID

  if (uploadDocId != null) {
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

        // Delete video from Firebase Storage
        if (upload.videoUrl.isNotEmpty) {
          await firebase_storage.FirebaseStorage.instance.refFromURL(upload.videoUrl).delete();
        }

        // Delete the document from Firestore
        await FirebaseFirestore.instance.collection('uploads').doc(uploadDocId).delete();

        // Update the UI to remove the verified upload
        setState(() {
          uploads.removeWhere((u) => u.docId == uploadDocId);
          selectedUpload = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Verification successful, points added!'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User not found.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('Error during verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verification failed. Error during deletion.'),
        backgroundColor: Colors.red,
      ));
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Upload document not found.'),
      backgroundColor: Colors.red,
    ));
  }
}

void _rejectUpload(Upload upload) async {
  String? uploadDocId = upload.docId; // Directly using the document ID

  if (uploadDocId != null) {
    try {
      // Delete video from Firebase Storage
      if (upload.videoUrl.isNotEmpty) {
        await firebase_storage.FirebaseStorage.instance.refFromURL(upload.videoUrl).delete();
      }

      // Delete the document from Firestore
      await FirebaseFirestore.instance.collection('uploads').doc(uploadDocId).delete();

      // Update the UI to remove the rejected upload
      setState(() {
        uploads.removeWhere((u) => u.docId == uploadDocId);
        selectedUpload = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Upload rejected and deleted successfully.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print('Error during rejection: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rejection failed. Error during deletion.'),
        backgroundColor: Colors.red,
      ));
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Upload document not found.'),
      backgroundColor: Colors.red,
    ));
  }
}


  @override
  Widget build(BuildContext context) {
    if (selectedUpload != null) {
      return Scaffold(
        appBar: AppBar(
        title: const Text("Verify Rewards"),
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
        body: Column(
          children: [
            Expanded(
              child: VideoPlayerItem(videoUrl: selectedUpload!.videoUrl),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _verifyUpload(selectedUpload!),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Verify'),
                ),
                ElevatedButton(
                  onPressed: () => _rejectUpload(selectedUpload!),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    } else if (selectedLocation != null) {
      List<Upload> locationUploads = uploads.where((u) => u.locationName == selectedLocation).toList();
      return Scaffold(
        appBar: AppBar(
        title: Text("@${selectedLocation!}"),
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
        body: ListView.builder(
          itemCount: locationUploads.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('${locationUploads[index].userName}\'s upload'),
              onTap: () => setState(() => selectedUpload = locationUploads[index]),
            );
          },
        ),
      );
    } else {
      Set<String> locations = uploads.map((u) => u.locationName).toSet();
      return Scaffold(
        appBar: AppBar(
        title: const Text("Select Location"),
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
        body: ListView(
          children: locations.map((location) => ListTile(
            title: Text(location),
            onTap: () => setState(() {
              selectedLocation = location;
              selectedUpload = null;
            }),
          )).toList(),
        ),
      );
    }
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerItem({super.key, required this.videoUrl});

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                _buildPlayPauseOverlay(),
                VideoProgressIndicator(_controller, allowScrubbing: true),
              ],
            ),
          )
        : const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
  }

  Widget _buildPlayPauseOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Center(
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          size: 100.0,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }
}


