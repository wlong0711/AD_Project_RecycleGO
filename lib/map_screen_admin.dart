import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'drop_point_map.dart';

class MapScreenAdmin extends StatefulWidget {
  const MapScreenAdmin({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreenAdmin> {
  GoogleMapController? mapController;
  TextEditingController _searchController = TextEditingController();
  LatLng _initialPosition = const LatLng(0.0, 0.0);
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadDropPoints();
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
            infoWindow: InfoWindow(
              title: pointData['title'],
              snippet: pointData['address'],
              onTap: () {
                _showDropPointDetails(pointData);
              }
            ),
          ));
        }
      }
    });
  });
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
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(pointData['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Address:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
              Text(pointData['address'] ?? 'Not available', style: TextStyle(fontSize: 14)),
              SizedBox(height: 10),
              Divider(),
              Text(
                'Operating Hours:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
              Text(pointData['operationHours'] ?? 'Not available', style: TextStyle(fontSize: 14)),
              SizedBox(height: 10),
              Divider(),
              Text(
                'Recyclable Items:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (pointData['recycleItems'] as List<dynamic>).map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(item.toString(), style: TextStyle(fontSize: 14)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _searchAndNavigate() async {
    if (_searchController.text.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(locations.first.latitude, locations.first.longitude),
            zoom: 14.0,
          ),
        ));
      }
    } catch (e) {
      // Handle error or no result
      print('Error: ${e.toString()}');
    }
  }

List<String> _selectedFilters = [];

void _showFilterDialog() async {
  // Assuming you have a list of all recyclable items
  List<String> recyclableItems = ['Paper', 'Glass', 'Cans', 'Plastic'];

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Select Recyclable Items'),
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
                child: Text('Apply'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateFilterCriteria(_selectedFilters); // Update the filter criteria based on the selection
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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: (value) => _searchAndNavigate(),
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: Colors.black),
              hintText: 'Enter location name',
              border: InputBorder.none,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ],
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
            padding: EdgeInsets.only(top: 120.0, left: 25.0), // Adjust these values as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Important for proper spacing
              children: [
                FloatingActionButton(
                  onPressed: _showFilterDialog,
                  child: Icon(Icons.filter_list),
                  tooltip: 'Filter Drop Points',
                  heroTag: 'filterBtn',
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DropPointMap())),
                  child: Icon(Icons.settings),
                  tooltip: 'Manage Drop Points',
                  heroTag: 'manageBtn',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed, required String tooltip}) {
    return Container(
      height: 45.0, // Standard FAB size
      width: 45.0,  // Standard FAB size
      child: FloatingActionButton(
        onPressed: onPressed,
        child: Icon(icon, size: 24.0), // Adjust icon size if needed
        tooltip: tooltip,
      ),
    );
  }
}