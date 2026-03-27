import 'package:hive_flutter/hive_flutter.dart';

part 'qt_entry.g.dart';

@HiveType(typeId: 0)
class QtEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String scriptureTitle;

  @HiveField(3)
  final String scriptureVerse;

  @HiveField(4)
  final String meditation;

  @HiveField(5)
  final String application;

  @HiveField(6)
  final String prayer;

  @HiveField(7)
  final bool isShared;

  @HiveField(8)
  final int talentsEarned;

  @HiveField(9)
  final String? cardTemplate; // 'dark_minimal' | 'rich_media' | 'community'

  QtEntry({
    required this.id,
    required this.date,
    required this.scriptureTitle,
    required this.scriptureVerse,
    required this.meditation,
    required this.application,
    required this.prayer,
    this.isShared = false,
    this.talentsEarned = 10,
    this.cardTemplate,
  });

  QtEntry copyWith({
    String? id,
    DateTime? date,
    String? scriptureTitle,
    String? scriptureVerse,
    String? meditation,
    String? application,
    String? prayer,
    bool? isShared,
    int? talentsEarned,
    String? cardTemplate,
  }) {
    return QtEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      scriptureTitle: scriptureTitle ?? this.scriptureTitle,
      scriptureVerse: scriptureVerse ?? this.scriptureVerse,
      meditation: meditation ?? this.meditation,
      application: application ?? this.application,
      prayer: prayer ?? this.prayer,
      isShared: isShared ?? this.isShared,
      talentsEarned: talentsEarned ?? this.talentsEarned,
      cardTemplate: cardTemplate ?? this.cardTemplate,
    );
  }
}
