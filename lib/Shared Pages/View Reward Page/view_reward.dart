import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recycle_go/models/global_user.dart';
import 'package:recycle_go/models/voucher.dart';

import 'add_voucher_page.dart'; // Assume this is the file where the Voucher class is defined

class ViewRewardPage extends StatefulWidget {
  const ViewRewardPage({super.key});

  @override
  _ViewRewardPageState createState() => _ViewRewardPageState();
}

class _ViewRewardPageState extends State<ViewRewardPage> {
  List<Voucher> vouchers = [];

  @override
  void initState() {
    super.initState();
    fetchVouchers();
  }

  void fetchVouchers() async {
    var querySnapshot = await FirebaseFirestore.instance.collection('vouchers').get();
    var fetchedVouchers = querySnapshot.docs.map((doc) => Voucher.fromFirestore(doc)).toList();

    setState(() {
      vouchers = fetchedVouchers;
    });
  }

  void navigateToAddVoucherPage() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AddVoucherPage()),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Rewards'),
        actions: [
          if (GlobalUser.userLevel == 1) // Check if user is admin
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: navigateToAddVoucherPage,
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          var voucher = vouchers[index];
          return ListTile(
            title: Text(voucher.voucherName),
            subtitle: Text('Expires on: ${voucher.expiredDate.toLocal()}'),
            trailing: Text('ID: ${voucher.voucherID}'),
          );
        },
      ),
    );
  }
}
