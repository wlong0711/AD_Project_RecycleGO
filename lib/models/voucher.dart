import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String voucherID;
  final String voucherName;
  final int pointsNeeded;
  final DateTime expiredDate;

  Voucher({
    required this.voucherID,
    required this.voucherName,
    required this.pointsNeeded,
    required this.expiredDate,
  });

  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Voucher(
      voucherID: data['voucherID'] ?? '',
      voucherName: data['voucherName'] ?? '',
      pointsNeeded: data['pointsNeeded'] ?? 0,
      expiredDate: (data['expiredDate'] as Timestamp).toDate(),
    );
  }
}
