import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_post.dart';
import '../models/community_group.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

/// 내가 속한 공동체 목록
final myCommunitiesProvider = StreamProvider<List<CommunityGroup>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).myCommunitiesStream(user.uid);
});

/// 특정 공동체의 게시물 스트림
final communityFeedProvider =
    StreamProvider.family<List<CommunityPost>, String>((ref, communityId) {
  return ref.read(firestoreServiceProvider).getCommunityPosts(communityId);
});

// 하위 호환 — 기존 코드에서 communityPostsProvider를 참조하는 곳이 없도록 제거됨
// featured 게시물 — 홈 오늘의 QT 카드용 (내 공동체 전체에서 isFeatured인 것)
final featuredPostProvider = Provider<CommunityPost?>((ref) {
  final communities = ref.watch(myCommunitiesProvider).valueOrNull ?? [];
  for (final group in communities) {
    final posts =
        ref.watch(communityFeedProvider(group.id)).valueOrNull ?? [];
    try {
      return posts.firstWhere((p) => p.isFeatured);
    } catch (_) {
      continue;
    }
  }
  return null;
});
