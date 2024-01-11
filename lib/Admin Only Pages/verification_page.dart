import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import '../models/upload.dart';

class VerificationPage extends StatefulWidget {
  final Upload upload;

  const VerificationPage({super.key, required this.upload});

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
        // Full screen semi-transparent overlay
        Positioned.fill(
          child: Container(
            color: Colors.grey.withOpacity(0.5), // Semi-transparent grey color
          ),
        ),
        // Centered loading indicator
        Center(
          child: Container(
            width: 80, // Set the width of the overlay
            height: 80, // Set the height of the overlay
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5), // Semi-transparent black for the loading box
              borderRadius: BorderRadius.circular(10), // Rounded corners for the loading box
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Verify',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () => _rejectUpload(widget.upload),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
          onPressed: () => Navigator.of(context).pop(), // Go back on press
        ),
        title: const Text(
          'Verify Upload',
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
          
          await FirebaseFirestore.instance.collection('uploads').doc(upload.docId).update({
            'status': 'Approved',
            'verifiedTime': FieldValue.serverTimestamp(),
          });

          if (userDoc.docs.isNotEmpty) {
            var userRef = userDoc.docs.first.reference;
            var userData = userDoc.docs.first.data();
            var newPoints = (userData['points'] ?? 0) + pointsToAdd;

            // Update the user's points
            await userRef.update({'points': newPoints});

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
      final TextEditingController reasonController = TextEditingController();

      // Show a dialog to enter the reason for rejection
      String? reason = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Rejection Reason'),
            content: TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'Reason for rejection'),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );

      if (reason != null && reason.isNotEmpty) {
        setState(() => _isLoading = true);

        try {
          // Update the upload status and rejection reason in Firestore
          await FirebaseFirestore.instance.collection('uploads').doc(upload.docId).update({
            'status': 'Rejected',
            'rejectionReason': reason,
            'verifiedTime': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Upload rejected.'),
            backgroundColor: Colors.green,
          ));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error during rejection: $e'),
            backgroundColor: Colors.red,
          ));
        } finally {
          setState(() => _isLoading = false);
          Navigator.pop(context, true); // Return to the previous screen with a result
        }
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

  const VideoPlayerItem({super.key, required this.videoUrl});

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
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showControls = false; // Hide controls
              });
            }
          });
        });
      },
      child: Center(
        child: SizedBox(
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
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 10,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
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
                    style: const TextStyle(color: Colors.white),
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