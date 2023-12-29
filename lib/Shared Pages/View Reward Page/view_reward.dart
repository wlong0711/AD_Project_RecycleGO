import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:recycle_go/Shared%20Pages/Transition%20Page/transition_page.dart';
import 'package:recycle_go/Shared%20Pages/View%20Reward%20Page/add_voucher_page.dart';
import 'package:recycle_go/models/global_user.dart';
import 'package:recycle_go/models/voucher.dart';
import 'dart:async';

class ViewRewardPage extends StatefulWidget {
  const ViewRewardPage({super.key});

  @override
  _ViewRewardPageState createState() => _ViewRewardPageState();
}

class _ViewRewardPageState extends State<ViewRewardPage> with SingleTickerProviderStateMixin {
  List<Voucher> vouchers = [];
  List<String> claimedVouchers = [];
  bool _isDeleting = false;
  bool _isWritingToDatabase = false;
  Timer? _timer;
  int _userPoints = 0;
  late TabController _tabController;

  OverlayEntry? _overlayEntry;
  final int loadingTimeForOverlay = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOverlay();
      }
    });
    initializePage();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => TransitionOverlay(
            iconData: Icons.verified_user, // The icon you want to show
            duration: Duration(seconds: loadingTimeForOverlay), // Duration for the transition
            pageName: "Fetching Vouchers",
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

  void initializePage() async {
    print("In initializePage");
    await _fetchUserPoints();
    await fetchVouchers();
    await fetchClaimedVouchers();
    _timer = Timer.periodic(Duration(minutes: 1), (Timer t) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserPoints() async {
    try {
      var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: GlobalUser.userName)
        .get();
      
      if (snapshot.docs.isNotEmpty) {
          DocumentSnapshot userDoc = snapshot.docs.first;
          if (userDoc.exists && userDoc.data() != null && (userDoc.data() as Map<String, dynamic>).containsKey('points')) {
            setState(() {
              _userPoints = userDoc.get('points');
            });
          }
        }
      
    } catch (error) {
      print('Error fetching user points: $error');
      // Handle error
    }
  }

  Future<void> fetchVouchers() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('vouchers').get();
    List<Voucher> fetchedVouchers = querySnapshot.docs.map((doc) => Voucher.fromFirestore(doc)).toList();
    setState(() {
      vouchers = fetchedVouchers;
      print("Fetched ${vouchers.length} vouchers"); // Debug statement
    });
  }

  Future<void> fetchClaimedVouchers() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users')
        .where('username', isEqualTo: GlobalUser.userName).get().then((snapshot) => snapshot.docs.first);
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        claimedVouchers = List<String>.from(data['claimedVouchers'] ?? []);
      });
    }
  }

  void claimVoucher(String voucherId, int pointsNeeded) async {
    if (_userPoints < pointsNeeded) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Not Enough Points'),
          content: Text('You need $pointsNeeded points to claim this voucher. You currently have $_userPoints points.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        ),
      );
      return; // Exit if not enough points
    }else {

      if (!claimedVouchers.contains(voucherId)) {
        // Subtract the points needed for the voucher from the user's total points
        int newPointsTotal = _userPoints - pointsNeeded;
        
        setState(() {
          _isWritingToDatabase = true; // Start the loading indicator
        });

        // Update the user's 'claimedVouchers' and 'points' in Firestore
        try {
          // Fetch the user's document ID using their username
          var userQuerySnapshot = await FirebaseFirestore.instance.collection('users')
              .where('username', isEqualTo: GlobalUser.userName).get();
          var userDoc = userQuerySnapshot.docs.first;

          // Update the user's 'claimedVouchers' and 'points' in Firestore using the document ID
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            transaction.update(userDoc.reference, {
              'claimedVouchers': FieldValue.arrayUnion([voucherId]),
              'points': newPointsTotal // update the points
            });
          });

          // Update the local list of claimed vouchers
          claimedVouchers.add(voucherId);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Claimed successfully!'),
            backgroundColor: Colors.green,
          ));

          // Update the UI with the new points total
          setState(() {
            _userPoints = newPointsTotal;
          });

          // Optionally, refetch user data to confirm update (if there are other fields that might change)
          _fetchUserPoints();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to claim voucher: $e"),
            backgroundColor: Colors.red,
          ));
        } finally {
          setState(() {
            _isWritingToDatabase = false; // Stop the loading indicator
          });
        }
      }
    }
  }

  void refreshData() {
    print("Refreshing Data");
    fetchVouchers();
    fetchClaimedVouchers();
  }

  void deleteVoucher(String voucherId, int index) async {
    setState(() {
      _isDeleting = true; // Turn on loading overlay
    });

    try {
      QuerySnapshot voucherSnapshot = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('voucherID', isEqualTo: voucherId)
          .get();

      DocumentSnapshot voucherDoc = voucherSnapshot.docs.first;
      await FirebaseFirestore.instance.collection('vouchers').doc(voucherDoc.id).delete();

      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('claimedVouchers', arrayContains: voucherId)
          .get();

      for (var userDoc in usersSnapshot.docs) {
        userDoc.reference.update({
          'claimedVouchers': FieldValue.arrayRemove([voucherId])
        });
      }

      // After deletion, fetch vouchers and claimed vouchers again
      refreshData();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Voucher deleted successfully"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error deleting voucher: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isDeleting = false; // Turn off loading overlay
      });
    }
  }

  String formatTimeLeft(DateTime expiredDate) {
    final now = DateTime.now();
    final difference = expiredDate.difference(now);

    if (difference.isNegative) {
      return "Expired";
    } else {
      String days = difference.inDays.toString();
      String hours = (difference.inHours % 24).toString().padLeft(2, '0');
      String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');

      return "$days d $hours h $minutes min Left";
    }
  }

  void editVoucher(Voucher voucher, int index) {
    TextEditingController _nameController = TextEditingController(text: voucher.voucherName);
    TextEditingController _pointsNeededController = TextEditingController(text: voucher.pointsNeeded.toString());
    DateTime _selectedDateTime = voucher.expiredDate.toLocal(); // Initialize with current expiry date
    
    // Function to select date and time
    Future<void> _selectDateTime(BuildContext context) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDateTime,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        );
        if (pickedTime != null) {
          setState(() {
            _selectedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          });
        }
      }
    }

    // Show dialog for editing
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 250.0, // Minimum width
            maxWidth: MediaQuery.of(context).size.width * 0.9, // Maximum width
          ),
          child: AlertDialog(
            title: const Text('Edit Voucher'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text(
                        'Voucher ID - ${voucher.voucherID}', // Display Voucher ID
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Voucher Name',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold, // Make the label text bold
                            // You can also specify other text styles here if needed
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      TextField(
                        controller: _pointsNeededController,
                        decoration: InputDecoration(
                          labelText: 'Points Needed',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold, // Make the label text bold
                            // You can also specify other text styles here if needed
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 10,),
                      ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Expired Date:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, // Make it bold or style it as needed
                                    ),
                                  ),
                                  Text(
                                    "${DateFormat.yMd().add_Hm().format(_selectedDateTime)}", // Your date formatting
                                    style: TextStyle(
                                      color: Colors.black, // Optional: style it as needed
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.calendar_today), // Your trailing icon
                          ],
                        ),
                        onTap: () async {
                          await _selectDateTime(context);
                          setState(() {}); // Refresh the ListTile with the new date and time
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: <Widget>[
              TextButton(
                child: const Text( 'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                onPressed: () => {
                  deleteVoucher(voucher.voucherID, index),
                  Navigator.of(context).pop(), // Close the dialog
                },
              ),
              SizedBox(width: 70,),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () => updateVoucherDetails(voucher, _nameController.text, int.parse(_pointsNeededController.text), _selectedDateTime),
              ),
            ],
          ),
        );
      },
    );
  }

  void updateVoucherDetails(Voucher voucher, String newName, int newPoints, DateTime newExpiredDate) async {
    setState(() {
      _isWritingToDatabase = true; // Turn on loading overlay
    });

    try {
      // Fetch the document ID using the voucher ID
      var voucherSnapshot = await FirebaseFirestore.instance.collection('vouchers')
          .where('voucherID', isEqualTo: voucher.voucherID)
          .get();
      var voucherDoc = voucherSnapshot.docs.first;

      // Update the voucher details in Firestore
      FirebaseFirestore.instance.collection('vouchers').doc(voucherDoc.id).update({
        'voucherName': newName,
        'pointsNeeded': newPoints,
        'expiredDate': newExpiredDate, // Make sure to convert DateTime to a Timestamp if needed
      }).then((_) {
        print("Voucher updated successfully.");
        refreshData(); // Refresh the data to show updates
      });

      Navigator.of(context).pop(); // Close the dialog after updating
    } catch (e) {
      print("Error updating voucher: $e");
      // Handle error
    } finally {
      setState(() {
        _isWritingToDatabase = false; // Turn off loading overlay
      });
    }

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

  Widget _buildUserPointsCard() {
    var circleHeight = 170.0; // Height of the semi-circle
    var cardWidth = 350.0; // Fixed width of the card

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Semi-circle container
        Container(
          width: double.infinity, // Take full width available
          height: circleHeight, // Height of the semi-circle
          decoration: BoxDecoration(
            color: Colors.green, // Color of the semi-circle
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(circleHeight), // Flip the semi-circle upside down
              bottomRight: Radius.circular(circleHeight), // Flip the semi-circle upside down
            ),
          ),
        ),
        // Card
        SizedBox(
          width: cardWidth,
          child: Card(
            elevation: 4.0,
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Available Points',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.remove_red_eye, size: 18),
                    ],
                  ),
                  Text(
                    '$_userPoints Points',
                    style: TextStyle(
                      fontSize: 40.0,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableVouchers() {
    List<Voucher> availableVouchers = vouchers.where((voucher) {
      return voucher.expiredDate.toLocal().isAfter(DateTime.now());
    }).toList();

    return ListView.builder(
      itemCount: availableVouchers.length,
      itemBuilder: (context, index) {
        Voucher voucher = availableVouchers[index];
        bool isClaimed = claimedVouchers.contains(voucher.voucherID);
        String timeLeft = formatTimeLeft(voucher.expiredDate.toLocal());

        return buildVoucherCard(voucher, isClaimed, timeLeft, index);
      },
    );
  }

  Widget _buildExpiredVouchers() {
    List<Voucher> expiredVouchers = vouchers.where((voucher) {
      return voucher.expiredDate.toLocal().isBefore(DateTime.now());
    }).toList();

    return ListView.builder(
      itemCount: expiredVouchers.length,
      itemBuilder: (context, index) {
        Voucher voucher = expiredVouchers[index];
        bool isClaimed = claimedVouchers.contains(voucher.voucherID);
        String timeLeft = formatTimeLeft(voucher.expiredDate.toLocal());

        return buildVoucherCard(voucher, isClaimed, timeLeft, index);
      },
    );
  }

  Widget buildVoucherCard(Voucher voucher, bool isClaimed, String timeLeft, int index) {
    bool isExpired = voucher.expiredDate.toLocal().isBefore(DateTime.now());
    Color lightGreyColor = Colors.grey[300]!; // Light grey color for the button when claimed or expired
    Color greenColor = Colors.green; // Green color for the icon and button when not claimed and not expired

    return Card(
      elevation: 2.0,
      color: isExpired ? lightGreyColor : Colors.white, // Apply light grey color if expired
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7),
              color: greenColor, // The icon container remains green regardless of the voucher state
              child: Icon(Icons.discount, color: Colors.white, size: 40),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.voucherName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "${voucher.pointsNeeded} points needed", // Display points needed
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600], // You might want to adjust the color to fit your design
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text(timeLeft),
                    ],
                  ),
                ],
              ),
            ),
            if (GlobalUser.userLevel == 1) // Show delete button
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => editVoucher(voucher, index),
              ),
            ElevatedButton(
              onPressed: isExpired || isClaimed ? null : () => claimVoucher(voucher.voucherID,voucher.pointsNeeded),
              style: ElevatedButton.styleFrom(
                primary: isExpired || isClaimed ? lightGreyColor : greenColor, // Use light grey if expired or claimed, green if not
              ),
              child: Text(
                isExpired ? 'Expired' : isClaimed ? 'Claimed' : 'Claim',
                style: TextStyle(
                  color: isExpired || isClaimed ? Colors.grey : Colors.white, // Conditional text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content; // This will hold the current state widget
      content = Scaffold(
        key: ValueKey("Loaded"),
        appBar: AppBar(
          title: const Text('View Rewards'),
          flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.greenAccent, Colors.green],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              elevation: 10,
              shadowColor: Colors.greenAccent.withOpacity(0.5),
              actions: [
                if (GlobalUser.userLevel == 1)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddVoucherPage(
                            onVoucherAdded: () {

                            },
                          ),
                        ),
                      ).then((_) => refreshData());
                    },
                  ),
              ],
        ),
        body: Column(
          children: <Widget>[
            _buildUserPointsCard(),
            // TabBar directly below the user points card
                Material(
                  child: Container(
                    width: 400,
                    decoration: BoxDecoration(
                      color: Colors.green,  // Set the background color of the container
                      borderRadius: BorderRadius.circular(50),
                    ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.yellow, // Color for the text of the selected tab
                        unselectedLabelColor: Colors.white, // Color for the text of the unselected tabs
                        indicatorColor: Colors.yellow,
                        tabs: [
                          Tab(text: 'Available'),
                          Tab(text: 'Expired'),
                        ],
                      ),
                  ),
                ),
                Expanded(
                  // TabBarView inside the Expanded to fill the rest of the screen space
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvailableVouchers(),
                      _buildExpiredVouchers(),
                    ],
                  ),
                ),
          ],
        ),
      );

    if (_isDeleting) {
      content = Stack(
        children: [
          content, // The current content (loading or main content)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: _buildLoadingOverlay(),
            ),
          ),
        ],
      );
    }

    // Overlay the writing to database indicator if needed
    if (_isWritingToDatabase) {
      content = Stack(
        children: [
          content, // The current content (loading or main content)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: _buildLoadingOverlay(),
            ),
          ),
        ],
      );
    }

    // Wrap the content in an AnimatedSwitcher for smooth transition
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: content,
    );
  }
}
