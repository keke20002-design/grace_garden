import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/community_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../app/theme/app_colors.dart';
import 'community_screen.dart';

class JoinCommunityScreen extends ConsumerStatefulWidget {
  const JoinCommunityScreen({super.key});

  @override
  ConsumerState<JoinCommunityScreen> createState() =>
      _JoinCommunityScreenState();
}

class _JoinCommunityScreenState extends ConsumerState<JoinCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _joining = false;
  String? _errorMsg;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _joining = true;
      _errorMsg = null;
    });
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final group = await ref.read(firestoreServiceProvider).joinCommunity(
            uid: user.uid,
            communityId: _idCtrl.text.trim().toUpperCase(),
            password: _pwCtrl.text.trim(),
          );

      if (!mounted) return;

      if (group == null) {
        setState(() => _errorMsg = '공동체 ID 또는 비밀번호가 올바르지 않아요.');
        return;
      }

      context.pop(); // join 화면 닫기
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityFeedScreen(
            communityId: group.id,
            communityName: group.name,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('공동체 참여하기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🔑', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '공동체에 참여해보세요!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '공동체 관리자에게 ID와 비밀번호를 받아 입력하세요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _idCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: '공동체 ID *',
                hintText: '예) A1B2C3D4',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? '공동체 ID를 입력해주세요' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pwCtrl,
              obscureText: _obscurePw,
              decoration: InputDecoration(
                labelText: '비밀번호 *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePw ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? '비밀번호를 입력해주세요' : null,
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _joining ? null : _join,
              child: _joining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('참여하기'),
            ),
          ],
        ),
      ),
    );
  }
}
