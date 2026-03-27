import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/community_post.dart';
import '../models/community_group.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── 공동체 그룹 ────────────────────────────────────────────────

  /// 공동체 만들기 — 생성 후 자동으로 creator를 멤버로 추가. communityId 반환.
  Future<String> createCommunity({
    required String uid,
    required String name,
    required String password,
  }) async {
    final communityId = const Uuid().v4().substring(0, 8).toUpperCase();
    final group = CommunityGroup(
      id: communityId,
      name: name,
      creatorUid: uid,
      createdAt: DateTime.now(),
    );
    await _db
        .collection('communities')
        .doc(communityId)
        .set(group.toMap(uid, password));
    await _addMembership(uid: uid, communityId: communityId, communityName: name);
    return communityId;
  }

  /// 공동체 입장 — ID와 비밀번호 검증. 성공하면 CommunityGroup 반환, 실패하면 null.
  Future<CommunityGroup?> joinCommunity({
    required String uid,
    required String communityId,
    required String password,
  }) async {
    final doc = await _db.collection('communities').doc(communityId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['password'] != password) return null;

    // 이미 멤버인지 확인
    final membershipId = '${uid}_$communityId';
    final existing =
        await _db.collection('community_memberships').doc(membershipId).get();
    if (!existing.exists) {
      await _addMembership(
        uid: uid,
        communityId: communityId,
        communityName: data['name'] as String,
      );
      await _db.collection('communities').doc(communityId).update({
        'memberCount': FieldValue.increment(1),
      });
    }
    return CommunityGroup.fromDoc(doc);
  }

  Future<void> _addMembership({
    required String uid,
    required String communityId,
    required String communityName,
  }) async {
    final membershipId = '${uid}_$communityId';
    await _db.collection('community_memberships').doc(membershipId).set({
      'uid': uid,
      'communityId': communityId,
      'communityName': communityName,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 내가 속한 공동체 목록 스트림
  Stream<List<CommunityGroup>> myCommunitiesStream(String uid) {
    return _db
        .collection('community_memberships')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snap) async {
      final groups = <CommunityGroup>[];
      for (final m in snap.docs) {
        final cid = m.data()['communityId'] as String;
        final doc = await _db.collection('communities').doc(cid).get();
        if (doc.exists) groups.add(CommunityGroup.fromDoc(doc));
      }
      return groups;
    });
  }

  /// 공동체 이름 수정 (방장 전용)
  Future<void> updateCommunityName(String communityId, String newName) async {
    await _db.collection('communities').doc(communityId).update({'name': newName});
  }

  // ── 공동체 나눔 ────────────────────────────────────────────────

  /// 특정 공동체의 게시물 스트림
  Stream<List<CommunityPost>> getCommunityPosts(String communityId) {
    return _db
        .collection('community_posts')
        .where('communityId', isEqualTo: communityId)
        .limit(50)
        .snapshots()
        .map((snap) {
          final posts = snap.docs.map(CommunityPost.fromDoc).toList();
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  Future<void> sharePost(CommunityPost post) async {
    await _db.collection('community_posts').add(post.toMap());
  }

  Future<void> toggleAmen(String postId, String uid) async {
    final ref = _db.collection('community_posts').doc(postId);
    final doc = await ref.get();
    final data = doc.data()!;
    final amenUids = List<String>.from(data['amenUids'] ?? []);

    if (amenUids.contains(uid)) {
      await ref.update({
        'amenUids': FieldValue.arrayRemove([uid]),
        'amenCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'amenUids': FieldValue.arrayUnion([uid]),
        'amenCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> updatePost(
    String postId, {
    required String scriptureTitle,
    required String scriptureVerse,
    required String prayer,
    String? meditation,
  }) async {
    await _db.collection('community_posts').doc(postId).update({
      'scriptureTitle': scriptureTitle,
      'scriptureVerse': scriptureVerse,
      'prayer': prayer,
      'meditation': meditation,
    });
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('community_posts').doc(postId).delete();
  }

  Future<void> toggleFeatured(
      String postId, bool current, String communityId) async {
    if (!current) {
      final snap = await _db
          .collection('community_posts')
          .where('communityId', isEqualTo: communityId)
          .where('isFeatured', isEqualTo: true)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isFeatured': false});
      }
      batch.update(
        _db.collection('community_posts').doc(postId),
        {'isFeatured': true},
      );
      await batch.commit();
    } else {
      await _db
          .collection('community_posts')
          .doc(postId)
          .update({'isFeatured': false});
    }
  }

  // ── 유저 프로필 동기화 ─────────────────────────────────────────

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}
