import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/community_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/models/community_post.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/widgets/native_ad_card.dart';

class CommunityFeedScreen extends ConsumerWidget {
  final String communityId;
  final String communityName;

  const CommunityFeedScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  void _showWriteSheet(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WriteSheet(
        communityId: communityId,
        uid: currentUser.uid,
        displayName: currentUser.displayName ?? '사용자',
        onSubmit: (text) async {
          final post = CommunityPost(
            id: '',
            communityId: communityId,
            uid: currentUser.uid,
            displayName: currentUser.displayName ?? '사용자',
            scriptureTitle: '',
            scriptureVerse: '',
            prayer: text,
            createdAt: DateTime.now(),
          );
          await ref.read(firestoreServiceProvider).sharePost(post);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityFeedProvider(communityId));
    final currentUser = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWriteSheet(context, ref),
        tooltip: '나눔 작성',
        child: const Icon(Icons.edit),
      ),
      appBar: AppBar(
        title: Text(communityName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: const Text('실시간'),
              avatar: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('불러오기 실패: $e'),
            ],
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    '아직 나눔이 없어요',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '첫 번째로 나눔을 나눠보세요!',
                    style: TextStyle(color: colorScheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          // 게시물 3개마다 광고 1개 삽입
          const adInterval = 4; // 게시물 3개 + 광고 1개
          final adCount = (posts.length / (adInterval - 1)).floor();
          final totalCount = posts.length + adCount;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: totalCount,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              // adInterval번째마다 광고 (0-based: 3, 7, 11...)
              if ((i + 1) % adInterval == 0) {
                return const NativeAdCard();
              }
              final postIndex = i - (i ~/ adInterval);
              if (postIndex >= posts.length) return const SizedBox.shrink();
              return _PostCard(
                post: posts[postIndex],
                currentUid: currentUser?.uid,
                communityId: communityId,
              );
            },
          );
        },
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final CommunityPost post;
  final String? currentUid;
  final String communityId;

  const _PostCard({
    required this.post,
    required this.currentUid,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasAmened = currentUid != null && post.amenUids.contains(currentUid);
    final isOwner = currentUid != null && post.uid == currentUid;
    final timeAgo = _timeAgo(post.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.backgroundLevel1,
        borderRadius: BorderRadius.circular(16),
        border: post.isFeatured
            ? Border.all(
                color: colorScheme.primary.withValues(alpha: 0.6), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 작성자 + 시간 + 메뉴
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                child: Text(
                  post.displayName.isNotEmpty ? post.displayName[0] : '?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (post.isFeatured) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star, size: 14, color: colorScheme.goldColor),
                        ],
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  onPressed: () => ref
                      .read(firestoreServiceProvider)
                      .toggleFeatured(post.id, post.isFeatured, communityId),
                  icon: Icon(
                    post.isFeatured ? Icons.star : Icons.star_border,
                    color: post.isFeatured
                        ? colorScheme.goldColor
                        : colorScheme.textSecondary,
                    size: 20,
                  ),
                  tooltip: post.isFeatured ? '오늘의 QT 카드 해제' : '오늘의 QT 카드로 설정',
                  visualDensity: VisualDensity.compact,
                ),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: colorScheme.textSecondary, size: 20),
                  onSelected: (v) {
                    if (v == 'edit') _showEditDialog(context, ref, colorScheme);
                    if (v == 'delete') _confirmDelete(context, ref);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (post.scriptureTitle.isNotEmpty) ...[
            Text(
              '📖  ${post.scriptureTitle}',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
          ],

          if (post.scriptureVerse.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: colorScheme.primary, width: 2.5),
                ),
              ),
              child: Text(
                post.scriptureVerse,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 10),

          Text(
            '🙏  ${post.prayer}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              GestureDetector(
                onTap: currentUid != null
                    ? () => ref
                        .read(firestoreServiceProvider)
                        .toggleAmen(post.id, currentUid!)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: hasAmened
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.backgroundLevel2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasAmened
                          ? colorScheme.primary
                          : colorScheme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🙏',
                        style: TextStyle(
                          fontSize: 14,
                          color: hasAmened ? null : colorScheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '아멘 ${post.amenCount > 0 ? post.amenCount : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasAmened
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: hasAmened
                              ? colorScheme.primary
                              : colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) async {
    final titleCtrl = TextEditingController(text: post.scriptureTitle);
    final verseCtrl = TextEditingController(text: post.scriptureVerse);
    final prayerCtrl = TextEditingController(text: post.prayer);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('나눔 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '말씀 제목'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: verseCtrl,
                  decoration: const InputDecoration(labelText: '핵심 구절'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: prayerCtrl,
                  decoration: const InputDecoration(labelText: '기도'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      await ref.read(firestoreServiceProvider).updatePost(
                            post.id,
                            scriptureTitle: titleCtrl.text.trim(),
                            scriptureVerse: verseCtrl.text.trim(),
                            prayer: prayerCtrl.text.trim(),
                            meditation: post.meditation,
                          );
                      titleCtrl.dispose();
                      verseCtrl.dispose();
                      prayerCtrl.dispose();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('나눔 삭제'),
        content: const Text('이 나눔을 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(firestoreServiceProvider).deletePost(post.id);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return DateFormat('M월 d일').format(dt);
  }
}

// ── 나눔 작성 바텀시트 ─────────────────────────────────────────────────────
class _WriteSheet extends StatefulWidget {
  final String communityId;
  final String uid;
  final String displayName;
  final Future<void> Function(String text) onSubmit;

  const _WriteSheet({
    required this.communityId,
    required this.uid,
    required this.displayName,
    required this.onSubmit,
  });

  @override
  State<_WriteSheet> createState() => _WriteSheetState();
}

class _WriteSheetState extends State<_WriteSheet> {
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    Navigator.pop(context);
    await widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🤝 나눔 작성',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: '말씀 묵상, 기도, 은혜 받은 것을 자유롭게 나눠보세요 🙏',
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: const Text('나눔 등록'),
            ),
          ),
        ],
      ),
    );
  }
}
