import 'package:cloud_firestore/cloud_firestore.dart';

class Upload {
  String locationName;
  String videoUrl;
  String? userName;
  String? docId;
  Timestamp? uploadedTime;

  Upload({
    required this.locationName,
    required this.videoUrl,
    this.userName,
    this.docId,
    this.uploadedTime,
  });

  factory Upload.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Upload(
      locationName: data['location'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      userName: data['username'] as String? ?? '',
      docId: doc.id,
      uploadedTime: data['uploadedTime'] as Timestamp?,
    );
  }
}
