import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'shared/models/qt_entry.dart';
import 'shared/models/user_profile.dart';
import 'shared/models/sermon_entry.dart';
import 'shared/providers/hive_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'shared/services/notification_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive 초기화
  await Hive.initFlutter();
  Hive.registerAdapter(QtEntryAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(SermonEntryAdapter());
  await Hive.openBox<QtEntry>(qtBoxName);
  await Hive.openBox<UserProfile>(profileBoxName);
  await Hive.openBox<SermonEntry>(sermonBoxName);
  await Hive.openBox<dynamic>(settingsBoxName);

  // AdMob 초기화
  await MobileAds.instance.initialize();

  // 알림 서비스 초기화 + 기존 설정 재등록
  final notificationService = NotificationService();
  await notificationService.initialize();
  final settings = Hive.box<dynamic>(settingsBoxName);
  if (settings.get('qt_alarm', defaultValue: false) as bool) {
    await notificationService.scheduleQtAlarm(
      true,
      hour: settings.get('qt_alarm_hour', defaultValue: 7) as int,
      minute: settings.get('qt_alarm_minute', defaultValue: 0) as int,
    );
  }
  if (settings.get('sermon_alarm', defaultValue: false) as bool) {
    await notificationService.scheduleSermonAlarm(
      true,
      hour: settings.get('sermon_alarm_hour', defaultValue: 9) as int,
      minute: settings.get('sermon_alarm_minute', defaultValue: 0) as int,
    );
  }

  // 로그인 세션이 없으면 익명으로 자동 로그인 (로그인 화면 없이 앱 사용 가능)
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  runApp(const ProviderScope(child: GraceGardenApp()));
}
