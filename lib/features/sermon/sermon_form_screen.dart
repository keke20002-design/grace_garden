import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/sermon_provider.dart';
import '../../app/theme/app_colors.dart';

// 설교자 프리셋 목록 — 교회 상황에 맞게 수정하세요
const _presetPastors = ['담임목사', '부목사', '전도사', '협동목사', '객원 강사'];

class SermonFormScreen extends ConsumerStatefulWidget {
  const SermonFormScreen({super.key});

  @override
  ConsumerState<SermonFormScreen> createState() => _SermonFormScreenState();
}

class _SermonFormScreenState extends ConsumerState<SermonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _pastorCtrl = TextEditingController();
  final _scriptureCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _fullContentCtrl = TextEditingController();
  bool _isSaving = false;

  // 설교자 입력 모드: true = 프리셋 선택, false = 직접 입력
  bool _usePreset = true;
  String _selectedPreset = _presetPastors.first;

  String get _effectivePastor =>
      _usePreset ? _selectedPreset : _pastorCtrl.text.trim();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pastorCtrl.dispose();
    _scriptureCtrl.dispose();
    _summaryCtrl.dispose();
    _fullContentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(sermonServiceProvider).saveSermon(
        title: _titleCtrl.text.trim(),
        pastor: _effectivePastor,
        scriptureRef: _scriptureCtrl.text.trim(),
        summary: _summaryCtrl.text.trim(),
        fullContent: _fullContentCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설교가 등록되었어요! (+5 달란트) ✨')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('주일설교 등록'),
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
                    '저장',
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            _field(
              ctrl: _titleCtrl,
              label: '설교 제목',
              hint: '예) 하나님의 은혜',
              validator: (v) => v!.isEmpty ? '설교 제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 14),

            // ── 설교자 입력 (선택 / 직접입력 토글) ──
            _PastorField(
              usePreset: _usePreset,
              selectedPreset: _selectedPreset,
              ctrl: _pastorCtrl,
              colorScheme: colorScheme,
              onToggle: (val) => setState(() {
                _usePreset = val;
                if (!val) _pastorCtrl.clear();
              }),
              onPresetChanged: (val) => setState(() => _selectedPreset = val),
            ),
            const SizedBox(height: 14),

            _field(
              ctrl: _scriptureCtrl,
              label: '본문 말씀',
              hint: '예) 로마서 8:28',
              validator: (v) => v!.isEmpty ? '본문 말씀을 입력해주세요' : null,
            ),
            const SizedBox(height: 14),
            _field(
              ctrl: _summaryCtrl,
              label: '설교 요약',
              hint: '핵심 메시지를 2~3문장으로 요약해주세요',
              maxLines: 4,
              validator: (v) => v!.isEmpty ? '설교 요약을 입력해주세요' : null,
            ),
            const SizedBox(height: 14),
            _field(
              ctrl: _fullContentCtrl,
              label: '전체 내용 (선택)',
              hint: '설교 전문이나 노트를 자유롭게 적어보세요',
              maxLines: 8,
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
                  : const Text('설교 등록하기 ✝️'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
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

class _PastorField extends StatelessWidget {
  final bool usePreset;
  final String selectedPreset;
  final TextEditingController ctrl;
  final ColorScheme colorScheme;
  final void Function(bool) onToggle;
  final void Function(String) onPresetChanged;

  const _PastorField({
    required this.usePreset,
    required this.selectedPreset,
    required this.ctrl,
    required this.colorScheme,
    required this.onToggle,
    required this.onPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '설교자',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.textSecondary,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '직접 입력',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.textSecondary,
                  ),
                ),
                Checkbox(
                  value: !usePreset,
                  visualDensity: VisualDensity.compact,
                  onChanged: (val) => onToggle(!(val ?? false)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (usePreset)
          DropdownButtonFormField<String>(
            initialValue: selectedPreset,
            decoration: InputDecoration(
              hintText: '설교자를 선택하세요',
              hintStyle: TextStyle(
                color: colorScheme.textSecondary,
                fontSize: 13,
              ),
            ),
            items: _presetPastors
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (val) {
              if (val != null) onPresetChanged(val);
            },
          )
        else
          TextFormField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: '예) 홍길동 목사',
              hintStyle: TextStyle(
                color: colorScheme.textSecondary,
                fontSize: 13,
              ),
            ),
            validator: (v) => v!.isEmpty ? '설교자를 입력해주세요' : null,
          ),
      ],
    );
  }
}
