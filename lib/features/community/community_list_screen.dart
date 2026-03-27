import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/community_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/models/community_group.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants.dart';
import 'community_screen.dart';
import 'community_auth_gate.dart';

class CommunityListScreen extends ConsumerWidget {
  const CommunityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnonymous = ref.watch(isAnonymousProvider);
    if (isAnonymous) return const _AnonymousCommunityPlaceholder();

    final communitiesAsync = ref.watch(myCommunitiesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('공동체')),
      body: communitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (communities) {
          if (communities.isEmpty) {
            return _EmptyState(colorScheme: colorScheme);
          }

          final currentUid = ref.read(currentUserProvider)?.uid;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: communities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CommunityCard(
              group: communities[i],
              currentUid: currentUid,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommunityFeedScreen(
                    communityId: communities[i].id,
                    communityName: communities[i].name,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionSheet(context, ref),
        icon: const Icon(Icons.group_add),
        label: const Text('공동체'),
      ),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref) {
    if (ref.read(isAnonymousProvider)) {
      showCommunityAuthGate(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.add),
                ),
                title: const Text('공동체 만들기'),
                subtitle: const Text('새 공동체를 개설하고 초대하세요'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.communityCreate);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.login),
                ),
                title: const Text('공동체 참여하기'),
                subtitle: const Text('공동체 ID와 비밀번호로 입장하세요'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.communityJoin);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤝', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text(
              '아직 참여한 공동체가 없어요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '공동체를 만들거나 초대받은 공동체에 참여해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.communityCreate),
                icon: const Icon(Icons.add),
                label: const Text('공동체 만들기'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.communityJoin),
                icon: const Icon(Icons.login),
                label: const Text('공동체 참여하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnonymousCommunityPlaceholder extends StatelessWidget {
  const _AnonymousCommunityPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('공동체')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('🤝', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 24),
              const Text(
                '공동체에서 함께 성장해요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '계정을 만들면 공동체에 참여하고\n서로의 묵상을 나눌 수 있어요.\n지금까지의 QT 기록은 그대로 유지돼요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.textSecondary,
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.signup),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('계정 만들기', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('이미 계정이 있어요', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends ConsumerWidget {
  final CommunityGroup group;
  final String? currentUid;
  final VoidCallback onTap;

  const _CommunityCard({
    required this.group,
    required this.currentUid,
    required this.onTap,
  });

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditNameDialog(initialName: group.name),
    );
    if (newName != null && newName.isNotEmpty && newName != group.name) {
      await ref.read(firestoreServiceProvider).updateCommunityName(group.id, newName);
      ref.invalidate(myCommunitiesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCreator = currentUid != null && currentUid == group.creatorUid;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.backgroundLevel1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  group.name.isNotEmpty ? group.name[0] : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 14, color: colorScheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '멤버 ${group.memberCount}명',
                        style: TextStyle(
                          color: colorScheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ID: ${group.id}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCreator)
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 20, color: colorScheme.textSecondary),
                tooltip: '그룹명 수정',
                onPressed: () => _editName(context, ref),
              )
            else
              Icon(Icons.chevron_right, color: colorScheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  final String initialName;
  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('그룹명 수정'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: '새 그룹명 입력'),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('저장'),
        ),
      ],
    );
  }
}
