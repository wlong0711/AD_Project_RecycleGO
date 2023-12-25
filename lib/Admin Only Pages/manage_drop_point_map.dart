import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class DropPointMap extends StatefulWidget {
  const DropPointMap({super.key});
  @override
  State<DropPointMap> createState() => _DropPointMapState();
}

class _DropPointMapState extends State<DropPointMap> with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Marker? tempMarker;
  LatLng? tempPoint;
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  String _dropPointTitle = '';
  String _operationHours = '';
  final List<String> _recycleItems = [];
  late AnimationController _animationController;

  final DatabaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadDropPoints();
    _determinePosition();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

   void _onMapTap(LatLng point) {
    setState(() {
      tempPoint = point;
      tempMarker = Marker(
        markerId: const MarkerId("temp"),
        position: point,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
  }

  void _onAddDropPointPressed() async {
    if (tempPoint != null) {
      await _showDetailsDialog(tempPoint!);
      if (_dropPointTitle.isNotEmpty) {
        String address = await _getAddressFromLatLng(tempPoint!);
        Marker newMarker = Marker(
          markerId: MarkerId(tempPoint.toString()),
          position: tempPoint!,
          infoWindow: InfoWindow(title: _dropPointTitle, snippet: address),
        );
        setState(() {
          markers.add(newMarker);
          tempMarker = null;
        });
        _saveDropPoint(tempPoint!, _dropPointTitle, address);
      }
    }
  }

   Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

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

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(forceAndroidLocationManager: true);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition,
            zoom: 18.0,
          ),
        ),
      );
    });
  }

void _showDropPointDetails(Map<String, dynamic> pointData, String docId, String title) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext bc) {
      return Container(
        child: Wrap(
          children: <Widget>[
            ListTile(
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {},
            ),
            Divider(),
            ListTile(
                leading: Icon(Icons.info),
                title: Text('View Details'),
                onTap: () => _navigateToDetailView(context, pointData)),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () => _navigateToEditView(context, docId),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () => _deleteDropPointConfirmation(docId),
            ),
          ],
        ),
      );
    },
  );
}

void _deleteDropPointConfirmation(String docId) async {
  bool confirmDelete = await _confirmDeleteDialog();
  if (confirmDelete) {
    await FirebaseFirestore.instance.collection('drop_points').doc(docId).delete();
    Navigator.of(context).pop(); // Close the bottom sheet

    // Refresh the markers on the map
    _refreshMarkers();
  }
}

void _refreshMarkers() async {
  var updatedMarkers = <Marker>{};
  // Fetch the updated list of drop points from Firestore or your local list
  var snapshot = await FirebaseFirestore.instance.collection('drop_points').get();
  for (var doc in snapshot.docs) {
    var pointData = doc.data();
    var point = LatLng(pointData['latitude'], pointData['longitude']);
    updatedMarkers.add(
      Marker(
        markerId: MarkerId(doc.id),
        position: point,
        infoWindow: InfoWindow(
          title: pointData['title'],
          snippet: pointData['address'],
        ),
        onTap: () {
          _showDropPointDetails(pointData, doc.id, pointData['title']);
        },
      ),
    );
  }

  setState(() {
    markers = updatedMarkers;
  });
}

Future<bool> _confirmDeleteDialog() async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this drop point? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  ) ?? false;
}



void _navigateToDetailView(BuildContext context, Map<String, dynamic> pointData) {
  Navigator.pop(context); 
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetailedViewScreen(pointData: pointData),
    ),
  );
}

void _navigateToEditView(BuildContext context, String docId) {
  Navigator.pop(context); 
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditDropPointScreen(dropPointId: docId),
    ),
  );
}


void _loadDropPoints() {
  FirebaseFirestore.instance.collection('drop_points').snapshots().listen((snapshot) {
    setState(() {
      markers.clear();
      for (var doc in snapshot.docs) {
        Map<String, dynamic> pointData = doc.data();
        LatLng point = LatLng(pointData['latitude'], pointData['longitude']);
        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: point,
            infoWindow: InfoWindow(
              title: pointData['title'], 
              snippet: pointData['address']
            ),
            onTap: () {
              _showDropPointDetails(pointData, doc.id, pointData['title'] ?? 'No Title');
            },
          ),
        );
      }
    });
  });
}

  Future<String?> _showLocationNameDialog() async {
  String? locationName;
  locationName = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      TextEditingController textFieldController = TextEditingController();
      return AlertDialog(
        title: const Text('Enter Location Name'),
        content: TextField(
          controller: textFieldController,
          decoration: const InputDecoration(hintText: "Location name"),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              if (textFieldController.text.isNotEmpty) {
                Navigator.of(dialogContext).pop(textFieldController.text);
              }
            },
          ),
        ],
      );
    },
  );
  return locationName;
}

  void _addDropPoint(LatLng point) async {
    await _showDetailsDialog(point);
    if (_dropPointTitle.isNotEmpty) {
      String address = await _getAddressFromLatLng(point);
      Marker newMarker = Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        infoWindow: InfoWindow(title: _dropPointTitle, snippet: address),
      );
      setState(() {
        markers.add(newMarker);
      });
      _saveDropPoint(point, _dropPointTitle, address);
    }
  }

  Future<void> _showDetailsDialog(LatLng point) async {
  TextEditingController titleController = TextEditingController();
  TextEditingController operationHoursController = TextEditingController();

  return showDialog(
    context: context,
    barrierDismissible: false, // User must tap button to close dialog
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) {
          return AlertDialog(
            title: const Text('Enter Drop Point Details'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: "Enter title"),
                    onChanged: (value) {
                      _dropPointTitle = value;
                    },
                  ),
                  TextField(
                    controller: operationHoursController,
                    decoration: const InputDecoration(hintText: "Operation hours"),
                    onChanged: (value) {
                      _operationHours = value;
                    },
                  ),
                  ...['Paper', 'Glass', 'Cans', 'Plastic'].map((item) {
                    return ListTile(
                      title: Text(item),
                      trailing: IconButton(
                        icon: _recycleItems.contains(item) 
                          ? const Icon(Icons.check_circle, color: Colors.blue) 
                          : const Icon(Icons.circle_outlined, color: Colors.grey),
                        onPressed: () {
                          setStateDialog(() {
                            if (_recycleItems.contains(item)) {
                              _recycleItems.remove(item);
                            } else {
                              _recycleItems.add(item);
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  _dropPointTitle = '';
                  _operationHours = '';
                  _recycleItems.clear();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () {
                  setState(() {
                    _dropPointTitle = titleController.text;
                    _operationHours = operationHoursController.text;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}


  Future<String> _getAddressFromLatLng(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
    } catch (e) {
      return 'Failed to fetch address';
    }
    return 'No address available';
  }

   void _saveDropPoint(LatLng point, String title, String address) {
    FirebaseFirestore.instance.collection('drop_points').add({
      'latitude': point.latitude,
      'longitude': point.longitude,
      'title': title,
      'operationHours': _operationHours,
      'recycleItems': _recycleItems,
      'address': address,
    });
  }
  
  void _onMapCreated(GoogleMapController controller) {
  setState(() {
    mapController = controller;
  });
}

final List<String> _selectedFilters = [];

void _showFilterDialog() async {
  // Assuming you have a list of all recyclable items
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
List<String> _filterCriteria = [];

bool _matchesFilter(List<dynamic> dropPointItems) {
  if (_filterCriteria.isEmpty) {
    return true;
  }
  for (var item in _filterCriteria) {
    if (!dropPointItems.contains(item)) {
      return false;
    }
  }
  return true; 
}

void _updateFilterCriteria(List<String> newCriteria) {
  setState(() {
    _filterCriteria = newCriteria;
    _loadDropPoints();
  });
}
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drop Point'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: GoogleMap(
        onMapCreated: (controller) => mapController = controller,
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 18.0,
        ),
        markers: {...markers, if (tempMarker != null) tempMarker!},
        onTap: _onMapTap,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
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
                  onPressed: _onAddDropPointPressed,
                  tooltip: 'Manage Drop Points',
                  icon: Icons.add_location_alt_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DetailedViewScreen extends StatelessWidget {
  final Map<String, dynamic> pointData;

  const DetailedViewScreen({Key? key, required this.pointData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pointData['title'] ?? 'Detail View'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Title Section
              Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(pointData['title'] ?? 'Not available', style: TextStyle(fontSize: 16)),

              Divider(color: Colors.grey[300], height: 20, thickness: 1),

              // Operation Hours Section
              Text(
                'Operation Hours',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(pointData['operationHours'] ?? 'Not available', style: TextStyle(fontSize: 16)),

              Divider(color: Colors.grey[300], height: 20, thickness: 1),

              // Address Section
              Text(
                'Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(pointData['address'] ?? 'Not available', style: TextStyle(fontSize: 16)),

              Divider(color: Colors.grey[300], height: 20, thickness: 1),

              // Recyclable Items Section
              Text(
                'Recyclable Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(pointData['recycleItems'].join(', '), style: TextStyle(fontSize: 16)),

              // Add more sections as necessary
            ],
          ),
        ),
      ),
    );
  }
}

class EditDropPointScreen extends StatefulWidget {
  final String dropPointId;

  const EditDropPointScreen({Key? key, required this.dropPointId}) : super(key: key);

  @override
  _EditDropPointScreenState createState() => _EditDropPointScreenState();
}

class _EditDropPointScreenState extends State<EditDropPointScreen> {
  late TextEditingController _titleController;
  late TextEditingController _operationHoursController;
  late TextEditingController _addressController;
  Map<String, bool> _recyclableItemsMap = {}; // Map to track selected recyclable items
  bool _isLoading = true; // track loading state

  // List of all possible recyclable items
  final List<String> _allRecyclableItems = [
    "Paper",
    "Glass",
    "Cans",
    "Plastic",
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _operationHoursController = TextEditingController();
    _addressController = TextEditingController();
    // Initialize all recyclable items to false (i.e., not selected)
    for (String item in _allRecyclableItems) {
      _recyclableItemsMap[item] = false;
    }
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      DocumentSnapshot dropPointSnapshot = await FirebaseFirestore.instance
          .collection('drop_points')
          .doc(widget.dropPointId)
          .get();

      if (dropPointSnapshot.exists) {
        Map<String, dynamic> pointData = dropPointSnapshot.data() as Map<String, dynamic>;
        _titleController.text = pointData['title'] ?? '';
        _operationHoursController.text = pointData['operationHours'] ?? '';
        _addressController.text = pointData['address'] ?? '';
        // Update recyclable items map based on fetched data
        List<dynamic> recyclableItems = pointData['recycleItems'] ?? [];
        for (String item in _allRecyclableItems) {
          if (recyclableItems.contains(item)) {
            _recyclableItemsMap[item] = true;
          }
        }
      }
      setState(() {
        _isLoading = false; // Set loading state to false once data is fetched
      });
    } catch (e) {
      print("Error fetching initial data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is removed
    _titleController.dispose();
    _operationHoursController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveDropPoint() async {
    // Gather the selected recyclable items
    List<String> selectedRecyclableItems = _recyclableItemsMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    try {
      await FirebaseFirestore.instance
          .collection('drop_points')
          .doc(widget.dropPointId)
          .update({
            'title': _titleController.text,
            'operationHours': _operationHoursController.text,
            'address': _addressController.text,
            'recycleItems': selectedRecyclableItems,
          });

      Navigator.of(context).pop();
    } catch (e) {
      print("Error updating document: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Drop Point'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _operationHoursController,
                  decoration: InputDecoration(labelText: 'Operation Hours'),
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                ),
                SizedBox(height: 20),
                Text("Select Recyclable Items:"),
                ..._allRecyclableItems.map((item) => CheckboxListTile(
                title: Text(item),
                value: _recyclableItemsMap[item],
                onChanged: (bool? newValue) {
                  setState(() {
                    if (newValue != null) {
                      _recyclableItemsMap[item] = newValue;
                    }
                  });
                },
                activeColor: Colors.green,
                )),
                ElevatedButton(
                onPressed: _saveDropPoint,
                style: ElevatedButton.styleFrom(
                  primary: Colors.green, // background (button) color
                  onPrimary: Colors.white, // foreground (text) color
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              ],
            ),
      ),
    );
  }
}

Widget _buildGradientFAB({required VoidCallback onPressed, required String tooltip, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.greenAccent, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        heroTag: null, // Use null or unique tag for each FAB
        child: Icon(icon, color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }