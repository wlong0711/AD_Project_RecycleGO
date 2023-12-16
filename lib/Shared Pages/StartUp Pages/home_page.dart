import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:recycle_go/Admin%20Only%20Pages/view_report_issues.dart';
import 'package:recycle_go/Shared%20Pages/QR%20Scan%20&%20Upload%20Page/qr_scan_screen.dart';
import 'package:recycle_go/Admin%20Only%20Pages/verify_reward.dart';
import 'package:recycle_go/Shared%20Pages/View%20Reward%20Page/view_reward.dart';
import 'package:recycle_go/models/global_user.dart';
import 'package:recycle_go/User%20Only%20Pages/report_issues.dart';
import '../../Admin Only Pages/map_screen_admin.dart';
import '../../User Only Pages/map_screen_user.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 10,
        shadowColor: Colors.greenAccent.withOpacity(0.5),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildTopCarousel(),
            _buildWelcomeText(),
            _buildGridMenu(context),
            // _buildNewsFeed(),
          ],
        ),
      ),
      backgroundColor: Colors.lightBlue[50],
    );
  }

  Widget _buildTopCarousel() {
    final List<String> imageUrls = [
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2FRecycle-Right-Banner.jpg?alt=media&token=0f09deef-3e48-4833-9614-b299289bf226',
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2Frecycling-poster-final.webp?alt=media&token=f1e1d089-ee91-4883-bf38-0ff17bfcc4a3',
      'https://firebasestorage.googleapis.com/v0/b/recyclego-64b10.appspot.com/o/Banner%2Ft-t-4256-eco-and-recycling-the-future-of-the-planet-display-poster_ver_1.webp?alt=media&token=c95bb98d-a132-4909-a295-71cd92bbf9c7',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        aspectRatio: 2.0,
        enlargeCenterPage: true,
      ),
      items: imageUrls.map((url) => Container(
        child: Center(
          child: Image.network(url, fit: BoxFit.cover, width: 1000),
        ),
      )).toList(),
    );
  }

  Widget _buildWelcomeText() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Welcome, ${GlobalUser.userName ?? 'User'}!',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
  List<Widget> gridItems = [
    // Common User Actions
    _buildMenuButton(context, Icons.map, 'Map', const MapScreenUser(title: 'User View Map')),
    _buildMenuButton(context, Icons.qr_code_scanner, 'Scan QR', const QRScanScreen(title: 'Scan QR')),
    _buildMenuButton(context, Icons.report_problem, 'Report Issue', const ReportIssueScreen(title: 'Report an Issue')),
    _buildMenuButton(context, Icons.discount, 'View Reward', const ViewRewardPage()),

  ];

  // Admin-Only Actions
  if (GlobalUser.userLevel == 1) {
    gridItems.addAll([
      _buildMenuButton(context, Icons.admin_panel_settings, 'Map for Admin', const MapScreenAdmin(title: 'Admin View Map')),
      _buildMenuButton(context, Icons.verified_user, 'Verify for Rewards', const VerifyRewardPage()),
      _buildMenuButton(context, Icons.view_list, 'View Reports', const AdminReportsPage()),
    ]);
  }

  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: gridItems,
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
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
              Text(label, style: const TextStyle(fontSize: 16.0, color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }
  
  // Widget _buildNewsFeed() {
  //   // Fetch news articles or posts from a database or API
  //   // Display them here as a list or cards
  // }

  // Widget _adminOnlyButtons(BuildContext context) {
  // return GridView.count(
  //   crossAxisCount: 2,
  //   shrinkWrap: true, // Important to prevent infinite height error
  //   children: <Widget>[
  //       _buildMenuButton(context, Icons.admin_panel_settings, 'Map for Admin', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const MapScreenAdmin(title: 'Admin View Map')),
  //         );
  //       }),
  //       _buildMenuButton(context, Icons.verified_user, 'Verify for Rewards', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const VerifyRewardPage()),
  //         );
  //       }),
  //       _buildMenuButton(context, Icons.view_list, 'View Reports', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => AdminReportsPage()),
  //         );
  //       }),
  //       _buildMenuButton(context, Icons.map, 'Map', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const MapScreenUser(title: 'User View Map')),
  //         );
  //       }),
  //       _buildMenuButton(context, Icons.qr_code_scanner, 'Scan QR', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const QRScanScreen(title: 'Scan QR')),
  //         );
  //       }),
  //       _buildMenuButton(context, Icons.report_problem, 'Report Issue', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const ReportIssueScreen(title: 'Report an Issue')),
  //         );
  //       }),
  //     ],
  //   );
  // }

  // Widget _commonButtons(BuildContext context) {
  // return GridView.count(
  //   crossAxisCount: 1,
  //   shrinkWrap: true, // Important to prevent infinite height error
  //   physics: NeverScrollableScrollPhysics(), // to disable GridView's scrolling
  //   children: <Widget>[
  //       _buildMenuButton(context, Icons.map, 'Map', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const MapScreenUser(title: 'User View Map')),
  //         );
  //       }),
  //       _buildMenuButton(context, Icons.qr_code_scanner, 'Scan QR', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const QRScanScreen(title: 'Scan QR')),
  //         );
  //       }),
  //       _buildMenuButton(context, Icons.report_problem, 'Report Issue', () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const ReportIssueScreen(title: 'Report an Issue')),
  //         );
  //       }),
  //     ],
  //   );
  // }
}