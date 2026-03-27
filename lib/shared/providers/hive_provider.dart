import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/qt_entry.dart';
import '../models/user_profile.dart';
import '../models/sermon_entry.dart';

const qtBoxName = 'qt_entries';
const profileBoxName = 'user_profile';
const sermonBoxName = 'sermons';
const settingsBoxName = 'settings';

final qtBoxProvider = Provider<Box<QtEntry>>((ref) {
  return Hive.box<QtEntry>(qtBoxName);
});

final profileBoxProvider = Provider<Box<UserProfile>>((ref) {
  return Hive.box<UserProfile>(profileBoxName);
});

final sermonBoxProvider = Provider<Box<SermonEntry>>((ref) {
  return Hive.box<SermonEntry>(sermonBoxName);
});

final settingsBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>(settingsBoxName);
});

// 설교 목록 반응성을 위한 버전 카운터
final sermonVersionProvider = StateProvider<int>((ref) => 0);
