import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportDetailsPage extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final String documentId;

  const ReportDetailsPage({Key? key, required this.reportData, required this.documentId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(reportData['title'] ?? 'Report Details'),
        // AppBar styling...
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(reportData['userId']).get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
            return _buildReportDetails(context, userData);
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildReportDetails(BuildContext context, Map<String, dynamic> userData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView( // Changed to ListView for long contents
        children: [
          Text(
            'Reported by: ${userData['username'] ?? 'Anonymous'}',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Email: ${userData['email'] ?? 'No email provided'}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            'Description: ${reportData['description'] ?? 'Not provided'}',
            style: const TextStyle(fontSize: 16),
          ),
          // Other details...
          const SizedBox(height: 20), // Provide some spacing before the button
          if (reportData['status'] != 'solved')
            Center( // Wrap the ElevatedButton with Center
              child: ElevatedButton(
                onPressed: () => _markAsSolved(context),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green, // Button background color
                  onSurface: Colors.greenAccent, // Surface color
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                  child: const Text("Mark as Solved"),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _markAsSolved(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('reports issues')
        .doc(documentId)
        .update({'status': 'solved'});

    Navigator.of(context).pop(); // Pop back to the previous page after marking as solved
  }
}