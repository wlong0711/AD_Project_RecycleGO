import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class Upload {
  String locationName;
  List<String> videoUrls;
  String? userName;
  String? docId;

  Upload({
    required this.locationName,
    required this.videoUrls,
    this.userName,
    this.docId,
  });

  factory Upload.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Upload(
      locationName: data['location'] ?? '',
      videoUrls: List<String>.from(data['videos'] ?? []),
      userName: data['username'] ?? '',
      docId: doc.id,
    );
  }
}

class VerifyRewardPage extends StatefulWidget {
  const VerifyRewardPage({Key? key}) : super(key: key);

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

  void _verifyUpload(Upload upload) {
    // Add your verification logic here
  }

  void _rejectUpload(Upload upload) {
    // Add your rejection logic here
  }

  @override
  Widget build(BuildContext context) {
    if (selectedUpload != null) {
      return Scaffold(
        appBar: AppBar(title: Text(selectedUpload!.locationName)),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: selectedUpload!.videoUrls.length,
                itemBuilder: (context, index) {
                  return VideoPlayerItem(videoUrl: selectedUpload!.videoUrls[index]);
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
            SizedBox(height: 20),
          ],
        ),
      );
    } else if (selectedLocation != null) {
      List<Upload> locationUploads = uploads.where((u) => u.locationName == selectedLocation).toList();
      return Scaffold(
        appBar: AppBar(title: Text("@" + selectedLocation!)),
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
        appBar: AppBar(title: Text('Select Location')),
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

  const VideoPlayerItem({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Container(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
