import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_post.dart';
import '../models/community_group.dart';
import '../providers/community_provider.dart';

/// QT 작성/기도카드에서 공동체 나눔 공유 시 공통으로 사용하는 헬퍼.
/// - 공동체 0개: 안내 스낵바 표시
/// - 공동체 1개: 자동 선택 후 공유
/// - 공동체 2개 이상: 선택 다이얼로그 표시
Future<bool> shareToCommunity({
  required BuildContext context,
  required WidgetRef ref,
  required CommunityPost Function(String communityId) buildPost,
}) async {
  final communities =
      ref.read(myCommunitiesProvider).valueOrNull ?? [];

  if (communities.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('먼저 공동체에 참여해야 나눔을 공유할 수 있어요 🤝'),
      ),
    );
    return false;
  }

  CommunityGroup? selected;

  if (communities.length == 1) {
    selected = communities.first;
  } else {
    // 공동체 선택 다이얼로그
    selected = await showDialog<CommunityGroup>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('어느 공동체에 나눔할까요?'),
        children: communities
            .map(
              (g) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, g),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(g.name.isNotEmpty ? g.name[0] : '?'),
                      ),
                      const SizedBox(width: 12),
                      Text(g.name, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  if (selected == null) return false;

  final post = buildPost(selected.id);
  await ref.read(firestoreServiceProvider).sharePost(post);
  return true;
}
