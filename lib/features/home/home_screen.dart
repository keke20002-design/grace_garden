import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/qt_provider.dart';
import '../../shared/providers/sermon_provider.dart';
import '../../shared/providers/community_provider.dart';
import '../../shared/models/qt_entry.dart';
import '../../shared/models/sermon_entry.dart';
import '../../shared/models/community_post.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants.dart';
import '../tree/tree_widget.dart';
import '../../shared/widgets/banner_ad_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final todayList = ref.watch(todayQtListProvider);
    final latestSermon = ref.watch(latestSermonProvider);
    final featuredPost = ref.watch(featuredPostProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.qtForm),
        icon: const Icon(Icons.edit_note),
        label: const Text('묵상 추가'),
      ),
      body: Column(
        children: [
          Expanded(child: CustomScrollView(
        slivers: [
          // 상단 앱바
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 58,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: colorScheme.goldColor),
                      const SizedBox(width: 4),
                      Text(
                        '${profile.totalTalents}',
                        style: TextStyle(
                          color: colorScheme.goldColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 날짜
                Text(
                  DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(today),
                  style: TextStyle(
                    color: colorScheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // ─── 나무 카드 (컴팩트) ───────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.backgroundLevel1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      TreeWidget(stage: profile.treeStage, size: 72),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.treeStageName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.treeStage < 4
                                  ? '${profile.qtCountForNextStage - profile.totalQtCount}번 더 묵상하면 성장해요!'
                                  : '최고 단계에 도달했어요! 🎉',
                              style: TextStyle(
                                color: colorScheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (profile.qtStreak > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${profile.qtStreak}일 연속',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── 별표 게시물 (오늘의 QT 카드) ────────────────────
                if (featuredPost != null) ...[
                  _FeaturedQtCard(post: featuredPost),
                  const SizedBox(height: 14),
                ],

                // ─── 오늘의 묵상 섹션 ─────────────────────────────────
                _TodayQtSection(
                  entries: todayList,
                  onNewTap: () => context.push(AppRoutes.qtForm),
                  onCardTap: (e) => context.push(AppRoutes.prayerCard, extra: e),
                ),
                const SizedBox(height: 14),

                // ─── 주일설교 요약 카드 ───────────────────────────────
                _SermonPreviewCard(
                  sermon: latestSermon,
                  onTap: latestSermon != null
                      ? () => context.push(
                            AppRoutes.sermonDetail,
                            extra: latestSermon,
                          )
                      : null,
                  onRegisterTap: () => context.push(AppRoutes.sermonNew),
                ),
              ]),
            ),
          ),
        ],
      )),
      const HomeBannerAd(),
    ],
    ),
    );
  }
}

// ─── 별표 공동체 게시물 → 오늘의 QT 카드 ──────────────────────────────────
class _FeaturedQtCard extends StatelessWidget {
  final CommunityPost post;
  const _FeaturedQtCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, size: 15, color: cs.goldColor),
              const SizedBox(width: 6),
              Text(
                '오늘의 QT 카드',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                post.displayName,
                style: TextStyle(color: cs.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '📖  ${post.scriptureTitle}',
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (post.scriptureVerse.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              post.scriptureVerse,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.75),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '🙏  ${post.prayer}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 오늘의 묵상 섹션 ──────────────────────────────────────────────────────
class _TodayQtSection extends StatelessWidget {
  final List<QtEntry> entries;
  final VoidCallback onNewTap;
  final void Function(QtEntry) onCardTap;

  const _TodayQtSection({
    required this.entries,
    required this.onNewTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return GestureDetector(
        onTap: onNewTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘의 묵상을 시작해볼까요?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '말씀을 묵상하고 달란트 10개를 받으세요 ✨',
                      style: TextStyle(color: cs.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: cs.primary),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.backgroundLevel1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                '오늘 ${entries.length}건 묵상 완료',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '+${entries.length * 10} 달란트',
                style: TextStyle(color: cs.goldColor, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (e) => _QtEntryRow(entry: e, onCardTap: () => onCardTap(e)),
          ),
        ],
      ),
    );
  }
}

class _QtEntryRow extends StatelessWidget {
  final QtEntry entry;
  final VoidCallback onCardTap;
  const _QtEntryRow({required this.entry, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.scriptureTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                if (entry.scriptureVerse.isNotEmpty)
                  Text(
                    entry.scriptureVerse,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCardTap,
            icon: Icon(Icons.card_giftcard, size: 18, color: cs.primary),
            tooltip: '기도 카드',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ─── 주일설교 요약 카드 ────────────────────────────────────────────────────
class _SermonPreviewCard extends StatelessWidget {
  final SermonEntry? sermon;
  final VoidCallback? onTap;
  final VoidCallback onRegisterTap;

  const _SermonPreviewCard({
    required this.sermon,
    required this.onTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (sermon == null) {
      return GestureDetector(
        onTap: onRegisterTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.backgroundLevel1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('✝️', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '주일설교 등록',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '이번 주 설교를 기록해보세요 (+5 달란트)',
                      style: TextStyle(color: cs.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add, color: cs.primary),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.backgroundLevel1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✝️', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '주일설교',
                    style: TextStyle(
                      color: cs.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              sermon!.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '${sermon!.pastor}  |  ${sermon!.scriptureRef}',
              style: TextStyle(color: cs.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              sermon!.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onRegisterTap,
                child: Text(
                  '+ 새 설교 등록',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
