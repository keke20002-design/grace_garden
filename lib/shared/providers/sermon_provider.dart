import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/sermon_entry.dart';
import '../models/user_profile.dart';
import 'hive_provider.dart';
import 'profile_provider.dart';

// 전체 설교 목록 (최신순) — sermonVersionProvider를 watch해서 변경 감지
final sermonListProvider = Provider<List<SermonEntry>>((ref) {
  ref.watch(sermonVersionProvider); // 버전 변경 시 재실행
  final box = ref.watch(sermonBoxProvider);
  final list = box.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return list;
});

// 가장 최근 설교
final latestSermonProvider = Provider<SermonEntry?>((ref) {
  final list = ref.watch(sermonListProvider);
  return list.isEmpty ? null : list.first;
});

class SermonService {
  final Box<SermonEntry> _sermonBox;
  final Box<UserProfile> _profileBox;
  final Ref _ref;

  SermonService(this._sermonBox, this._profileBox, this._ref);

  Future<void> saveSermon({
    required String title,
    required String pastor,
    required String scriptureRef,
    required String summary,
    required String fullContent,
    DateTime? date,
  }) async {
    final entry = SermonEntry(
      id: const Uuid().v4(),
      date: date ?? DateTime.now(),
      title: title,
      pastor: pastor,
      scriptureRef: scriptureRef,
      summary: summary,
      fullContent: fullContent,
      talentsEarned: 5,
    );
    await _sermonBox.put(entry.id, entry);

    // 달란트 5개 지급
    final profile = _profileBox.get('me');
    if (profile != null) {
      profile.totalTalents += 5;
      await _profileBox.put('me', profile);
    }
    _ref.read(sermonVersionProvider.notifier).state++;
    _ref.invalidate(userProfileProvider);
  }

  Future<void> deleteSermon(String id) async {
    final entry = _sermonBox.get(id);
    if (entry == null) return;
    await _sermonBox.delete(id);
    final profile = _profileBox.get('me');
    if (profile != null) {
      profile.totalTalents =
          (profile.totalTalents - entry.talentsEarned).clamp(0, 999999);
      await _profileBox.put('me', profile);
    }
    _ref.read(sermonVersionProvider.notifier).state++;
    _ref.invalidate(userProfileProvider);
  }
}

final sermonServiceProvider = Provider<SermonService>((ref) {
  final sermonBox = ref.watch(sermonBoxProvider);
  final profileBox = ref.watch(profileBoxProvider);
  return SermonService(sermonBox, profileBox, ref);
});
