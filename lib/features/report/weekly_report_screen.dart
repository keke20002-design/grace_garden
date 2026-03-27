import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/providers/qt_provider.dart';
import '../../shared/providers/sermon_provider.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/models/user_profile.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants.dart';
import '../../shared/widgets/banner_ad_widget.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qtList = ref.watch(qtListProvider);
    final sermonList = ref.watch(sermonListProvider);
    final profile = ref.watch(userProfileProvider);
    final cs = Theme.of(context).colorScheme;

    final weekStart = _weekStart;
    final weekEnd = _weekEnd;

    final weekQts = qtList
        .where((e) =>
            !e.date.isBefore(weekStart) && !e.date.isAfter(weekEnd))
        .toList();

    final weekSermons = sermonList
        .where((e) =>
            !e.date.isBefore(weekStart) && !e.date.isAfter(weekEnd))
        .toList();

    // 일월화수목금토 순서: 일(0), 월(1)...토(6)
    // Dart weekday: 1=월~7=일 → 일요일은 7이므로 0으로 매핑
    final qtDaySet =
        weekQts.map((e) => e.date.weekday % 7).toSet(); // 0=일,6=토

    final weekTalents = weekQts.fold<int>(0, (s, e) => s + e.talentsEarned) +
        weekSermons.fold<int>(0, (s, e) => s + e.talentsEarned);

    final dateLabel =
        '${weekStart.month}월${weekStart.day}일 ~ ${weekEnd.month}월${weekEnd.day}일';

    return Scaffold(
      appBar: AppBar(
        title: const Text('이번 주 신앙 리포트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '공유',
            onPressed: () =>
                _share(profile, weekQts.length, weekTalents, weekSermons),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 날짜 헤더
          Center(
            child: Text(
              '📅 $dateLabel',
              style: TextStyle(
                color: cs.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 카드1: QT 성실도
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(icon: Icons.menu_book, title: 'QT 성실도'),
                const SizedBox(height: 14),
                _WeekGrid(qtDaySet: qtDaySet, cs: cs),
                const SizedBox(height: 12),
                Text(
                  '이번 주 ${weekQts.length}회 묵상  ·  $weekTalents 달란트 획득',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 카드2: 나무 성장
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(icon: Icons.park_outlined, title: '나무 성장'),
                const SizedBox(height: 14),
                _TreeGrowthCard(profile: profile, cs: cs),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 카드3: 이번 주 설교
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(icon: Icons.church_outlined, title: '이번 주 설교'),
                const SizedBox(height: 14),
                if (weekSermons.isEmpty)
                  _EmptyStateInCard(
                    message: '이번 주 설교 기록이 없어요 ✝️',
                    buttonLabel: '설교 등록하기',
                    onTap: () => context.push(AppRoutes.sermonNew),
                  )
                else
                  ...weekSermons.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (s.pastor.isNotEmpty)
                              Text(
                                s.pastor,
                                style: TextStyle(
                                    color: cs.textSecondary, fontSize: 13),
                              ),
                            if (s.scriptureRef.isNotEmpty)
                              Text(
                                s.scriptureRef,
                                style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 카드4: 기도 제목
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(icon: Icons.volunteer_activism_outlined, title: '기도 제목'),
                const SizedBox(height: 14),
                if (weekQts.isEmpty ||
                    weekQts.every((e) => e.prayer.trim().isEmpty))
                  _EmptyStateInCard(
                    message: '이번 주 기도 제목이 없어요 🙏',
                    buttonLabel: 'QT 작성하기',
                    onTap: () => context.push(AppRoutes.qtForm),
                  )
                else
                  ...weekQts
                      .where((e) => e.prayer.trim().isNotEmpty)
                      .take(3)
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🙏 ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${e.date.month}/${e.date.day}',
                                        style: TextStyle(
                                          color: cs.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        e.prayer,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 공유 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _share(profile, weekQts.length, weekTalents, weekSermons),
              icon: const Icon(Icons.share_outlined),
              label: const Text('리포트 공유하기'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      )),
          const HomeBannerAd(),
        ],
      ),
    );
  }

  void _share(
    UserProfile profile,
    int qtCount,
    int talents,
    List sermons,
  ) {
    final weekStart = _weekStart;
    final weekEnd = _weekEnd;
    final sermonTitle = sermons.isEmpty ? '-' : sermons.first.title as String;

    Share.share(
      '📊 이번 주 신앙 리포트 (${weekStart.month}월${weekStart.day}일~${weekEnd.month}월${weekEnd.day}일)\n\n'
      '✅ QT: $qtCount회 완료\n'
      '⭐ 달란트: $talents개 획득\n'
      '🌱 나무: ${profile.treeStageName} 단계\n'
      '✝️ 설교: $sermonTitle\n\n'
      '- 은혜 기록장에서 기록 중 🌿',
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.backgroundLevel1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _WeekGrid extends StatelessWidget {
  final Set<int> qtDaySet;
  final ColorScheme cs;
  const _WeekGrid({required this.qtDaySet, required this.cs});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    final today = DateTime.now().weekday % 7; // 0=일,6=토

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final hasDone = qtDaySet.contains(i);
        final isToday = i == today;
        return Column(
          children: [
            Text(
              dayLabels[i],
              style: TextStyle(
                fontSize: 11,
                color: isToday ? cs.primary : cs.textSecondary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasDone
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.08),
                border: isToday && !hasDone
                    ? Border.all(color: cs.primary, width: 1.5)
                    : null,
              ),
              child: hasDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        );
      }),
    );
  }
}

class _TreeGrowthCard extends StatelessWidget {
  final UserProfile profile;
  final ColorScheme cs;
  const _TreeGrowthCard({required this.profile, required this.cs});

  @override
  Widget build(BuildContext context) {
    const stageEmojis = ['🫘', '🌱', '🌿', '🌳', '🍎'];
    final emoji = stageEmojis[profile.treeStage.clamp(0, 4)];

    double progress = 0;
    String progressLabel = '';

    if (profile.treeStage >= 4) {
      progress = 1.0;
      progressLabel = '최고 단계 달성! 🎉';
    } else {
      final threshold = UserProfile.stageThresholds[profile.treeStage];
      final prevThreshold =
          profile.treeStage > 0 ? UserProfile.stageThresholds[profile.treeStage - 1] : 0;
      final current = profile.totalQtCount.clamp(prevThreshold, threshold);
      progress = (current - prevThreshold) / (threshold - prevThreshold);
      progressLabel =
          '다음 단계까지 ${threshold - profile.totalQtCount.clamp(0, threshold)}회';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.treeStageName} 단계',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '총 QT ${profile.totalQtCount}회  ·  ${profile.totalTalents} 달란트',
                    style:
                        TextStyle(fontSize: 12, color: cs.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: cs.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          progressLabel,
          style: TextStyle(fontSize: 12, color: cs.textSecondary),
        ),
      ],
    );
  }
}

class _EmptyStateInCard extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onTap;

  const _EmptyStateInCard({
    required this.message,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          message,
          style: TextStyle(color: cs.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onTap,
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
