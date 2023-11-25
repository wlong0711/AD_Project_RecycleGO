// home_page.dart
import 'package:flutter/material.dart';
import 'package:recycle_go/Shared%20Pages/QR%20Scan%20&%20Upload%20Page/qr_scan_screen.dart';
import 'package:recycle_go/Admin%20Only%20Pages/verify_reward.dart';
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreenAdmin(title:'Admin View Map')),
                );
              },
              child: const Text('Map for Admin'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreenUser(title:'User View Map')),
                );
              },
              child: const Text('Map for User'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VerifyRewardPage()),
                );
              },
              child: const Text('Rewards'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScanScreen(title:'Scan QR')),
                );
              },
              child: const Text('Scan QR'),
            ),
          ],
        ),
      ),
    );
  }
}
