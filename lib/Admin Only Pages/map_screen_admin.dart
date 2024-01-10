import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:recycle_go/Shared%20Pages/Transition%20Page/transition_page.dart';
import 'manage_drop_point_map.dart';

class MapScreenAdmin extends StatefulWidget {
  const MapScreenAdmin({super.key, required this.title});

  final String title;

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreenAdmin> {
  GoogleMapController? mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng _initialPosition = const LatLng(0.0, 0.0);
  final Set<Marker> _markers = {};

  OverlayEntry? _overlayEntry;
  final int loadingTimeForOverlay = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOverlay();
      }
    });
    _determinePosition();
    _loadDropPoints();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => TransitionOverlay(
        iconData: Icons.admin_panel_settings, // The icon you want to show
        duration: Duration(seconds: loadingTimeForOverlay), // Duration for the transition
        pageName: "Loading Admin Map",
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

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When permissions are granted, get the current position
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });

    mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: _initialPosition,
        zoom: 18.0,
      ),
    ));
  }

  // Declare a list to hold the filter criteria. This list will be updated based on user selections.
List<String> _filterCriteria = [];

void _loadDropPoints() {
  FirebaseFirestore.instance.collection('drop_points').snapshots().listen((snapshot) {
    setState(() {
      _markers.clear();
      for (var doc in snapshot.docs) {
        Map<String, dynamic> pointData = doc.data();
        // Check if the drop point matches the filter criteria
        if (_matchesFilter(pointData['recycleItems'])) {
          LatLng point = LatLng(pointData['latitude'], pointData['longitude']);
          _markers.add(Marker(
            markerId: MarkerId(doc.id),
            position: point,
            icon: BitmapDescriptor.defaultMarkerWithHue(_getBinColorHue(pointData['currentCapacity'])),
            infoWindow: InfoWindow(
              title: pointData['title'],
              snippet: 'Tap here for details',
              onTap: () {
                _showDropPointDetails(pointData);
              },
            ),
            onTap: () {
              // This onTap is for the marker itself, not the InfoWindow
            },
          ));
        }
      }
    });
  });
}

double _getBinColorHue(int capacity) {
  if (capacity <= 10) return BitmapDescriptor.hueGreen; // Green for empty
  if (capacity <= 20) return BitmapDescriptor.hueYellow; // Yellow for half full
  if (capacity <= 29) return BitmapDescriptor.hueOrange; // Orange for about full
  return BitmapDescriptor.hueRed; // Red for full
}

// Helper function to determine if a drop point matches the filter criteria
bool _matchesFilter(List<dynamic> dropPointItems) {
  if (_filterCriteria.isEmpty) {
    return true; // If no filter criteria, everything matches
  }
  for (var item in _filterCriteria) {
    if (!dropPointItems.contains(item)) {
      return false; // If any item in the filter is not present, it's not a match
    }
  }
  return true; // All filter items are present
}

// Define a method to update the filter criteria based on user selection
void _updateFilterCriteria(List<String> newCriteria) {
  setState(() {
    _filterCriteria = newCriteria;
    _loadDropPoints(); // Reload points with the new filter
  });
}

  void _showDropPointDetails(Map<String, dynamic> pointData) {
    int currentCapacity = pointData['currentCapacity'] ?? 0;
    int maxCapacity = pointData['maxCapacity'] ?? 0;
    String capacityInfo = 'Capacity: $currentCapacity/$maxCapacity';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            pointData['title'] ?? 'Not available',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green),
                  title: const Text('Address', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    pointData['address'] ?? 'Not available',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.event, color: Colors.green),
                  title: const Text('Pickup Days', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    (pointData['pickupDays'] as List<dynamic>).join(', '),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.recycling, color: Colors.green),
                  title: const Text('Recyclable Items', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    (pointData['recycleItems'] as List<dynamic>).join(', '),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.storage, color: Colors.green),
                  title: const Text('Capacity', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    capacityInfo,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Navigate', style: TextStyle(color: Colors.blue, fontSize: 18)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _navigateToPoint(pointData['latitude'], pointData['longitude']); // Add this line
              },
            ),
            TextButton(
              child: const Text('Close', style: TextStyle(color: Colors.blue, fontSize: 18)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

void _navigateToPoint(double latitude, double longitude) async {
  String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving";

  if (await canLaunch(googleMapsUrl)) {
    await launch(googleMapsUrl);
  } else {
    print('Could not launch $googleMapsUrl');
    // Optionally, show a dialog or a toast to inform the user that the URL could not be opened
  }
}

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _searchAndNavigate() async {
  String searchText = _searchController.text.trim();

  if (searchText.isEmpty) return;

  // Query Firestore for drop points with a matching name
  var querySnapshot = await FirebaseFirestore.instance
      .collection('drop_points')
      .where('title', isEqualTo: searchText)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    var dropPointData = querySnapshot.docs.first.data();
    LatLng point = LatLng(dropPointData['latitude'], dropPointData['longitude']);

    // Navigate to the drop point location
    mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: point,
        zoom: 20.0,
      ),
    ));
  } else {
    print("No matching drop points found");
  }
}


final List<String> _selectedFilters = [];

void _showFilterDialog() async {
  List<String> recyclableItems = ['Paper', 'Glass', 'Cans', 'Plastic'];

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Select Recyclable Items'),
            content: SingleChildScrollView(
              child: ListBody(
                children: recyclableItems.map((item) {
                  return CheckboxListTile(
                    value: _selectedFilters.contains(item),
                    title: Text(item),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedFilters.add(item);
                        } else {
                          _selectedFilters.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Apply'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateFilterCriteria(_selectedFilters);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
          onPressed: () => Navigator.of(context).pop('refresh'), // Go back on press
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
          elevation: 10,
          shadowColor: Colors.green.withOpacity(0.5),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {}); // update the visibility of the clear button
                    },
                    onSubmitted: (value) => _searchAndNavigate(),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.black),
                      hintText: 'Enter location name',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Visibility(
                  visible: _searchController.text.isNotEmpty,
                  child: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {}); // update the visibility of the clear button
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 18.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
      
      floatingActionButton: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 120.0, left: 25.0), // Adjust these values as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Important for proper spacing
              children: [
                _buildGradientFAB(
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter Drop Points',
                  icon: Icons.filter_list,
                ),
                const SizedBox(height: 10),
                _buildGradientFAB(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DropPointMap())),
                  tooltip: 'Manage Drop Points',
                  icon: Icons.settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientFAB({required VoidCallback onPressed, required String tooltip, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        heroTag: null,
        backgroundColor: Colors.transparent,
        elevation: 0, // Use null or unique tag for each FAB
        child: Icon(icon, color: Colors.white), // Use null or unique tag for each FAB
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed, required String tooltip}) {
    return SizedBox(
      height: 45.0, // Standard FAB size
      width: 45.0,  // Standard FAB size
      child: FloatingActionButton(
        onPressed: onPressed, // Adjust icon size if needed
        tooltip: tooltip,
        child: Icon(icon, size: 24.0),
      ),
    );
  }
}