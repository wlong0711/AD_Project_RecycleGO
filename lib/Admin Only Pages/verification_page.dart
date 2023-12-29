import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:video_player/video_player.dart';
import '../models/upload.dart';

class VerificationPage extends StatefulWidget {
  final Upload upload;

  const VerificationPage({Key? key, required this.upload}) : super(key: key);

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  late VideoPlayerController _controller;
  // ignore: unused_field
  bool _isPlaying = false;
  // ignore: unused_field
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.upload.videoUrl)
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

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
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

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Column(
      children: [
        Expanded(
          child: VideoPlayerItem(videoUrl: widget.upload.videoUrl),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _verifyUpload(widget.upload),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Verify',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => _rejectUpload(widget.upload),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Reject',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );

    // Conditional loading overlay
    if (_isLoading) {
      mainContent = Stack(
        children: [
          mainContent, // The current content
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: _buildLoadingOverlay(), // Call the function that builds your loading indicator
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Verify Upload"),
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
      body: mainContent, // Use the mainContent which might be wrapped with loading overlay
    );
  }

  void _verifyUpload(Upload upload) async {
    bool? confirm = await _showConfirmDialog('Verify', 'Are you sure you want to verify this upload?');

    if (confirm == true) {

      setState(() => _isLoading = true);
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

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Verification successful, points added!'),
              backgroundColor: Colors.green,
            ));
            Navigator.pop(context, true); //Added
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('User not found.'),
              backgroundColor: Colors.red,
            ));
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Verification failed. Error: $e'),
            backgroundColor: Colors.red,
          ));
        } finally {
            setState(() => _isLoading = false);
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Upload document not found.'),
          backgroundColor: Colors.red,
        ));
      }
    } // if statement
  }

  void _rejectUpload(Upload upload) async {
    bool? confirm = await _showConfirmDialog('Reject', 'Are you sure you want to reject this upload?');
    
    if (confirm == true) {
      setState(() => _isLoading = true);

      String? uploadDocId = upload.docId; // Directly using the document ID

      if (uploadDocId != null) {
        try {
          // Delete video from Firebase Storage
          if (upload.videoUrl.isNotEmpty) {
            await firebase_storage.FirebaseStorage.instance.refFromURL(upload.videoUrl).delete();
          }

          // Delete the document from Firestore
          await FirebaseFirestore.instance.collection('uploads').doc(uploadDocId).delete();

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Upload rejected and deleted successfully.'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context, true); //Added
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Rejection failed. Error: $e'),
            backgroundColor: Colors.red,
          ));
        } finally {
            setState(() => _isLoading = false);
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Upload document not found.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<bool?> _showConfirmDialog(String action, String message) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$action Upload'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Dismiss dialog and return false
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Dismiss dialog and return true
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
  bool _isPlaying = false;
  bool _showControls = true; // Initially show the play icon

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

  String _formatDuration(Duration position) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(position.inHours);
    final minutes = twoDigits(position.inMinutes.remainder(60));
    final seconds = twoDigits(position.inSeconds.remainder(60));
    return "${int.parse(hours) > 0 ? '$hours:' : ''}$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final videoInitialized = _controller.value.isInitialized;
    final isBuffering = _controller.value.isBuffering;
    final desiredHeight = MediaQuery.of(context).size.height * 0.7;
    final desiredWidth = videoInitialized
        ? _controller.value.aspectRatio * desiredHeight
        : MediaQuery.of(context).size.width; // Default to full width if not initialized

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
          _showControls = true; // Show controls on every tap

          // Hide the controls after some time
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showControls = false; // Hide controls
              });
            }
          });
        });
      },
      child: Center(
        child: Container(
          width: desiredWidth, // for full width of the device
          height: desiredHeight, // modify this as per your aspect ratio need
          child: AspectRatio(
            aspectRatio: _controller.value.isInitialized ? _controller.value.aspectRatio : 16 / 9,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                VideoPlayer(_controller),
                if (!videoInitialized || isBuffering) const Center(child: CircularProgressIndicator()),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: EdgeInsets.all(10),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 10,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
                    duration: Duration(milliseconds: 300),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 30.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 10,
                  child: Text(
                    "${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}