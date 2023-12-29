import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recycle_go/Admin%20Only%20Pages/report_details.dart';
import 'package:recycle_go/Shared%20Pages/Transition%20Page/transition_page.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  _AdminReportsPageState createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TabController? _tabController;

  OverlayEntry? _overlayEntry;
  final int loadingTimeForOverlay = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOverlay();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => TransitionOverlay(
        iconData: Icons.view_list, // The icon you want to show
        duration: Duration(seconds: loadingTimeForOverlay), // Duration for the transition
        pageName: "Fetching Report List",
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

  Widget buildReportList(String status) {
    return StreamBuilder(
      stream: _firestore
          .collection('reports issues')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          // return const Text('Something went wrong');
          // Log the error or use a developer tool to inspect the error
          print(snapshot.error);
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        // Categorize reports by month
        Map<String, List<DocumentSnapshot>> categorizedReports = {};
        for (var doc in snapshot.data!.docs) {
          Timestamp timestamp = doc['timestamp'] as Timestamp;
          String monthYear = DateFormat('MMMM yyyy').format(timestamp.toDate());

          if (!categorizedReports.containsKey(monthYear)) {
            categorizedReports[monthYear] = [];
          }
          categorizedReports[monthYear]!.add(doc);
        }

        List<String> sortedKeys = categorizedReports.keys.toList();
        sortedKeys.sort((a, b) => b.compareTo(a)); // For descending order

        return ListView.builder(
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            String monthYear = sortedKeys[index];
            List<DocumentSnapshot> monthReports = categorizedReports[monthYear]!;

            return ExpansionTile(
              title: Text(monthYear),
              children: monthReports.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Text(DateFormat('dd MMMM yyyy – kk:mm').format((data['timestamp'] as Timestamp).toDate())),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailsPage(reportData: data, documentId: doc.id),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Issues"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "To Solve"),
            Tab(text: "Solved"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildReportList("to solve"), // to solve tab
          buildReportList("solved"),   // solved tab
        ],
      ),
    );
  }
}
