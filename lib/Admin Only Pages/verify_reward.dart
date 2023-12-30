import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:recycle_go/Admin%20Only%20Pages/verification_page.dart';
import 'package:recycle_go/Shared%20Pages/Transition%20Page/transition_page.dart';
import 'package:video_player/video_player.dart';
import 'package:recycle_go/models/upload.dart';


class VerifyRewardPage extends StatefulWidget {
  const VerifyRewardPage({super.key});

  @override
  _VerifyRewardPageState createState() => _VerifyRewardPageState();
}

class _VerifyRewardPageState extends State<VerifyRewardPage> {
  List<Upload> uploads = [];
  List<String> locations = [];
  String? selectedLocation;
  Upload? selectedUpload;
  bool _isSortedByOldest = false;

  OverlayEntry? _overlayEntry;
  final int loadingTimeForOverlay = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOverlay();
      }
    });
    fetchUploads();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => TransitionOverlay(
            iconData: Icons.verified_user, // The icon you want to show
            duration: Duration(seconds: loadingTimeForOverlay), // Duration for the transition
            pageName: "Fetching Upload List",
          ),
    );

    // Find the overlay context
    final overlay = Overlay.of(context);
    // ignore: unnecessary_null_comparison
    if (overlay != null) {
      // Insert the overlay
      overlay.insert(_overlayEntry!);

      // Simulate a loading duration and then remove the overlay
      Future.delayed(Duration(seconds: loadingTimeForOverlay), () {
        if (mounted) {
          _removeOverlay();
        }
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> fetchUploads() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('uploads').get();
    List<Upload> fetchedUploads = querySnapshot.docs.map((doc) => Upload.fromFirestore(doc)).toList();

    // Sort the uploads initially as per the default sort order
    fetchedUploads.sort((a, b) {
      var aTime = a.uploadedTime?.toDate() ?? DateTime.now();
      var bTime = b.uploadedTime?.toDate() ?? DateTime.now();
      return _isSortedByOldest ? bTime.compareTo(aTime) : aTime.compareTo(bTime); // Sort by latest or oldest initially
    });

    setState(() {
      uploads = fetchedUploads;
      // Create a set to eliminate duplicates and then convert it to a list
      locations = fetchedUploads.map((u) => u.locationName).toSet().toList();
      // If you want to sort the locations, add the following line
      locations.sort((a, b) => a.compareTo(b));
      print("Locations after fetch: $locations"); // Debug print
      if (!locations.contains(selectedLocation)) {
        selectedLocation = null; // Reset if no longer valid
      }
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _isSortedByOldest = !_isSortedByOldest; // Toggle sorting order
      uploads.sort((a, b) {
        // Compare timestamps, nulls last
        var aTime = a.uploadedTime?.toDate() ?? DateTime.now();
        var bTime = b.uploadedTime?.toDate() ?? DateTime.now();
        return _isSortedByOldest ? bTime.compareTo(aTime) : aTime.compareTo(bTime); // Sort by latest or oldest
      });
    });
  }

  Widget _buildDropdownMenu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7, // Set the width to 80% of screen width
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.0),
            border: Border.all(color: Colors.green, width: 2),
            color: Colors.green, // Background color
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero, // Zero padding inside the button
                // Adjust alignment to center if needed
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectedLocation = newValue;
                  selectedUpload = null;
                });
              },
              items: locations.map<DropdownMenuItem<String>>((String location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Container(
                    alignment: Alignment.center, // Center the text for each item
                    height: 48, // Standard height for each item to align text and icon
                    child: Text(
                      location,
                      textAlign: TextAlign.center, // Center align text
                      style: const TextStyle(fontSize: 20), // Increase font size for items
                    ),
                  ),
                );
              }).toList(),
              dropdownColor: Colors.green,
              icon: Container(),
              isExpanded: true, // Important to expand the dropdown button
              hint: Container(
                alignment: Alignment.center, // Center the hint text
                child: const Text(
                  'Select Location',
                  textAlign: TextAlign.center, // Center align text
                  style: TextStyle(
                    fontSize: 20, // Increase font size for hint
                    color: Colors.white, // Font color for hint
                  ),
                ),
              ),
              style: const TextStyle(
                fontSize: 20, // Increase font size
                color: Colors.white, // Font color
              ),
              alignment: Alignment.center, // Align the dropdown content
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadsList() {
    List<Upload> locationUploads = selectedLocation == null
        ? []
        : uploads.where((u) => u.locationName == selectedLocation).toList();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 5), // Border for the entire container
          borderRadius: BorderRadius.circular(18),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Apply the same borderRadius to the inner list
          child: ListView.separated(
            itemCount: locationUploads.length,
            itemBuilder: (context, index) {

              Timestamp? timestamp = locationUploads[index].uploadedTime;
              DateTime dateTime = timestamp?.toDate() ?? DateTime.now();
              String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(dateTime); // Using DateFormat from intl package
              // Wrap each list item in a container with a bottom border
              return Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 179, 224, 128),
                  border: Border(
                    bottom: BorderSide(color: Colors.green, width: 2), // Bottom border for each item
                  ),
                ),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${locationUploads[index].userName}\'s upload'),
                      Text(
                        formattedTime, // Display formatted timestamp
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerificationPage(upload: locationUploads[index]),
                      ),
                    ).then((value) {
                      if (value == true) {
                        fetchUploads(); // Refresh list after navigation
                      }
                    });
                  },
                ),
              );
            },
            separatorBuilder: (context, index) => SizedBox(height: 0), // Remove space between items if not needed
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
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
        actions: <Widget>[
          InkWell(
            onTap: _toggleSortOrder,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort by ${_isSortedByOldest ? "Oldest" : "Latest"}',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold, // Make text bold
                      fontSize: 16, // Optionally adjust font size as needed
                    ),
                  ),
                  Icon(
                    _isSortedByOldest ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDropdownMenu(),
          selectedLocation != null ? _buildUploadsList() : Container(),
          //_buildBody(),
        ],
      ),
    );
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