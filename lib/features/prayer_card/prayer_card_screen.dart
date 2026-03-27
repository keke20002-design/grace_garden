import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../shared/models/qt_entry.dart';
import '../../shared/models/community_post.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/profile_provider.dart';
import '../../shared/providers/hive_provider.dart';
import '../../shared/widgets/community_share_helper.dart';
import '../../core/constants.dart';

const _cardShareCost = 5; // 기도카드 공동체 나눔 비용

// ─── 테마 데이터 모델 ─────────────────────────────────────────────────────────
class CardThemeData {
  final String name;
  final String emoji;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color verseColor;
  final Color prayerColor;
  final Color footerColor;

  const CardThemeData({
    required this.name,
    required this.emoji,
    required this.gradientColors,
    required this.accentColor,
    required this.verseColor,
    required this.prayerColor,
    required this.footerColor,
  });
}

// ─── 20종 테마 정의 ───────────────────────────────────────────────────────────
const List<CardThemeData> _themedCards = [
  // ── 계절별 ──────────────────────────────────────────────────────────────
  CardThemeData(name: '봄', emoji: '🌱', gradientColors: [Color(0xFF1A4A2E), Color(0xFF0A2818)], accentColor: Color(0xFF7EC8A0), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFB8DECA), footerColor: Color(0xFF4A8A6A)),
  CardThemeData(name: '여름', emoji: '🌊', gradientColors: [Color(0xFF0A3D62), Color(0xFF0D2040)], accentColor: Color(0xFF74C2E1), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFB0DAED), footerColor: Color(0xFF4AA5C8)),
  CardThemeData(name: '가을', emoji: '🍂', gradientColors: [Color(0xFF5D1A00), Color(0xFF9B4400)], accentColor: Color(0xFFE8A048), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFECC897), footerColor: Color(0xFFB87A3A)),
  CardThemeData(name: '겨울', emoji: '❄️', gradientColors: [Color(0xFF0D1B2A), Color(0xFF1B3A60)], accentColor: Color(0xFFACC8E8), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFCCDDEE), footerColor: Color(0xFF6896C8)),
  // ── 일상 시간대 ────────────────────────────────────────────────────────
  CardThemeData(name: '새벽 기도', emoji: '🌅', gradientColors: [Color(0xFF2D0A02), Color(0xFF8B2E08), Color(0xFFBF6B10)], accentColor: Color(0xFFFFBC42), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFFFDDA0), footerColor: Color(0xFFCDA020)),
  CardThemeData(name: '저녁 묵상', emoji: '🌌', gradientColors: [Color(0xFF020817), Color(0xFF0A1628)], accentColor: Color(0xFF7C83B4), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFB0B8D4), footerColor: Color(0xFF505880)),
  CardThemeData(name: '식사 기도', emoji: '🍞', gradientColors: [Color(0xFF5C300A), Color(0xFF8B4F1A)], accentColor: Color(0xFFE8C068), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFEDD090), footerColor: Color(0xFFBD9048)),
  CardThemeData(name: '일터 기도', emoji: '✨', gradientColors: [Color(0xFF0A2340), Color(0xFF1A3D6E)], accentColor: Color(0xFF60A0E0), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFB0CCEE), footerColor: Color(0xFF4080C0)),
  // ── 고난과 위로 ────────────────────────────────────────────────────────
  CardThemeData(name: '위로', emoji: '🏮', gradientColors: [Color(0xFF0D1B2A), Color(0xFF1B3050)], accentColor: Color(0xFFFFD07A), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFCCDDEE), footerColor: Color(0xFF8898C8)),
  CardThemeData(name: '치유', emoji: '🌿', gradientColors: [Color(0xFF1A3320), Color(0xFF2D5038)], accentColor: Color(0xFF8FCA9A), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFBBDAC0), footerColor: Color(0xFF5A9065)),
  CardThemeData(name: '인내', emoji: '🌵', gradientColors: [Color(0xFF3D2800), Color(0xFF6B4800)], accentColor: Color(0xFFD4A840), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFE8C880), footerColor: Color(0xFFA07830)),
  CardThemeData(name: '회개', emoji: '🌧️', gradientColors: [Color(0xFF1A2030), Color(0xFF2C3A50)], accentColor: Color(0xFF8AAABF), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFB0C4D8), footerColor: Color(0xFF5A7A97)),
  // ── 공동체 및 감사 ─────────────────────────────────────────────────────
  CardThemeData(name: '중보 기도', emoji: '🤲', gradientColors: [Color(0xFF1A0A2E), Color(0xFF2E1050)], accentColor: Color(0xFFB080F0), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFCCAAFF), footerColor: Color(0xFF8060C0)),
  CardThemeData(name: '감사 찬양', emoji: '🌸', gradientColors: [Color(0xFF5C0A3A), Color(0xFF9B1060)], accentColor: Color(0xFFFF8EC0), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFFFBBD8), footerColor: Color(0xFFCC6090)),
  CardThemeData(name: '주일 설교', emoji: '✝️', gradientColors: [Color(0xFF1E0808), Color(0xFF3D1010)], accentColor: Color(0xFFD4907A), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFEDBBAA), footerColor: Color(0xFFA06050)),
  CardThemeData(name: '열매 나눔', emoji: '🎊', gradientColors: [Color(0xFF1A0030), Color(0xFF350060)], accentColor: Color(0xFFE0A000), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFECC060), footerColor: Color(0xFFB08020)),
  // ── 신앙 성장 및 비전 ──────────────────────────────────────────────────
  CardThemeData(name: '사명', emoji: '🗺️', gradientColors: [Color(0xFF0D2840), Color(0xFF1A3D60)], accentColor: Color(0xFF50B0D0), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFA0CCE0), footerColor: Color(0xFF3090B0)),
  CardThemeData(name: '성경 완독', emoji: '👑', gradientColors: [Color(0xFF1A1000), Color(0xFF2E2000)], accentColor: Color(0xFFFFD700), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFEECC60), footerColor: Color(0xFFBB9920)),
  CardThemeData(name: '가족 축복', emoji: '🏡', gradientColors: [Color(0xFF3D1E0A), Color(0xFF6B3A18)], accentColor: Color(0xFFFFB870), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFFFD8A8), footerColor: Color(0xFFCC8840)),
  CardThemeData(name: '비전', emoji: '🧭', gradientColors: [Color(0xFF040B24), Color(0xFF0B1642)], accentColor: Color(0xFF6070E8), verseColor: Color(0xFFFFFFFF), prayerColor: Color(0xFFB0B8F8), footerColor: Color(0xFF4050C8)),
];

// 카테고리별 인덱스 매핑 (0-2: 기본 특수 템플릿, 3-22: _themedCards 인덱스+3)
const _categories = {
  '기본': [0, 1, 2],
  '계절': [3, 4, 5, 6],
  '시간대': [7, 8, 9, 10],
  '위로': [11, 12, 13, 14],
  '공동체': [15, 16, 17, 18],
  '비전': [19, 20, 21, 22],
};

const _chipLabels = [
  ('다크 미니멀', '🌙'),
  ('리치 미디어', '🌿'),
  ('커뮤니티', '🤝'),
  // 계절
  ('봄', '🌱'), ('여름', '🌊'), ('가을', '🍂'), ('겨울', '❄️'),
  // 시간대
  ('새벽 기도', '🌅'), ('저녁 묵상', '🌌'), ('식사 기도', '🍞'), ('일터 기도', '✨'),
  // 위로
  ('위로', '🏮'), ('치유', '🌿'), ('인내', '🌵'), ('회개', '🌧️'),
  // 공동체
  ('중보 기도', '🤲'), ('감사 찬양', '🌸'), ('주일 설교', '✝️'), ('열매 나눔', '🎊'),
  // 비전
  ('사명', '🗺️'), ('성경 완독', '👑'), ('가족 축복', '🏡'), ('비전', '🧭'),
];

// ─── 메인 화면 ────────────────────────────────────────────────────────────────
class PrayerCardScreen extends ConsumerStatefulWidget {
  final QtEntry entry;
  const PrayerCardScreen({super.key, required this.entry});

  @override
  ConsumerState<PrayerCardScreen> createState() => _PrayerCardScreenState();
}

class _PrayerCardScreenState extends ConsumerState<PrayerCardScreen> {
  int _selectedIndex = 0;
  String _activeCategory = '기본';
  final _cardKey = GlobalKey();
  bool _isSaving = false;

  Future<Uint8List?> _captureCard() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('갤러리 저장 권한이 필요해요')),
            );
          }
          return;
        }
      }
      final bytes = await _captureCard();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카드 생성에 실패했어요. 다시 시도해주세요')),
          );
        }
        return;
      }
      await Gal.putImageBytes(bytes, album: 'Grace Garden');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에 저장됐어요! 📸')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했어요: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareCard() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureCard();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/prayer_card_share.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🙏 오늘의 기도 카드\n\n${widget.entry.scriptureTitle}\n\n${widget.entry.prayer}',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareToCommuntiy() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // 달란트 확인
    final profile = ref.read(userProfileProvider);
    if (profile.totalTalents < _cardShareCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('달란트가 부족해요. 나눔 비용: $_cardShareCost ⭐, 보유: ${profile.totalTalents} ⭐')),
      );
      return;
    }

    // 재확인
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('공동체 나눔'),
        content: Text('$_cardShareCost 달란트를 사용해서 기도카드를 나눔할까요?\n\n보유: ${profile.totalTalents} ⭐'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('나눔')),
        ],
      ),
    );
    if (confirmed != true) return;

    // 달란트 차감
    final box = ref.read(profileBoxProvider);
    final p = box.get('me');
    if (p != null) {
      p.totalTalents -= _cardShareCost;
      await p.save();
      ref.invalidate(userProfileProvider);
    }

    if (!mounted) return;
    final shared = await shareToCommunity(
      context: context,
      ref: ref,
      buildPost: (communityId) => CommunityPost(
        id: '',
        communityId: communityId,
        uid: user.uid,
        displayName: user.displayName ?? '사용자',
        scriptureTitle: widget.entry.scriptureTitle,
        scriptureVerse: widget.entry.scriptureVerse,
        prayer: widget.entry.prayer,
        meditation: widget.entry.meditation,
        createdAt: DateTime.now(),
      ),
    );
    if (shared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공동체 나눔에 등록됐어요! 🤝')),
      );
      context.go(AppRoutes.community);
    }
  }

  Widget _buildCard() {
    if (_selectedIndex == 0) return _DarkMinimalCard(entry: widget.entry);
    if (_selectedIndex == 1) return _RichMediaCard(entry: widget.entry);
    if (_selectedIndex == 2) return _CommunityCard(entry: widget.entry);
    return _ThemedCard(theme: _themedCards[_selectedIndex - 3], entry: widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryIndices = _categories[_activeCategory]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('기도 카드'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveToGallery,
            icon: const Icon(Icons.download_outlined),
            tooltip: '저장',
          ),
          IconButton(
            onPressed: _isSaving ? null : _shareCard,
            icon: const Icon(Icons.share_outlined),
            tooltip: '공유',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 카테고리 탭 ────────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.keys.map((cat) {
                final selected = _activeCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _activeCategory = cat;
                      // 해당 카테고리의 첫 번째 테마 자동 선택
                      _selectedIndex = _categories[cat]!.first;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? Colors.white : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── 테마 칩 (선택된 카테고리) ──────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: categoryIndices.map((idx) {
                final (name, emoji) = _chipLabels[idx];
                final selected = _selectedIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? Border.all(color: colorScheme.primary, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        '$emoji $name',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── 카드 미리보기 ──────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ),

          // ── 하단 버튼 ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveToGallery,
                      icon: const Icon(Icons.download),
                      label: const Text('저장'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _shareToCommuntiy,
                      icon: const Icon(Icons.group_outlined),
                      label: const Text('나눔  (5 ⭐)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 템플릿 1: 다크 미니멀 ───────────────────────────────────────────────────
class _DarkMinimalCard extends StatelessWidget {
  final QtEntry entry;
  const _DarkMinimalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy.MM.dd').format(entry.date);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 날짜(작게) + 이모지
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(color: Color(0xFF555555), fontSize: 10, letterSpacing: 0.5)),
                const Text('🌱', style: TextStyle(fontSize: 16)),
              ],
            ),
            const Spacer(flex: 1),
            // 구절 참조 (작게, accent)
            Text(
              entry.scriptureTitle,
              style: const TextStyle(color: Color(0xFF4CAF87), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            // 성경 구절 (크게, 히어로)
            Text(
              entry.scriptureVerse,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
            ),
            const Spacer(flex: 1),
            Container(height: 1, color: const Color(0xFF2C2C2E)),
            const SizedBox(height: 12),
            // 기도 (작게)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🙏 ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(entry.prayer, maxLines: 4, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, height: 1.6)),
                ),
              ],
            ),
            const Spacer(flex: 1),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Grace Garden', style: const TextStyle(color: Color(0xFF3A3A3C), fontSize: 10, letterSpacing: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 템플릿 2: 리치 미디어 ───────────────────────────────────────────────────
class _RichMediaCard extends StatelessWidget {
  final QtEntry entry;
  const _RichMediaCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy.MM.dd').format(entry.date);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // 아주 미세한 그라데이션
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B4332), Color(0xFF0D2B1A)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(color: Color(0xFF52A888), fontSize: 10, letterSpacing: 0.5)),
                const Text('🌿', style: TextStyle(fontSize: 16)),
              ],
            ),
            const Spacer(flex: 2),
            // 큰 따옴표
            const Text('"', style: TextStyle(color: Color(0xFF4CAF87), fontSize: 52, height: 0.9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            // 구절 (크게)
            Text(entry.scriptureVerse,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5)),
            const SizedBox(height: 8),
            // 참조 (작게)
            Text('— ${entry.scriptureTitle}',
                style: const TextStyle(color: Color(0xFF4CAF87), fontSize: 11, letterSpacing: 0.5)),
            const Spacer(flex: 1),
            Container(width: double.infinity, height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🙏 ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(entry.prayer, maxLines: 4, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF8DBDAA), fontSize: 12, height: 1.6)),
                ),
              ],
            ),
            const Spacer(flex: 2),
            Align(
              alignment: Alignment.centerRight,
              child: const Text('Grace Garden 🌳', style: TextStyle(color: Color(0xFF3A7A5A), fontSize: 10, letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 템플릿 3: 커뮤니티 나눔형 ───────────────────────────────────────────────
class _CommunityCard extends StatelessWidget {
  final QtEntry entry;
  const _CommunityCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('M월 d일').format(entry.date);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 배지 + 날짜(작게)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6914).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('📖 묵상 나눔',
                      style: TextStyle(color: Color(0xFF8B6914), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(date, style: const TextStyle(color: Color(0xFFAA9977), fontSize: 10)),
              ],
            ),
            const SizedBox(height: 14),
            // 구절 참조 (작게)
            Text(entry.scriptureTitle,
                style: const TextStyle(color: Color(0xFF2E5A2E), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            // 성경 구절 (크게)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E4A2E).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: const Color(0xFF2E4A2E).withValues(alpha: 0.35), width: 3)),
              ),
              child: Text(entry.scriptureVerse,
                  style: const TextStyle(color: Color(0xFF2C4A2C), fontSize: 16, fontWeight: FontWeight.bold, height: 1.5, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: const Color(0xFFEEE8DC)),
            const SizedBox(height: 12),
            const Text('💭 묵상', style: TextStyle(color: Color(0xFF7A6050), fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 5),
            Text(entry.meditation, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF5A4838), fontSize: 12, height: 1.5)),
            const SizedBox(height: 10),
            const Text('🙏 기도', style: TextStyle(color: Color(0xFF7A6050), fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 5),
            Text(entry.prayer, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF5A4838), fontSize: 12, height: 1.5)),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEEE8DC), borderRadius: BorderRadius.circular(16)),
                  child: const Text('🙏 아멘', style: TextStyle(color: Color(0xFF6B5040), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                const Text('Grace Garden', style: TextStyle(color: Color(0xFFCCBBA8), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 파라미터화 테마 카드 (20종 공통 레이아웃) ────────────────────────────────
// 배경: 단색(theme 기반), 카드: 흰색 반투명, 구절: 크게, 날짜: 작게
class _ThemedCard extends StatelessWidget {
  final CardThemeData theme;
  final QtEntry entry;
  const _ThemedCard({required this.theme, required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy.MM.dd').format(entry.date);
    final bg = theme.gradientColors.first;
    return Container(
      decoration: BoxDecoration(
        // 단색 배경 (아주 미세한 그라데이션)
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg, Color.lerp(bg, Colors.black, 0.18)!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Container(
        // 흰색 반투명 카드
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜(작게) + 이모지
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 10, letterSpacing: 0.4)),
                Text(theme.emoji, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const Spacer(flex: 1),

            // 구절 참조(작게, accent)
            Text(
              entry.scriptureTitle,
              style: TextStyle(color: theme.accentColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),

            // 성경 구절 (크게, 히어로)
            Text(
              entry.scriptureVerse,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
            ),

            const Spacer(flex: 1),
            Container(height: 1, color: const Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // 기도(작게)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🙏 ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    entry.prayer,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF777777), fontSize: 12, height: 1.6),
                  ),
                ),
              ],
            ),

            const Spacer(flex: 1),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Grace Garden', style: TextStyle(color: theme.accentColor.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
