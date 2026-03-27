import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/hive_provider.dart';
import '../../shared/models/user_profile.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/providers/notification_provider.dart';
import '../../shared/widgets/banner_ad_widget.dart';
import '../../core/constants.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isDark = ref.watch(themeModeProvider);
    final isAnonymous = ref.watch(isAnonymousProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        actions: [
          if (!isAnonymous)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '로그아웃',
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 프로필 카드
          if (isAnonymous)
            _AnonymousProfileCard(profile: profile)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.backgroundLevel1,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      profile.displayName.isNotEmpty ? profile.displayName[0] : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${profile.treeStageName} 단계',
                        style: TextStyle(color: colorScheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // 통계
          Row(
            children: [
              _StatCard(
                label: '달란트',
                value: '${profile.totalTalents}',
                icon: Icons.star,
                color: colorScheme.goldColor,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: '연속 QT',
                value: '${profile.qtStreak}일',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: '총 QT',
                value: '${profile.totalQtCount}회',
                icon: Icons.menu_book,
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 익명 사용자: 계정 만들기 배너
          if (isAnonymous) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '계정을 만들면 더 많은 기능을 쓸 수 있어요',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '공동체 참여, 기기 간 동기화, 데이터 백업',
                    style: TextStyle(color: colorScheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push(AppRoutes.signup),
                      child: const Text('계정 만들기'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.push(AppRoutes.login),
                child: const Text('이미 계정이 있어요 (로그인)'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 주간 신앙 리포트 배너
          InkWell(
            onTap: () => context.push(AppRoutes.weeklyReport),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이번 주 신앙 리포트',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '이번 주 QT · 설교 · 성장 요약',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 다크모드 설정
          Container(
            decoration: BoxDecoration(
              color: colorScheme.backgroundLevel1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('다크 모드'),
              subtitle: const Text('눈의 편안함을 위해 권장됩니다'),
              value: isDark,
              onChanged: (val) => ref.read(themeModeProvider.notifier).state = val,
              activeThumbColor: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // 알림 설정
          Container(
            decoration: BoxDecoration(
              color: colorScheme.backgroundLevel1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _AlarmTile(
                  title: 'QT 알림',
                  subtitle: '매일',
                  alarmState: ref.watch(qtAlarmProvider),
                  onToggle: (val) =>
                      ref.read(qtAlarmProvider.notifier).toggle(val),
                  onTimePick: () async {
                    final cur = ref.read(qtAlarmProvider);
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: cur.timeOfDay,
                      helpText: 'QT 알림 시간 선택',
                    );
                    if (picked != null) {
                      ref.read(qtAlarmProvider.notifier)
                          .updateTime(picked.hour, picked.minute);
                    }
                  },
                ),
                Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outlineVariant),
                _AlarmTile(
                  title: '설교 기록 알림',
                  subtitle: '매주 일요일',
                  alarmState: ref.watch(sermonAlarmProvider),
                  onToggle: (val) =>
                      ref.read(sermonAlarmProvider.notifier).toggle(val),
                  onTimePick: () async {
                    final cur = ref.read(sermonAlarmProvider);
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: cur.timeOfDay,
                      helpText: '설교 알림 시간 선택',
                    );
                    if (picked != null) {
                      ref.read(sermonAlarmProvider.notifier)
                          .updateTime(picked.hour, picked.minute);
                    }
                  },
                ),
              ],
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

class _AnonymousProfileCard extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _AnonymousProfileCard({required this.profile});

  @override
  ConsumerState<_AnonymousProfileCard> createState() =>
      _AnonymousProfileCardState();
}

class _AnonymousProfileCardState extends ConsumerState<_AnonymousProfileCard> {
  late final TextEditingController _nameCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final box = ref.read(profileBoxProvider);
    final profile = box.get('me') ?? widget.profile;
    profile.displayName = name;
    await box.put('me', profile);
    ref.invalidate(userProfileProvider);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.backgroundLevel1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: cs.primary.withValues(alpha: 0.2),
            child: Text(
              widget.profile.displayName.isNotEmpty
                  ? widget.profile.displayName[0]
                  : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _editing
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: '닉네임 입력',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _saveName(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _saveName,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.profile.displayName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '게스트 사용자',
                              style: TextStyle(
                                  color: cs.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: '닉네임 수정',
                        onPressed: () => setState(() => _editing = true),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.backgroundLevel1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: colorScheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final AlarmState alarmState;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimePick;

  const _AlarmTile({
    required this.title,
    required this.subtitle,
    required this.alarmState,
    required this.onToggle,
    required this.onTimePick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title),
      subtitle: GestureDetector(
        onTap: onTimePick,
        child: Row(
          children: [
            Text('$subtitle '),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    alarmState.timeLabel,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      trailing: Switch(
        value: alarmState.enabled,
        onChanged: onToggle,
        activeThumbColor: cs.primary,
      ),
    );
  }
}
