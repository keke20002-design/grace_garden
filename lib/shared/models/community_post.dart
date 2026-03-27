import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String communityId; // 소속 공동체 ID
  final String uid;
  final String displayName;
  final String scriptureTitle;
  final String scriptureVerse;
  final String prayer;
  final String? meditation;
  final int amenCount;
  final List<String> amenUids;
  final DateTime createdAt;
  final bool isFeatured; // 별표 — 홈 오늘의 QT 카드에 표시

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.uid,
    required this.displayName,
    required this.scriptureTitle,
    required this.scriptureVerse,
    required this.prayer,
    this.meditation,
    this.amenCount = 0,
    this.amenUids = const [],
    required this.createdAt,
    this.isFeatured = false,
  });

  factory CommunityPost.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '익명',
      scriptureTitle: data['scriptureTitle'] ?? '',
      scriptureVerse: data['scriptureVerse'] ?? '',
      prayer: data['prayer'] ?? '',
      meditation: data['meditation'],
      amenCount: data['amenCount'] ?? 0,
      amenUids: List<String>.from(data['amenUids'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'communityId': communityId,
        'uid': uid,
        'displayName': displayName,
        'scriptureTitle': scriptureTitle,
        'scriptureVerse': scriptureVerse,
        'prayer': prayer,
        'meditation': meditation,
        'amenCount': amenCount,
        'amenUids': amenUids,
        'isFeatured': isFeatured,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
