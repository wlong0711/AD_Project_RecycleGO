import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildTopCarousel(),
            _buildWelcomeText(),
            _buildGridMenu(context),
            // _buildNewsFeed(), // Uncomment if you want to include a news feed
          ],
        ),
      ),
    );
  }

  Widget _buildTopCarousel() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('Banner').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error fetching images'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No images found'));
        }

        List<DocumentSnapshot> documents = snapshot.data!.docs;
        return CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            aspectRatio: 2.0,
            enlargeCenterPage: true,
          ),
          items: documents.map((doc) => Container(
            child: Center(
              child: Image.network(
                doc[''],
                fit: BoxFit.cover,
                width: 1000,
              ),
            ),
          )).toList(),
        );
      },
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
      shrinkWrap: true, 
      physics: NeverScrollableScrollPhysics(),
      children: <Widget>[
        // Common User Actions
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
        
        // Admin-Only Actions
        if (GlobalUser.userLevel == 1) _buildMenuButton(context, Icons.admin_panel_settings, 'Map for Admin', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreenAdmin(title: 'Admin View Map')),
          );
        }),
        if (GlobalUser.userLevel == 1) _buildMenuButton(context, Icons.verified_user, 'Verify for Rewards', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VerifyRewardPage()),
          );
        }),
        if (GlobalUser.userLevel == 1) _buildMenuButton(context, Icons.view_list, 'View Reports', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminReportsPage()),
          );
        }),
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
