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

class _DropPointMapState extends State<DropPointMap> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Marker? tempMarker;
  LatLng? tempPoint;
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  String _dropPointTitle = '';
  String _operationHours = '';
  List<String> _recycleItems = [];

  final DatabaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadDropPoints();
    _determinePosition();
  }

   void _onMapTap(LatLng point) {
    setState(() {
      tempPoint = point;
      tempMarker = Marker(
        markerId: MarkerId("temp"),
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

void _showDropPointDetails(Map<String, dynamic> pointData, String docId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(pointData['title'], style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Operating Hours:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(pointData['operationHours'] ?? 'Not available'),
              ),
              Text(
                'Recyclable Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (pointData['recycleItems'] as List<dynamic>).map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.check, color: Colors.green),
                        SizedBox(width: 8),
                        Text(item.toString()),
                      ],
                    ),
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
          TextButton(
            child: const Text('Modify Drop Point Details'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the details dialog
              _modifyDropPointDetails(pointData, docId); // Implement this method
            },
          ),
          TextButton(
          child: const Text('Delete Drop Point'),
          onPressed: () {
          Navigator.of(context).pop(); // Close the details dialog
          _deleteDropPoint(docId); // Call the delete function
    },
  ),
        ],
      );
    },
  );
}

Future<Map<String, dynamic>?> _showEditDropPointDialog(Map<String, dynamic> pointData) async {
  TextEditingController titleController = TextEditingController(text: pointData['title']);
  TextEditingController operationHoursController = TextEditingController(text: pointData['operationHours']);
  List<String> recycleItems = List<String>.from(pointData['recycleItems']);

  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false, // User must tap button to close dialog
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Drop Point Details'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: "Enter title"),
                  ),
                  TextField(
                    controller: operationHoursController,
                    decoration: const InputDecoration(hintText: "Operation hours"),
                  ),
                  // ... Recyclable items checkboxes ...
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop({
                    'title': titleController.text,
                    'operationHours': operationHoursController.text,
                    'recycleItems': recycleItems,
                  });
                },
              ),
            ],
          );
        },
      );
    },
  );
}


void _modifyDropPointDetails(Map<String, dynamic> pointData, String docId) async {
  TextEditingController titleController = TextEditingController(text: pointData['title']);
  TextEditingController operationHoursController = TextEditingController(text: pointData['operationHours']);
  List<String> recycleItems = List<String>.from(pointData['recycleItems']);

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Modify Drop Point Details'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: "Enter title"),
                  ),
                  TextField(
                    controller: operationHoursController,
                    decoration: const InputDecoration(hintText: "Operation hours"),
                  ),
                  ...['Paper', 'Glass', 'Cans', 'Plastic'].map((item) {
                    return CheckboxListTile(
                      title: Text(item),
                      value: recycleItems.contains(item),
                      onChanged: (bool? value) {
                        if (value != null) {
                          setStateDialog(() {
                            if (value) {
                              recycleItems.add(item);
                            } else {
                              recycleItems.remove(item);
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
              }),
              TextButton(
                child: const Text('Update'),
                onPressed: () {
                  FirebaseFirestore.instance.collection('drop_points').doc(docId).update({
                    'title': titleController.text,
                    'operationHours': operationHoursController.text,
                    'recycleItems': recycleItems,
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


void _deleteDropPoint(String docId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Drop Point'),
        content: const Text('Are you sure you want to delete this drop point?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              FirebaseFirestore.instance.collection('drop_points').doc(docId).delete();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}



void _loadDropPoints() {
  FirebaseFirestore.instance.collection('drop_points').snapshots().listen((snapshot) {
    setState(() {
      markers.clear();
      for (var doc in snapshot.docs) {
        Map<String, dynamic> pointData = doc.data();
        // Check if the drop point matches the filter criteria
        if (_matchesFilter(pointData['recycleItems'])) {
          LatLng point = LatLng(pointData['latitude'], pointData['longitude']);
          markers.add(Marker(
            markerId: MarkerId(doc.id),
            position: point,
            infoWindow: InfoWindow(
              title: pointData['title'],
              snippet: pointData['address'],
              onTap: () {
                _showDropPointDetails(pointData, doc.id);
              }
            ),
          ));
        }
      }
    });
  });
}




  Future<String?> _showLocationNameDialog() async {
  String? locationName;
  // Use the current BuildContext to show the dialog
  locationName = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) { // Notice the new context name 'dialogContext'
      TextEditingController textFieldController = TextEditingController();
      return AlertDialog(
        title: const Text('Enter Location Name'),
        content: TextField(
          controller: textFieldController,
          decoration: InputDecoration(hintText: "Location name"),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Use the dialog's own context to pop
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
                          ? Icon(Icons.check_circle, color: Colors.blue) 
                          : Icon(Icons.circle_outlined, color: Colors.grey),
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
                  }).toList(),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  // Clear the form if the user cancels
                  _dropPointTitle = '';
                  _operationHours = '';
                  _recycleItems.clear();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () {
                  // Update the state with the values from the TextControllers
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
List<String> _filterCriteria = [];

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
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drop Point'),
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
                   onPressed: _onAddDropPointPressed,
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
}