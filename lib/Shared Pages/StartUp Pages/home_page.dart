import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:recycle_go/Admin%20Only%20Pages/view_report_issues.dart';
import 'package:recycle_go/Shared%20Pages/QR%20Scan%20&%20Upload%20Page/qr_scan_screen.dart';
import 'package:recycle_go/Admin%20Only%20Pages/verify_reward.dart';
import 'package:recycle_go/models/global_user.dart';
import 'package:recycle_go/User%20Only%20Pages/report_issues.dart';
import '../../Admin Only Pages/map_screen_admin.dart';
import '../../User Only Pages/map_screen_user.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: ListView(
        children: <Widget>[
          _buildTopCarousel(),
          _buildWelcomeText(),
          _buildGridMenu(context),
          // _buildNewsFeed(),
        ],
      ),
    );
  }

  Widget _buildTopCarousel() {
    // Placeholder for carousel images
    final List<String> imgList = [
      'assets/image1.jpg',
      'assets/image2.jpg',
      // Add more images
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        aspectRatio: 2.0,
        enlargeCenterPage: true,
      ),

      items: imgList.map((item) => Container(
        child: Center(
          child: Image.asset(item, fit: BoxFit.cover, width: 1000)
        ),
      )).toList(),
    );
  }

  Widget _buildWelcomeText() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'Welcome, ${GlobalUser.userName ?? 'User'}!',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true, // Important to prevent infinite height error
    physics: NeverScrollableScrollPhysics(), // to disable GridView's scrolling
    children: <Widget>[
      _buildMenuButton(context, Icons.map, 'Map', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreenUser(title: 'User View Map')),
        );
      }),
      _buildMenuButton(context, Icons.qr_code_scanner, 'Scan QR', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QRScanScreen(title: 'Scan QR')),
        );
      }),
      _buildMenuButton(context, Icons.report_problem, 'Report Issue', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportIssueScreen(title: 'Report an Issue')),
        );
      }),
      // Add more buttons as needed
    ],
  );
}

Widget _buildMenuButton(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
  return Card(
    child: InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50.0),
          Text(label, style: TextStyle(fontSize: 16.0))
        ],
      ),
    ),
  );
}

  // Widget _buildNewsFeed() {
  //   // Fetch news articles or posts from a database or API
  //   // Display them here as a list or cards
  // }

  Widget _adminOnlyButtons(BuildContext context) {
  return Column(
    children: [
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreenAdmin(title: 'Admin View Map')),
          );
        },
        icon: Icon(Icons.admin_panel_settings), // Icon for Admin Map
        label: const Text('Map for Admin'),
      ),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VerifyRewardPage()),
          );
        },
        icon: Icon(Icons.verified_user), // Icon for Verify Rewards
        label: const Text('Verify for Rewards'),
      ),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminReportsPage()),
          );
        },
        icon: Icon(Icons.view_list), // Icon for View Reports
        label: const Text('View Reports'),
      ),
    ],
  );
}

  Widget _commonButtons(BuildContext context) {
  return Column(
    children: [
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreenUser(title: 'User View Map')),
          );
        },
        icon: Icon(Icons.map), // Icon for Map
        label: const Text('Map'),
      ),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScanScreen(title: 'Scan QR')),
          );
        },
        icon: Icon(Icons.qr_code_scanner), // Icon for QR Scan
        label: const Text('Scan QR'),
      ),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportIssueScreen(title: 'Report an Issue')),
          );
        },
        icon: Icon(Icons.report_problem), // Icon for Report Issue
        label: const Text('Report Issue'),
      ),
    ],
  );
}
}
