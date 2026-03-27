import 'package:hive_flutter/hive_flutter.dart';

part 'sermon_entry.g.dart';

@HiveType(typeId: 2)
class SermonEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String title;

  @HiveField(3)
  String pastor;

  @HiveField(4)
  String scriptureRef;

  @HiveField(5)
  String summary;

  @HiveField(6)
  String fullContent;

  @HiveField(7)
  int talentsEarned;

  SermonEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.pastor,
    required this.scriptureRef,
    required this.summary,
    required this.fullContent,
    this.talentsEarned = 5,
  });
}
