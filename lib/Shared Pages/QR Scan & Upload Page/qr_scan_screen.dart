import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:recycle_go/Shared%20Pages/QR%20Scan%20&%20Upload%20Page/upload_page.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key, required this.title});

  final String title;

  @override
  State<StatefulWidget> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller; // Nullable controller
  Barcode? result; // Nullable result
  bool uploadCompleted = false;

  @override
  void reassemble() {
    super.reassemble();
    // This is needed for the camera on Android when using hot reload
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child:  Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    setState(() {}); // Update the state to reflect the controller is initialized

    controller.scannedDataStream.listen((scanData) {
      setState(() => result = scanData);
      if (result != null && result!.code != null) {
        _navigateToNextScreen(context, result!.code!);
      }
    });
  }


  void _navigateToNextScreen(BuildContext context, String scanResult) {
    // Pause the camera before navigating away
    controller?.pauseCamera();
    try {
      final data = jsonDecode(scanResult);
      //read data from {"location": "location#1"}
      final String locationName = data['location'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadPage(
            locationName: locationName,
            onUploadCompleted: () {
              setState(() {
                uploadCompleted = true; // Use setState to update the flag
              });
            },
          ),
        ),
      ).then((value) {
        // Check if upload was completed and only resume camera if it wasn't
        if (!uploadCompleted && mounted && controller != null) {
          controller?.resumeCamera();
        }
      });
    } catch (e) {
      // Handle or show error that QR didn't contain valid data
      print('Error parsing scanned data: $e');
    }
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    controller?.dispose();
    super.dispose();
  }
}
