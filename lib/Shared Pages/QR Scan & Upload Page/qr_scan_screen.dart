import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:recycle_go/Shared%20Pages/QR%20Scan%20&%20Upload%20Page/upload_page.dart';
import 'package:recycle_go/Shared%20Pages/Transition%20Page/transition_page.dart';

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

  OverlayEntry? _overlayEntry;
  final int loadingTimeForOverlay = 1;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOverlay();
      }
    });
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => TransitionOverlay(
        iconData: Icons.qr_code_scanner, // The icon you want to show
        duration: Duration(seconds: loadingTimeForOverlay), // Duration for the transition
        pageName: "Preparing Camera",
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(Duration(seconds: loadingTimeForOverlay), () {
      if (mounted) {
        _removeOverlay();
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
          onPressed: () => Navigator.of(context).pop(), // Go back on press
        ),
        title: Text(
                widget.title,
                style: const TextStyle(color: Colors.white),
              ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 10,
        shadowColor: Colors.greenAccent.withOpacity(0.5),
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
      final String locationName = data['location'];

      FirebaseFirestore.instance.collection('drop_points')
        .where('title', isEqualTo: locationName)
        .get()
        .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            final docSnapshot = querySnapshot.docs.first;
            int currentCapacity = docSnapshot.data()['currentCapacity'];
            int maxCapacity = docSnapshot.data()['maxCapacity'];

            if (currentCapacity < maxCapacity) {
              // Navigate to UploadPage if bin is not full
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
              ).then((value) => _handleAfterUpload(context));
            } else {
              // Show bin full dialog if bin is full
              _showBinFullDialog(context);
            }
          } else {
            print('No drop point found with the name: $locationName');
          }
        });
    } catch (e) {
      print('Error parsing scanned data: $e');
    }
  }

  void _handleAfterUpload(BuildContext context) {
    // This function is called after returning from the UploadPage
    if (!uploadCompleted && mounted && controller != null) {
      controller?.resumeCamera();
    }
  }

  void _showBinFullDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Bin Full'),
          content: const Text('This bin is full already.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                // Optionally, you can navigate back to a specific page in the stack
                // Navigator.popUntil(context, ModalRoute.withName('/specificPage'));
                Navigator.of(context).pop(); // Navigate back to the previous page
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    controller?.dispose();
    super.dispose();
  }
}