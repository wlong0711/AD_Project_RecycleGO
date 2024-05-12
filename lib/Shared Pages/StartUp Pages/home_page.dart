import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:recycle_go/Admin%20Only%20Pages/view_report_issues.dart';
import 'package:recycle_go/Shared%20Pages/QR%20Scan%20&%20Upload%20Page/qr_scan_screen.dart';
import 'package:recycle_go/Admin%20Only%20Pages/verify_reward.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/UserProfilePage.dart';
import 'package:recycle_go/Shared%20Pages/View%20Reward%20Page/view_reward.dart';
import 'package:recycle_go/models/global_user.dart';
import 'package:recycle_go/User%20Only%20Pages/report_issues.dart';
import 'package:recycle_go/models/upload.dart';
import '../../Admin Only Pages/map_screen_admin.dart';
import '../../User Only Pages/map_screen_user.dart';
import 'view_user_upload_history.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _selectedIndex = 0;
  int _currentCarouselIndex = 0;
  final List<String> imageUrls = [
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2FRecycle-Right-Banner.jpg?alt=media&token=0f09deef-3e48-4833-9614-b299289bf226',
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2Frecycling-poster-final.webp?alt=media&token=f1e1d089-ee91-4883-bf38-0ff17bfcc4a3',
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2Ft-t-4256-eco-and-recycling-the-future-of-the-planet-display-poster_ver_1.webp?alt=media&token=c95bb98d-a132-4909-a295-71cd92bbf9c7',
    ];

  int todayUploads = 0;
  int thirtyDayUploads = 0;
  int yearUploads = 0;
  Upload? latestUpload;

  @override
  void initState() {
    super.initState();
    // Fetch data when the page initializes
    fetchUploadData();
  }

  Future<void> fetchUploadData() async {
    try {
      DateTime now = DateTime.now().toUtc();
      DateTime todayStart = DateTime.utc(now.year, now.month, now.day);
      DateTime thirtyDaysAgoStart = todayStart.subtract(const Duration(days: 30));
      DateTime oneYearAgoStart = todayStart.subtract(const Duration(days: 365));

      var uploadCollection = FirebaseFirestore.instance.collection('uploads')
          .where('username', isEqualTo: GlobalUser.userName); // Filter by the current user's username

      // Fetch today's approved uploads
      var todayUploadsQuery = await uploadCollection
          .where('uploadedTime', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('status', isEqualTo: 'Approved')
          .get();
      todayUploads = todayUploadsQuery.docs.length;

      // Fetch last 30 days' approved uploads
      var thirtyDayUploadsQuery = await uploadCollection
          .where('uploadedTime', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgoStart))
          .where('status', isEqualTo: 'Approved')
          .get();
      thirtyDayUploads = thirtyDayUploadsQuery.docs.length;

      // Fetch last year's approved uploads
      var yearUploadsQuery = await uploadCollection
          .where('uploadedTime', isGreaterThanOrEqualTo: Timestamp.fromDate(oneYearAgoStart))
          .where('status', isEqualTo: 'Approved')
          .get();
      yearUploads = yearUploadsQuery.docs.length;

      // Fetch the latest activity
      var latestUploadQuery = await uploadCollection
          .orderBy('uploadedTime', descending: true)
          .limit(1)
          .get();

      if (latestUploadQuery.docs.isNotEmpty) {
        latestUpload = Upload.fromFirestore(latestUploadQuery.docs.first);
      }
      print('$uploadCollection');
      print('$todayUploads');
      print('$thirtyDayUploads');
      print('$yearUploads');
      setState(() {}); // Update the UI
    } catch (e) {
      print('Error fetching upload data: $e');
    }
  }


  Widget _buildActivitiesSection() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9, // 80% of screen width
        decoration: BoxDecoration(
          color: Colors.green, // Green background color
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        padding: const EdgeInsets.all(10), // Padding inside the container
        child: Column(
          children: [
            const Text('Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Today', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('$todayUploads times', style: const TextStyle(color: Colors.white)), // Display today's uploads
                  ],
                ),
                Column(
                  children: [
                    const Text('Last 30 Days', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('$thirtyDayUploads times', style: const TextStyle(color: Colors.white)), // Display last 30 days' uploads
                  ],
                ),
                Column(
                  children: [
                    const Text('Last 1 Year', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('$yearUploads times', style: const TextStyle(color: Colors.white)), // Display last year's uploads
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white),
            ListTile(
              title: const Text('Latest Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: latestUpload != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Upload at ${DateFormat('dd/MM/yyyy HH:mm').format(latestUpload!.uploadedTime!.toDate())}', style: const TextStyle(color: Colors.white)),
                        Text('Status: ${latestUpload!.status}', style: const TextStyle(color: Colors.white)),
                        if (latestUpload!.status == 'Rejected') 
                          Text('Rejected reason: ${latestUpload!.rejectionReason}', style: const TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text('No recent activity', style: TextStyle(color: Colors.white)),
              trailing: ElevatedButton(
                onPressed: () {
                  navigateToUserHistory();
                },
                child: const Text('View History', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> navigateToUserHistory() async {
    // Navigate to the UserProfilePage and wait for the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewUserUploadHistoryPage()),
    );

    // Check if the UserProfilePage indicates that data needs to be refreshed
    if (result == 'refresh') {
      await fetchUploadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              color: Colors.green, // Green background for the header and carousel
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 60),
                  _buildUserHeader(), // User profile and welcome text
                  _buildTopCarousel(),
                ],
              ),
            ),
            const SizedBox(height: 20,),
            if (GlobalUser.userLevel == 1) _buildAdminFunctionsTitle(),
            if (GlobalUser.userLevel == 1) _buildAdminFunctionsRow(context),
            const SizedBox(height: 20,),
            _buildActivitiesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _onItemTapped(2), // Handle QR Scan navigation
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 16.0, bottom: 16.0, right: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Welcome,',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                GlobalUser.userName ?? 'User',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 40, color: Colors.white,),
            onPressed: () {
              navigateToUserProfilePage();
            },
          ),
        ],
      ),
    );
  }

  Future<void> navigateToUserProfilePage() async {
    // Navigate to the UserProfilePage and wait for the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfilePage()),
    );

    // Check if the UserProfilePage indicates that data needs to be refreshed
    if (result == 'refresh') {
      await fetchUploadData();
    }
  }

  Widget _buildAdminFunctionsTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Admin\'s functions',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _buildAdminFunctionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _buildMenuButton(context, Icons.admin_panel_settings, 'Map for Admin', () => navigateToMapScreenAdmin()),
        _buildMenuButton(context, Icons.verified_user, 'Verify for Rewards', () => navigateToVerifyRewardPage()),
        _buildMenuButton(context, Icons.view_list, 'View Reports', () => navigateToAdminReportsPage()),
      ],
    );
  }

  Future navigateToVerifyRewardPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerifyRewardPage()),
    );

    // Check if the result is 'updateNeeded' and refresh data accordingly
    if (result == 'refresh') {
      await fetchUploadData();
    }
  }

  Future<void> navigateToMapScreenAdmin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreenAdmin(title: 'Admin View Map')),
    );

    // Check if the result is 'updateNeeded' and refresh data accordingly
    if (result == 'refresh') {
      await fetchUploadData();
    }
  }

  Future<void> navigateToAdminReportsPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminReportsPage()),
    );

    // Check if the result is 'updateNeeded' and refresh data accordingly
    if (result == 'refresh') {
      await fetchUploadData();
    }
  }

  Widget _buildMenuButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap, // Use the onTap callback here
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10), // Padding inside the container
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.lightGreen, Colors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50.0, color: Colors.white),
              const SizedBox(height: 5), // Space between the icon and the text
              Text(label, style: const TextStyle(fontSize: 16.0, color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
  return Stack(
    clipBehavior: Clip.none, // Allows elements to be drawn outside of the stack
    alignment: Alignment.topCenter,
    children: [
      BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            // Placeholder for the QR scan button
            icon: SizedBox(height: 25, width: 0),
            label: 'QR Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.discount),
            label: 'View Reward',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Report Issues',
          ),
        ],
        onTap: _onItemTapped,
      ),
    ],
  );
}


  void _onItemTapped(int index) {
    if (index == 0) {
      // If the home button is tapped, do nothing or refresh the home page
    } else {
      // Handle navigation for other buttons
      _handleNavigation(index);
    }
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomePage()));
        break;
      case 1:
        navigateToUserFunctions(1);
        break;
      case 2:
        navigateToUserFunctions(2);
        break;
      case 3:
        navigateToUserFunctions(3);
        break;
      case 4:
        navigateToUserFunctions(4);
        break;
      default:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomePage()));
        break;
    }
  }

  Future<void> navigateToUserFunctions(int index) async {
    
    switch (index) {
      case 1:
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapScreenUser(title: 'User View Map')),
        );
        
        if (result == 'refresh') {
          await fetchUploadData();
        }
        break;
      case 2:
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QRScanScreen(title: 'Scan QR')),
        );
        
        if (result == 'refresh') {
          await fetchUploadData();
        }
        break;
      case 3:
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ViewRewardPage()),
        );
        
        if (result == 'refresh') {
          await fetchUploadData();
        }
        break;
      case 4:
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportIssueScreen(title: 'Report an Issue')),
        );
        
        if (result == 'refresh') {
          await fetchUploadData();
        }
        break;
      
      default:
    }
  }

  Widget _buildTopCarousel() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: Colors.green,
          ),
          child: CarouselSlider(
            options: CarouselOptions(
              autoPlay: true,
              aspectRatio: 2.0,
              enlargeCenterPage: true,
              viewportFraction : 1.0,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
            items: imageUrls.map((url) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.network(url, fit: BoxFit.contain), // Using BoxFit.contain
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: imageUrls.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentCarouselIndex == entry.key
                      ? const Color.fromARGB(255, 0, 98, 4)
                      : Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

}
