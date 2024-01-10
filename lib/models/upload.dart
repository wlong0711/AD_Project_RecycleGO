import 'package:cloud_firestore/cloud_firestore.dart';

class Upload {
  String locationName;
  String videoUrl;
  String? userName;
  String? docId;
  Timestamp? uploadedTime;
  Timestamp? verifiedTime;
  final String? status;
  final String? rejectionReason;

  Upload({
    required this.locationName,
    required this.videoUrl,
    this.userName,
    this.docId,
    this.uploadedTime,
    this.verifiedTime,
    this.status,
    this.rejectionReason
  });

  factory Upload.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Upload(
      locationName: data['location'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      userName: data['username'] as String? ?? '',
      docId: doc.id,
      uploadedTime: data['uploadedTime'] as Timestamp?,
      verifiedTime: data['verifiedTime'] as Timestamp?,
      status: data['status'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }
}
