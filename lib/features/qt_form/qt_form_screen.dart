import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/qt_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/models/qt_entry.dart';
import '../../shared/models/community_post.dart';
import '../../shared/widgets/community_share_helper.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants.dart';

class QtFormScreen extends ConsumerStatefulWidget {
  final QtEntry? editEntry; // null이면 새 작성, not null이면 편집 모드
  final DateTime? initialDate; // 달력에서 날짜 선택 시 전달
  const QtFormScreen({super.key, this.editEntry, this.initialDate});

  @override
  ConsumerState<QtFormScreen> createState() => _QtFormScreenState();
}

class _QtFormScreenState extends ConsumerState<QtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _verseCtrl;
  late final TextEditingController _meditationCtrl;
  late final TextEditingController _applicationCtrl;
  late final TextEditingController _prayerCtrl;
  bool _isSaving = false;

  bool get _isEditMode => widget.editEntry != null;

  static const _sectionGuides = {
    'meditation': '말씀 속에서 하나님이 나에게 주시는 메시지는 무엇인가요?',
    'application': '오늘 이 말씀을 어떻게 삶에 적용할 수 있을까요?',
    'prayer': '이 말씀을 붙들고 하나님께 드리는 기도를 적어주세요.',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.editEntry;
    _titleCtrl = TextEditingController(text: e?.scriptureTitle ?? '');
    _verseCtrl = TextEditingController(text: e?.scriptureVerse ?? '');
    _meditationCtrl = TextEditingController(text: e?.meditation ?? '');
    _applicationCtrl = TextEditingController(text: e?.application ?? '');
    _prayerCtrl = TextEditingController(text: e?.prayer ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _verseCtrl.dispose();
    _meditationCtrl.dispose();
    _applicationCtrl.dispose();
    _prayerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        await ref.read(qtServiceProvider).updateEntry(
          id: widget.editEntry!.id,
          scriptureTitle: _titleCtrl.text.trim(),
          scriptureVerse: _verseCtrl.text.trim(),
          meditation: _meditationCtrl.text.trim(),
          application: _applicationCtrl.text.trim(),
          prayer: _prayerCtrl.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('묵상이 수정되었어요 ✏️')),
          );
          context.pop();
        }
      } else {
        final savedEntry = await ref.read(qtServiceProvider).saveQtEntry(
          scriptureTitle: _titleCtrl.text.trim(),
          scriptureVerse: _verseCtrl.text.trim(),
          meditation: _meditationCtrl.text.trim(),
          application: _applicationCtrl.text.trim(),
          prayer: _prayerCtrl.text.trim(),
          date: widget.initialDate,
        );
        if (mounted) _showCompletionDialog(savedEntry);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareToCommuntiy(QtEntry entry) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await shareToCommunity(
      context: context,
      ref: ref,
      buildPost: (communityId) => CommunityPost(
        id: '',
        communityId: communityId,
        uid: user.uid,
        displayName: user.displayName ?? '사용자',
        scriptureTitle: entry.scriptureTitle,
        scriptureVerse: entry.scriptureVerse,
        prayer: entry.prayer,
        meditation: entry.meditation,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _showCompletionDialog(QtEntry savedEntry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              '묵상 완료!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '달란트 10개를 받았어요 ✨\n나무가 조금 더 자랐어요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.textSecondary,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
            child: const Text('홈으로'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _shareToCommuntiy(savedEntry);
              if (mounted) context.go(AppRoutes.community);
            },
            child: const Text('🤝 나눔'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.prayerCard, extra: savedEntry);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('기도 카드 만들기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode
            ? '묵상 수정'
            : widget.initialDate != null
                ? '${widget.initialDate!.month}월 ${widget.initialDate!.day}일 묵상'
                : '오늘의 묵상'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEditMode ? '수정' : '저장',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _SectionCard(
              icon: '📖',
              title: '오늘의 말씀',
              color: colorScheme.primary,
              children: [
                _StyledField(
                  controller: _titleCtrl,
                  label: '말씀 제목',
                  hint: '예) 여호와는 나의 목자시니...',
                  validator: (v) => v!.isEmpty ? '말씀 제목을 입력해주세요' : null,
                ),
                const SizedBox(height: 12),
                _StyledField(
                  controller: _verseCtrl,
                  label: '핵심 구절',
                  hint: '예) 시편 23:1',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SectionCard(
              icon: '💭',
              title: '묵상 (Meditation)',
              subtitle: _sectionGuides['meditation'],
              color: const Color(0xFF9B59B6),
              children: [
                _StyledField(
                  controller: _meditationCtrl,
                  label: '묵상 내용',
                  hint: '하나님께서 이 말씀을 통해 내게 주시는 메시지를 자유롭게 적어보세요',
                  maxLines: 5,
                  validator: (v) => v!.isEmpty ? '묵상 내용을 입력해주세요' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SectionCard(
              icon: '🌱',
              title: '적용 (Application)',
              subtitle: _sectionGuides['application'],
              color: colorScheme.treeGreen,
              children: [
                _StyledField(
                  controller: _applicationCtrl,
                  label: '삶의 적용',
                  hint: '오늘 구체적으로 어떻게 실천할지 적어보세요',
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? '적용 내용을 입력해주세요' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SectionCard(
              icon: '🙏',
              title: '기도 (Prayer)',
              subtitle: _sectionGuides['prayer'],
              color: const Color(0xFFE67E22),
              children: [
                _StyledField(
                  controller: _prayerCtrl,
                  label: '오늘의 기도',
                  hint: '말씀을 붙들고 드리는 기도를 적어주세요',
                  maxLines: 5,
                  validator: (v) => v!.isEmpty ? '기도 내용을 입력해주세요' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditMode ? '수정 완료' : '묵상 완료하기 🌱'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.backgroundLevel1,
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
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.textSecondary,
          fontSize: 13,
        ),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
