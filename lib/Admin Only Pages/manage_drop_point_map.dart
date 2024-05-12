import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

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
  final String _dropPointTitle = '';

  final List<String> _pickupDays = [];
  final List<String> _recycleItems = [];


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
        markerId: const MarkerId("temp"),
        position: point,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
  }

  void _onAddDropPointPressed() async {
    if (tempPoint != null) {
      await _showDetailsDialog(tempPoint!); // This should set _pickupDays and _recycleItems
      if (_dropPointTitle.isNotEmpty) {
        // Ensure the address is fetched before saving the drop point
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
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.info),
                title: const Text('View Details'),
                onTap: () => _navigateToDetailView(context, pointData, docId)),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () => _navigateToEditView(context, docId),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
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

        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this drop point? This action cannot be undone.'),

        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  ) ?? false;
}

void _navigateToDetailView(BuildContext context, Map<String, dynamic> pointData, String docId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetailedViewScreen(pointData: pointData, dropPointId: docId),
    ),
  ).then((value) {
    // If the value is 'true', refresh the data
    if (value == true) {
      _loadDropPoints();
    }
  });
}

void _navigateToEditView(BuildContext context, String docId) {
  Navigator.pop(context); 
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditDropPointScreen(
        dropPointId: docId,
        onDropPointUpdated: _loadDropPoints, // Pass the callback here
      ),
    ),
  ).then((_) {
    // This will be called when EditDropPointScreen is popped
    _loadDropPoints(); // Refresh drop points when returning back to the map
  });
}


void _loadDropPoints() async {
  var snapshot = await FirebaseFirestore.instance.collection('drop_points').get();

  setState(() {
    markers.clear();
    for (var doc in snapshot.docs) {
      Map<String, dynamic> pointData = doc.data();
      List<String> recycleItems = List<String>.from(pointData['recycleItems']); // Cast to List<String>
      if (_matchesFilter(recycleItems)) {
        LatLng point = LatLng(pointData['latitude'], pointData['longitude']);
        markers.add(_createMarker(doc.id, point, pointData));
      }
    }
  });
}


Marker _createMarker(String id, LatLng point, Map<String, dynamic> pointData) {
  int currentCapacity = pointData['currentCapacity'] ?? 0;
  return Marker(
    markerId: MarkerId(id),
    position: point,
    icon: BitmapDescriptor.defaultMarkerWithHue(_getBinColorHue(currentCapacity)),
    infoWindow: InfoWindow(
      title: pointData['title'],
      snippet: 'Tap here for details',
      onTap: () {
        _showDropPointDetails(pointData, id, pointData['title']); // Pass all required arguments
      },
    ),
    onTap: () {
      // This onTap is for the marker itself, not the InfoWindow
    },
  );
}

double _getBinColorHue(int capacity) {
  if (capacity <= 10) return BitmapDescriptor.hueGreen; // Green for empty
  if (capacity <= 20) return BitmapDescriptor.hueYellow; // Yellow for half full
  if (capacity <= 29) return BitmapDescriptor.hueOrange; // Orange for about full
  return BitmapDescriptor.hueRed; // Red for full
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
    int? maxCapacity = await _showDetailsDialog(point);
    if (_dropPointTitle.isNotEmpty && maxCapacity != null) {
      String address = await _getAddressFromLatLng(point);
      Marker newMarker = Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        infoWindow: InfoWindow(title: _dropPointTitle, snippet: address),
      );
      setState(() {
        markers.add(newMarker);
      });
      _saveDropPoint(point, _dropPointTitle, address, _pickupDays, _recycleItems, maxCapacity);
    }
  }

  Future<int?> _showDetailsDialog(LatLng point) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController maxCapacityController = TextEditingController(text: '30');
    List<String> daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    List<bool> selectedDays = List.generate(7, (_) => false);
    List<String> recyclableItems = ['Paper', 'Glass', 'Cans', 'Plastic'];
    Map<String, bool> recycleItemsMap = {
      for (var item in recyclableItems) item: false,
    };

    // Fetch address from the given LatLng point
    String address = await _getAddressFromLatLng(point);

    int? maxCapacity;
    await showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Drop Point Details'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: "Enter title"),
                    ),
                    const SizedBox(height: 20),
                    const Text("Enter maximum capacity:"),
                    TextField(
                      controller: maxCapacityController,
                      decoration: const InputDecoration(hintText: "Enter maximum capacity"),
                      keyboardType: TextInputType.number, // To ensure only numbers are entered
                    ),
                    const SizedBox(height: 20),
                    const Text("Select Pickup Days:"),
                    Wrap(
                      children: List<Widget>.generate(
                        daysOfWeek.length,
                        (index) => ChoiceChip(
                          label: Text(daysOfWeek[index]),
                          selected: selectedDays[index],
                          selectedColor: Colors.green, // Color when selected
                          backgroundColor: Colors.grey, // Color when not selected
                          onSelected: (bool selected) {
                            setStateDialog(() {
                              selectedDays[index] = selected;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Select Recyclable Items:"),
                    Column(
                      children: recyclableItems.map((item) => CheckboxListTile(
                        title: Text(item),
                        value: recycleItemsMap[item],
                        onChanged: (bool? value) {
                          setStateDialog(() {
                            recycleItemsMap[item] = value!;
                          });
                        },
                        checkColor: Colors.white,
                        activeColor: Colors.green,
                      )).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                // Validation checks before confirming
                if (titleController.text.isEmpty) {
                  _showErrorDialog(context, 'Please enter a title.');
                  return;
                }

                List<String> selectedPickupDays = daysOfWeek
                    .asMap()
                    .entries
                    .where((entry) => selectedDays[entry.key])
                    .map((entry) => entry.value)
                    .toList();
                if (selectedPickupDays.isEmpty) {
                  _showErrorDialog(context, 'Please select at least one pickup day.');
                  return;
                }

                List<String> selectedRecycleItems = recycleItemsMap.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList();
                if (selectedRecycleItems.isEmpty) {
                  _showErrorDialog(context, 'Please select at least one recyclable item.');
                  return;
                }

                maxCapacity = int.tryParse(maxCapacityController.text) ?? 30;
                Navigator.of(context).pop(); // Close the dialog
                _saveDropPoint(point, titleController.text, address, _pickupDays, _recycleItems, maxCapacity!);
              },
            ),
          ],
        );
      },
    );
    return null;
  }

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Invalid Input'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          child: const Text('Okay'),
          onPressed: () {
            Navigator.of(ctx).pop(); // Close the dialog
          },
        )
      ],
    ),
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

  void _saveDropPoint(LatLng point, String title, String address, List<String> pickupDays, List<String> recycleItems, int maxCapacity) {
  FirebaseFirestore.instance.collection('drop_points').add({
    'latitude': point.latitude,
    'longitude': point.longitude,
    'title': title,
    'address': address,
    'pickupDays': pickupDays,
    'recycleItems': recycleItems,
    'currentCapacity' : 0,
    'maxCapacity': maxCapacity,
  }).then((result) {
    print("Drop point added");
    //Refresh Data
    // Call loadDropPoints again to refresh the list of markers
    _loadDropPoints();
  }).catchError((error) {
    print("Failed to add drop point: $error");
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

bool _matchesFilter(List<String> dropPointItems) {
  if (_filterCriteria.isEmpty) {
    return true; // If no filter criteria, everything matches
  }
  // Check if every filter criteria item is present in the drop point's items
  return _filterCriteria.every((item) => dropPointItems.contains(item));
}


void _updateFilterCriteria(List<String> newCriteria) {
  setState(() {
    _filterCriteria = newCriteria;
  });
  _loadDropPoints(); // Reload points with the new filter
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
          onPressed: () => Navigator.of(context).pop(), // Go back on press
        ),
        title: const Text(
          'Manage Drop Point',
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
  final String dropPointId;
  
  const DetailedViewScreen({super.key, required this.pointData, required this.dropPointId});

  @override
  Widget build(BuildContext context) {
    int currentCapacity = pointData['currentCapacity'] ?? 0;
    int maxCapacity = pointData['maxCapacity'] ?? 0;
    String capacityInfo = 'Capacity: $currentCapacity/$maxCapacity';

    return Scaffold(
      appBar: AppBar(
        title: Text(pointData['title'] ?? 'Detail View'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Title Section
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(pointData['title'] ?? 'Not available', style: const TextStyle(fontSize: 16)),

              Divider(color: Colors.grey[300], height: 20, thickness: 1),
              
              const Text(
                'Capacity',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(capacityInfo, style: const TextStyle(fontSize: 16)),

              Divider(color: Colors.grey[300], height: 20, thickness: 1),
              // Pickup Days Section
              const Text(
                'Pickup Days',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(pointData['pickupDays']?.join(', ') ?? 'Not available', style: const TextStyle(fontSize: 16)),

              Divider(color: Colors.grey[300], height: 20, thickness: 1),

              // Recyclable Items Section
              const Text(
                'Recyclable Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(pointData['recycleItems']?.join(', ') ?? 'Not available', style: const TextStyle(fontSize: 16)),

              ElevatedButton(
                onPressed: () => _confirmClearBin(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green, // foreground (text) color
                ),
                child: const Text('Clear Bin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearBin(BuildContext context) async {
    // Update the Firestore document for this drop point
    await FirebaseFirestore.instance.collection('drop_points').doc(dropPointId).update({
      'currentCapacity': 0,
    });

    // Pop the current screen and trigger a refresh if needed
    Navigator.pop(context,true); // Pops the DetailedViewScreen

    // Wait for the pop to finish and then pop again to go back to the screen before the previous one
    Future.delayed(Duration.zero, () {
      Navigator.pop(context); // Pops the previous screen (e.g., DropPointMap)
    });
  }

  void _confirmClearBin(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Clear Bin'),
          content: const Text('Are you sure you want to clear the bin? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog without clearing
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () {
                _clearBin(context);
                Navigator.of(dialogContext).pop(); // Close the dialog after clearing
              },
            ),
          ],
        );
      },
    );
  }
}

class EditDropPointScreen extends StatefulWidget {
  final String dropPointId;
  final VoidCallback onDropPointUpdated;
  const EditDropPointScreen({super.key, required this.dropPointId, required this.onDropPointUpdated});

  @override
  _EditDropPointScreenState createState() => _EditDropPointScreenState();
}

class _EditDropPointScreenState extends State<EditDropPointScreen> {
  late TextEditingController _titleController;
  late TextEditingController _maxCapacityController;
  Map<String, bool> _daysOfWeekMap = {};
  Map<String, bool> _recyclableItemsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _maxCapacityController = TextEditingController(text: '30');
    _daysOfWeekMap = {
      "Monday": false,
      "Tuesday": false,
      "Wednesday": false,
      "Thursday": false,
      "Friday": false,
      "Saturday": false,
      "Sunday": false,
    };
    _recyclableItemsMap = {
      "Paper": false,
      "Glass": false,
      "Cans": false,
      "Plastic": false,
    };
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

        // Initialize daysOfWeekMap based on fetched data
        List<dynamic> pickupDays = pointData['pickupDays'] ?? [];
        for (var day in pickupDays) {
          _daysOfWeekMap[day] = true;
        }

        // Initialize recyclableItemsMap based on fetched data
        List<dynamic> recyclableItems = pointData['recycleItems'] ?? [];
        for (var item in recyclableItems) {
          _recyclableItemsMap[item] = true;
        }

        int maxCapacity = pointData['maxCapacity'] ?? 30; // Default to 30 if not set
        _maxCapacityController.text = maxCapacity.toString();

      }
      setState(() {
        _isLoading = false;
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
    _titleController.dispose();
    _maxCapacityController.dispose();
    super.dispose();
  }
  
  void _saveDropPoint() async {

    int maxCapacity = int.tryParse(_maxCapacityController.text) ?? 30;
  // Validation: Ensure title is not empty
  if (_titleController.text.isEmpty) {
    _showErrorDialog('Title cannot be empty.'); 
    return; // Exit the function if validation fails
  }

  // Validation: Ensure at least one pickup day is selected
  List<String> selectedPickupDays = _daysOfWeekMap.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
  if (selectedPickupDays.isEmpty) {
    _showErrorDialog('Please select at least one pickup day.');
    return; // Exit the function if validation fails
  }

  // Validation: Ensure at least one recyclable item is selected
  List<String> selectedRecyclableItems = _recyclableItemsMap.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
  if (selectedRecyclableItems.isEmpty) {
    _showErrorDialog('Please select at least one recyclable item.');
    return; // Exit the function if validation fails
  }

  // Proceed with updating the drop point details if all validations pass
  try {
    await FirebaseFirestore.instance
        .collection('drop_points')
        .doc(widget.dropPointId)
        .update({
          'title': _titleController.text,
          'pickupDays': selectedPickupDays,
          'recycleItems': selectedRecyclableItems,
          'maxCapacity': maxCapacity,
        });
    widget.onDropPointUpdated(); // Call the callback here after successful update
    Navigator.of(context).pop(); // Return to the previous screen on success
  } catch (e) {
    _showErrorDialog('Error updating drop point: $e'); // Show error on exception
  }
}

void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Invalid Input'),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          child: const Text('Okay'),
          onPressed: () {
            Navigator.of(ctx).pop(); // Close the dialog
          },
        )
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Drop Point'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _maxCapacityController,
                    decoration: const InputDecoration(labelText: 'Max Capacity'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  const Text("Select Pickup Days:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8.0, // Gap between chips
                    runSpacing: 4.0, // Gap between lines
                    children: _daysOfWeekMap.keys.map((day) {
                      return ChoiceChip(
                        label: Text(day),
                        selected: _daysOfWeekMap[day]!,
                        onSelected: (bool selected) {
                          setState(() {
                            _daysOfWeekMap[day] = selected;
                          });
                        },
                        selectedColor: Colors.green,
                        backgroundColor: Colors.grey.shade300,
                        labelStyle: TextStyle(color: _daysOfWeekMap[day]! ? Colors.white : Colors.black),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text("Select Recyclable Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._recyclableItemsMap.keys.map(
                    (item) => CheckboxListTile(
                      title: Text(item),
                      value: _recyclableItemsMap[item],
                      onChanged: (bool? newValue) {
                        setState(() {
                          _recyclableItemsMap[item] = newValue ?? false;
                        });
                      },
                      checkColor: Colors.white,
                      activeColor: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveDropPoint,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green,
                    ),
                    child: const Padding(
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
        child: Icon(icon, color: Colors.white),
      ),
    );
  }