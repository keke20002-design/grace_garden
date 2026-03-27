import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityGroup {
  final String id;
  final String name;
  final String creatorUid;
  final DateTime createdAt;
  final int memberCount;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.creatorUid,
    required this.createdAt,
    this.memberCount = 1,
  });

  factory CommunityGroup.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityGroup(
      id: doc.id,
      name: data['name'] ?? '',
      creatorUid: data['creatorUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberCount: data['memberCount'] ?? 1,
    );
  }

  Map<String, dynamic> toMap(String uid, String password) => {
        'id': id,
        'name': name,
        'password': password,
        'creatorUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
      };
}
