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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Welcome, ${GlobalUser.userName ?? 'User'}!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20), // Spacing after the welcome text

            // Common Buttons
            _commonButtons(context),

            // Admin-only Buttons
            if (GlobalUser.userLevel == 1) 
              _adminOnlyButtons(context),

          ],
        ),
      ),
    );
  }

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
