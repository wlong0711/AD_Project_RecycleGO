import 'package:flutter/material.dart';
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
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreenAdmin(title: 'Admin View Map')),
            );
          },
          child: const Text('Map for Admin'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VerifyRewardPage()),
            );
          },
          child: const Text('Verify for Rewards'),
        ),
      ],
    );
  }

  Widget _commonButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreenUser(title: 'User View Map')),
            );
          },
          child: const Text('Map'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScanScreen(title: 'Scan QR')),
            );
          },
          child: const Text('Scan QR'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportIssueScreen(title: 'Report an Issue')),
            );
          },
          child: const Text('Report Issue'),
        ),
      ],
    );
  }
}
