import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportDetailsPage extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final String documentId;

  const ReportDetailsPage({Key? key, required this.reportData, required this.documentId})
      : super(key: key);

  void _markAsSolved(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('reports issues')
        .doc(documentId)
        .update({'status': 'solved'});

    // Pop back to the previous page after marking as solved
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(reportData['title'] ?? 'Report Details'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description: ${reportData['description'] ?? 'Not provided'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Phone Number: ${reportData['phoneNumber'] ?? 'Not provided'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            reportData['imageUrl'] != null && reportData['imageUrl'].toString().isNotEmpty
                ? Image.network(
                    reportData['imageUrl'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 20),
            if (reportData['status'] != 'solved') // Only show button if the issue isn't already solved
              ElevatedButton(
                onPressed: () => _markAsSolved(context),
                style: ElevatedButton.styleFrom(
                  primary: Colors.red, // Button background color
                ),
                child: const Text("Mark as Solved"),
              )
          ],
        ),
      ),
    );
  }
}
