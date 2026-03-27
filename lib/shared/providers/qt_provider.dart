import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/qt_entry.dart';
import '../models/user_profile.dart';
import 'hive_provider.dart';
import 'profile_provider.dart';

// 전체 QT 목록
final qtListProvider = Provider<List<QtEntry>>((ref) {
  final box = ref.watch(qtBoxProvider);
  final entries = box.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return entries;
});

// 오늘 QT 목록 (여러 건)
final todayQtListProvider = Provider<List<QtEntry>>((ref) {
  final list = ref.watch(qtListProvider);
  final today = DateTime.now();
  return list
      .where(
        (e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day,
      )
      .toList();
});

// 날짜별 QT 목록 (여러 건)
final qtsByDateProvider = Provider.family<List<QtEntry>, DateTime>((ref, date) {
  final list = ref.watch(qtListProvider);
  return list
      .where(
        (e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day,
      )
      .toList();
});

// QT 저장 서비스
class QtService {
  final Box<QtEntry> _qtBox;
  final Box<UserProfile> _profileBox;
  final Ref _ref;

  QtService(this._qtBox, this._profileBox, this._ref);

  Future<QtEntry> saveQtEntry({
    required String scriptureTitle,
    required String scriptureVerse,
    required String meditation,
    required String application,
    required String prayer,
    DateTime? date,
  }) async {
    final entry = QtEntry(
      id: const Uuid().v4(),
      date: date ?? DateTime.now(),
      scriptureTitle: scriptureTitle,
      scriptureVerse: scriptureVerse,
      meditation: meditation,
      application: application,
      prayer: prayer,
      talentsEarned: 10,
    );
    await _qtBox.put(entry.id, entry);
    await _updateProfile();
    _ref.invalidate(qtListProvider);
    _ref.invalidate(userProfileProvider);
    return entry; // 저장된 entry 반환 (공유 등에 사용)
  }

  Future<void> _updateProfile() async {
    final profile = _profileBox.get('me') ??
        UserProfile(uid: 'me', displayName: '사용자');

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final prevDate = profile.lastQtDate;

    // 오늘 첫 번째 QT인지 확인 (streak은 하루 한 번만 증가)
    final isFirstTodayQt = prevDate == null ||
        !(prevDate.year == now.year &&
            prevDate.month == now.month &&
            prevDate.day == now.day);

    profile.totalTalents += 10;
    profile.totalQtCount += 1;
    profile.lastQtDate = now;

    if (isFirstTodayQt) {
      final isConsecutive = prevDate != null &&
          prevDate.year == yesterday.year &&
          prevDate.month == yesterday.month &&
          prevDate.day == yesterday.day;
      profile.qtStreak = isConsecutive ? profile.qtStreak + 1 : 1;
    }

    // 나무 성장 체크
    final thresholds = UserProfile.stageThresholds;
    if (profile.treeStage < 4) {
      if (profile.totalQtCount >= thresholds[profile.treeStage]) {
        profile.treeStage += 1;
      }
    }

    await _profileBox.put('me', profile);
  }

  Future<void> updateEntry({
    required String id,
    required String scriptureTitle,
    required String scriptureVerse,
    required String meditation,
    required String application,
    required String prayer,
  }) async {
    final existing = _qtBox.get(id);
    if (existing == null) return;
    final updated = QtEntry(
      id: existing.id,
      date: existing.date,
      scriptureTitle: scriptureTitle,
      scriptureVerse: scriptureVerse,
      meditation: meditation,
      application: application,
      prayer: prayer,
      isShared: existing.isShared,
      talentsEarned: existing.talentsEarned,
      cardTemplate: existing.cardTemplate,
    );
    await _qtBox.put(id, updated);
    _ref.invalidate(qtListProvider);
  }

  Future<void> deleteEntry(String id) async {
    final existing = _qtBox.get(id);
    if (existing == null) return;
    await _qtBox.delete(id);

    // 달란트 회수
    final profile = _profileBox.get('me');
    if (profile != null) {
      profile.totalTalents =
          (profile.totalTalents - existing.talentsEarned).clamp(0, 999999);
      profile.totalQtCount = (profile.totalQtCount - 1).clamp(0, 999999);
      // 나무 단계 재계산
      final thresholds = UserProfile.stageThresholds;
      int stage = 0;
      for (int i = thresholds.length - 1; i >= 0; i--) {
        if (profile.totalQtCount >= thresholds[i]) {
          stage = i + 1;
          break;
        }
      }
      profile.treeStage = stage.clamp(0, 4);
      await _profileBox.put('me', profile);
    }
    _ref.invalidate(qtListProvider);
    _ref.invalidate(userProfileProvider);
  }
}

final qtServiceProvider = Provider<QtService>((ref) {
  final qtBox = ref.watch(qtBoxProvider);
  final profileBox = ref.watch(profileBoxProvider);
  return QtService(qtBox, profileBox, ref);
});
