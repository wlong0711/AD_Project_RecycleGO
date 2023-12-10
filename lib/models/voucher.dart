import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String voucherID;
  final String voucherName;
  final DateTime expiredDate;

  Voucher({
    required this.voucherID,
    required this.voucherName,
    required this.expiredDate,
  });

  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Voucher(
      voucherID: data['voucherID'] ?? '',
      voucherName: data['voucherName'] ?? '',
      expiredDate: (data['expiredDate'] as Timestamp).toDate(),
    );
  }
}
