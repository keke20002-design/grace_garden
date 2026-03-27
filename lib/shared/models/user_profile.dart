import 'package:hive_flutter/hive_flutter.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  String displayName;

  @HiveField(2)
  int totalTalents;

  @HiveField(3)
  int treeStage; // 0~4: 씨앗/새싹/어린나무/성목/열매

  @HiveField(4)
  int qtStreak; // 연속 QT 일수

  @HiveField(5)
  int totalQtCount;

  @HiveField(6)
  DateTime? lastQtDate;

  UserProfile({
    required this.uid,
    required this.displayName,
    this.totalTalents = 0,
    this.treeStage = 0,
    this.qtStreak = 0,
    this.totalQtCount = 0,
    this.lastQtDate,
  });

  // 나무 단계 레이블
  String get treeStageName {
    const names = ['씨앗', '새싹', '어린나무', '성목', '열매나무'];
    return names[treeStage.clamp(0, 4)];
  }

  // 다음 단계까지 필요한 QT 횟수 (씨앗:3, 새싹:7, 어린나무:15, 성목:30)
  static const List<int> stageThresholds = [3, 7, 15, 30];

  int get qtCountForNextStage {
    if (treeStage >= 4) return 0;
    return stageThresholds[treeStage];
  }
}
