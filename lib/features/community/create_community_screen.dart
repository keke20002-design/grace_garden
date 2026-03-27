import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/community_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/hive_provider.dart';
import '../../app/theme/app_colors.dart';
import 'community_screen.dart';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

// 생성 순서별 달란트 비용: 1번째=100, 2번째=1500, 인당 최대 2개
const _communityCosts = [100, 1500];
const _maxCommunitiesPerUser = 2;

int _getCommunityCreationCost(int createdCount) =>
    _communityCosts[createdCount.clamp(0, 1)];

class _CreateCommunityScreenState
    extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _create(int cost) async {
    if (!_formKey.currentState!.validate()) return;

    // 달란트 확인
    final profile = ref.read(userProfileProvider);
    if (profile.totalTalents < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('달란트가 부족해요. 필요: $cost ⭐, 보유: ${profile.totalTalents} ⭐')),
      );
      return;
    }

    // 재확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('공동체 만들기'),
        content: Text('$cost 달란트를 사용해서 공동체를 만들까요?\n\n보유: ${profile.totalTalents} ⭐'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('만들기')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // 달란트 차감
      final box = ref.read(profileBoxProvider);
      final p = box.get('me');
      if (p != null) {
        p.totalTalents -= cost;
        await p.save();
        ref.invalidate(userProfileProvider);
      }

      final communityId = await ref.read(firestoreServiceProvider).createCommunity(
            uid: user.uid,
            name: _nameCtrl.text.trim(),
            password: _pwCtrl.text.trim(),
          );

      if (mounted) {
        context.pop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityFeedScreen(
              communityId: communityId,
              communityName: _nameCtrl.text.trim(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final communities = ref.watch(myCommunitiesProvider).valueOrNull ?? [];
    final user = ref.watch(currentUserProvider);
    final createdCount = communities.where((c) => c.creatorUid == user?.uid).length;
    final reachedMax = createdCount >= _maxCommunitiesPerUser;
    final cost = _getCommunityCreationCost(createdCount);
    final canAfford = profile.totalTalents >= cost;

    return Scaffold(
      appBar: AppBar(title: const Text('공동체 만들기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 달란트 비용 배너
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: reachedMax
                    ? colorScheme.error.withValues(alpha: 0.08)
                    : canAfford
                        ? colorScheme.primary.withValues(alpha: 0.08)
                        : colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: reachedMax
                      ? colorScheme.error.withValues(alpha: 0.3)
                      : canAfford
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reachedMax
                              ? '공동체 최대 개수에 도달했어요'
                              : canAfford
                                  ? '공동체를 만들어보세요!'
                                  : '달란트가 부족해요',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (reachedMax)
                          Text(
                            '1인당 최대 $_maxCommunitiesPerUser개까지 만들 수 있어요',
                            style: TextStyle(fontSize: 12, color: colorScheme.error, height: 1.4),
                          )
                        else ...[
                          Text(
                            '생성 비용: $cost ⭐  ·  보유: ${profile.totalTalents} ⭐',
                            style: TextStyle(
                              fontSize: 12,
                              color: canAfford ? colorScheme.primary : colorScheme.error,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            createdCount == 0
                                ? '첫 번째 공동체 · 100 달란트'
                                : '두 번째(마지막) 공동체 · 1,500 달란트',
                            style: TextStyle(fontSize: 11, color: colorScheme.textSecondary, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '공동체 이름 *',
                hintText: '예) 은혜교회 청년부',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              validator: (v) => v!.trim().isEmpty ? '공동체 이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pwCtrl,
              obscureText: _obscurePw,
              decoration: InputDecoration(
                labelText: '비밀번호 *',
                hintText: '멤버 초대 시 사용할 비밀번호',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePw ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              validator: (v) {
                if (v!.trim().isEmpty) return '비밀번호를 입력해주세요';
                if (v.trim().length < 4) return '비밀번호는 4자 이상이어야 해요';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pwConfirmCtrl,
              obscureText: _obscurePw,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인 *',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  v != _pwCtrl.text ? '비밀번호가 일치하지 않아요' : null,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: (_saving || !canAfford || reachedMax) ? null : () => _create(cost),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('공동체 만들기  ($cost ⭐)'),
            ),
          ],
        ),
      ),
    );
  }
}
