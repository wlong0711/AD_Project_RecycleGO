import 'package:flutter/material.dart';

class ReportDetailsPage extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailsPage({super.key, required this.reportData});

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
          ],
        ),
      ),
    );
  }
}
