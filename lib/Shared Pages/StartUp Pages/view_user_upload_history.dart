import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:recycle_go/models/global_user.dart';
import 'package:recycle_go/models/upload.dart';

class ViewUserUploadHistoryPage extends StatefulWidget {
  const ViewUserUploadHistoryPage({super.key});

  @override
  _ViewUserUploadHistoryPageState createState() => _ViewUserUploadHistoryPageState();
}

class _ViewUserUploadHistoryPageState extends State<ViewUserUploadHistoryPage> {

  bool _isSortedByOldest = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
          onPressed: () => Navigator.of(context).pop('refresh'), // Go back on press
        ),
        title: const Text(
          "Upload History",
          style: TextStyle(color: Colors.white),
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
        actions: <Widget>[
          InkWell(
            onTap: _toggleSortOrder,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort by ${_isSortedByOldest ? "Latest" : "Oldest"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold, // Make text bold
                      fontSize: 16, // Optionally adjust font size as needed
                    ),
                  ),
                  Icon(
                    _isSortedByOldest ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('uploads')
            .where('userId', isEqualTo: GlobalUser.userID)
            .orderBy('uploadedTime', descending: _isSortedByOldest)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Center(child: CircularProgressIndicator());
            default:
              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No uploads found.'));
              }
              return ListView(
                children: snapshot.data!.docs.map((document) {
                  return _buildUploadItem(Upload.fromFirestore(document));
                }).toList(),
              );
          }
        },
      )
    );
  }

  void _toggleSortOrder() {
    setState(() {
      _isSortedByOldest = !_isSortedByOldest;
    });
  }

  Widget _buildUploadItem(Upload upload) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(upload.locationName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Uploaded at : ${DateFormat('dd/MM/yyyy HH:mm').format(upload.uploadedTime!.toDate())}'),
                  if (upload.verifiedTime != null)
                    Text('Verified at : ${DateFormat('dd/MM/yyyy HH:mm').format(upload.verifiedTime!.toDate())}'),
                  Text('Status: ${upload.status}'),
                  if (upload.status == 'Rejected')
                    Text('Rejection Reason: ${upload.rejectionReason}'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                upload.status == 'Approved' ? '+ 100 Points' : 'No Point Added',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: upload.status == 'Approved' ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
