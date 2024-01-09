import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:recycle_go/Admin%20Only%20Pages/view_report_issues.dart';
import 'package:recycle_go/Shared%20Pages/QR%20Scan%20&%20Upload%20Page/qr_scan_screen.dart';
import 'package:recycle_go/Admin%20Only%20Pages/verify_reward.dart';
import 'package:recycle_go/Shared%20Pages/StartUp%20Pages/UserProfilePage.dart';
import 'package:recycle_go/Shared%20Pages/View%20Reward%20Page/view_reward.dart';
import 'package:recycle_go/models/global_user.dart';
import 'package:recycle_go/User%20Only%20Pages/report_issues.dart';
import '../../Admin Only Pages/map_screen_admin.dart';
import '../../User Only Pages/map_screen_user.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _currentCarouselIndex = 0;
  final List<String> imageUrls = [
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2FRecycle-Right-Banner.jpg?alt=media&token=0f09deef-3e48-4833-9614-b299289bf226',
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2Frecycling-poster-final.webp?alt=media&token=f1e1d089-ee91-4883-bf38-0ff17bfcc4a3',
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2Ft-t-4256-eco-and-recycling-the-future-of-the-planet-display-poster_ver_1.webp?alt=media&token=c95bb98d-a132-4909-a295-71cd92bbf9c7',
    ];

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
                  SizedBox(height: 60),
                  _buildUserHeader(), // User profile and welcome text
                  _buildTopCarousel(),
                ],
              ),
            ),
            if (GlobalUser.userLevel == 1) _buildAdminFunctionsTitle(),
            if (GlobalUser.userLevel == 1) _buildAdminFunctionsRow(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _onItemTapped(2), // Handle QR Scan navigation
        child: Icon(Icons.qr_code_scanner, color: Colors.white),
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
              Text(
                'Welcome,',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '${GlobalUser.userName ?? 'User'}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 40, color: Colors.white,),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserProfilePage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFunctionsTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Admin\'s functions',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget _buildAdminFunctionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _buildMenuButton(context, Icons.admin_panel_settings, 'Map for Admin', const MapScreenAdmin(title: 'Admin View Map')),
        _buildMenuButton(context, Icons.verified_user, 'Verify for Rewards', const VerifyRewardPage()),
        _buildMenuButton(context, Icons.view_list, 'View Reports', const AdminReportsPage()),
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context, IconData icon, String label, Widget page) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
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
        items: [
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
            icon: Container(height: 25, width: 0),
            label: 'QR Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
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
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MapScreenUser(title: 'User View Map')));
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QRScanScreen(title: 'Scan QR')));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViewRewardPage()));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportIssueScreen(title: 'Report an Issue')));
        break;
      default:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomePage()));
        break;
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
