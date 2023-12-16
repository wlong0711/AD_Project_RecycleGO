import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recycle_go/Shared%20Pages/View%20Reward%20Page/add_voucher_page.dart';
import 'package:recycle_go/models/global_user.dart';
import 'package:recycle_go/models/voucher.dart';

class ViewRewardPage extends StatefulWidget {
  const ViewRewardPage({super.key});

  @override
  _ViewRewardPageState createState() => _ViewRewardPageState();
}

class _ViewRewardPageState extends State<ViewRewardPage> {
  List<Voucher> vouchers = [];
  List<String> claimedVouchers = [];

  @override
  void initState() {
    super.initState();
    fetchVouchers();
    fetchClaimedVouchers();
  }

  void fetchVouchers() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('vouchers').get();
    List<Voucher> fetchedVouchers = querySnapshot.docs.map((doc) => Voucher.fromFirestore(doc)).toList();
    setState(() {
      vouchers = fetchedVouchers;
    });
  }

  void fetchClaimedVouchers() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users')
        .where('username', isEqualTo: GlobalUser.userName).get().then((snapshot) => snapshot.docs.first);
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        claimedVouchers = List<String>.from(data['claimedVouchers'] ?? []);
      });
    }
  }

  void claimVoucher(String voucherId) async {
    if (!claimedVouchers.contains(voucherId)) {
      claimedVouchers.add(voucherId);
      await FirebaseFirestore.instance.collection('users')
          .where('username', isEqualTo: GlobalUser.userName)
          .get().then((snapshot) {
            var userDoc = snapshot.docs.first;
            userDoc.reference.update({
              'claimedVouchers': FieldValue.arrayUnion([voucherId])
            });
          });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Claimed successfully!'),
        backgroundColor: Colors.green,
      ));

      setState(() {}); // Update UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Rewards'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 10,
        shadowColor: Colors.greenAccent.withOpacity(0.5),
        actions: [
          if (GlobalUser.userLevel == 1)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddVoucherPage()),
                ).then((_) => fetchVouchers());
              },
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          Voucher voucher = vouchers[index];
          bool isClaimed = claimedVouchers.contains(voucher.voucherID);
          return ListTile(
            title: Text(voucher.voucherName),
            subtitle: Text('Expires on: ${voucher.expiredDate.toLocal()}'),
            trailing: Text('ID: ${voucher.voucherID}'),
            onTap: isClaimed ? null : () => claimVoucher(voucher.voucherID),
            leading: ElevatedButton(
              onPressed: isClaimed ? null : () => claimVoucher(voucher.voucherID),
              style: ElevatedButton.styleFrom(
                backgroundColor: isClaimed ? Colors.grey : Colors.blue,
              ),
              child: Text(isClaimed ? 'Claimed' : 'Claim'),
            ),
          );
        },
      ),
    );
  }
}
