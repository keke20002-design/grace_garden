import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'hive_provider.dart';

final userProfileProvider = Provider<UserProfile>((ref) {
  final box = ref.watch(profileBoxProvider);
  return box.get('me') ?? UserProfile(uid: 'me', displayName: '사용자');
});

// 테마 설정 (다크/라이트)
final themeModeProvider = StateProvider<bool>((ref) => true); // true = dark
