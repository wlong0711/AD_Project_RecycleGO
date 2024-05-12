import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_go/Component/dialogs.dart';

class ReportDetailsPage extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final String documentId;

  const ReportDetailsPage({super.key, required this.reportData, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom icon and color
          onPressed: () => Navigator.of(context).pop(), // Go back on press
        ),
        title: Text(reportData['title'] ?? 'Report Details', style: const TextStyle(color: Colors.white),),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green],
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showErrorDialog(context, "Error: ${snapshot.error}");
            });
            return const SizedBox.shrink();
          }
          return const Center(child: CircularProgressIndicator());
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
          if (reportData['imageUrl'] != null && reportData['imageUrl'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Image.network(
              reportData['imageUrl'],
              fit: BoxFit.cover, // Change this as needed
              // Add some error handling
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return const Text('Failed to load image');
              },
            ),
          ),
          
          const SizedBox(height: 20), // Provide some spacing before the button
          if (reportData['status'] != 'solved')
            Center( // Wrap the ElevatedButton with Center
              child: ElevatedButton(
                onPressed: () => _markAsSolved(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, disabledForegroundColor: Colors.greenAccent.withOpacity(0.38), disabledBackgroundColor: Colors.greenAccent.withOpacity(0.12), // Surface color
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                  child: Text("Mark as Solved", style: TextStyle(color: Colors.white),),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _markAsSolved(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(documentId)
          .update({'status': 'solved'});
      Navigator.of(context).pop('refresh'); // Pop back to the previous page
    } catch (e) {
      // Use the centralized error dialog
      showErrorDialog(context, 'Failed to mark as solved: $e');
    }
  }
}