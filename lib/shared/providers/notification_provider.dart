import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import 'hive_provider.dart';

class AlarmState {
  final bool enabled;
  final int hour;
  final int minute;

  const AlarmState({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  AlarmState copyWith({bool? enabled, int? hour, int? minute}) => AlarmState(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

// QT 알림
final qtAlarmProvider =
    StateNotifierProvider<_AlarmNotifier, AlarmState>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final svc = ref.watch(notificationServiceProvider);
  return _AlarmNotifier(
    box: box,
    svc: svc,
    enabledKey: 'qt_alarm',
    hourKey: 'qt_alarm_hour',
    minuteKey: 'qt_alarm_minute',
    defaultHour: 7,
    schedule: (enabled, hour, minute) =>
        svc.scheduleQtAlarm(enabled, hour: hour, minute: minute),
  );
});

// 설교 알림
final sermonAlarmProvider =
    StateNotifierProvider<_AlarmNotifier, AlarmState>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final svc = ref.watch(notificationServiceProvider);
  return _AlarmNotifier(
    box: box,
    svc: svc,
    enabledKey: 'sermon_alarm',
    hourKey: 'sermon_alarm_hour',
    minuteKey: 'sermon_alarm_minute',
    defaultHour: 9,
    schedule: (enabled, hour, minute) =>
        svc.scheduleSermonAlarm(enabled, hour: hour, minute: minute),
  );
});

class _AlarmNotifier extends StateNotifier<AlarmState> {
  final Box<dynamic> _box;
  final String _enabledKey;
  final String _hourKey;
  final String _minuteKey;
  final Future<void> Function(bool, int, int) _schedule;

  _AlarmNotifier({
    required Box<dynamic> box,
    required NotificationService svc,
    required String enabledKey,
    required String hourKey,
    required String minuteKey,
    required int defaultHour,
    required Future<void> Function(bool, int, int) schedule,
  })  : _box = box,
        _enabledKey = enabledKey,
        _hourKey = hourKey,
        _minuteKey = minuteKey,
        _schedule = schedule,
        super(AlarmState(
          enabled: box.get(enabledKey, defaultValue: false) as bool,
          hour: box.get(hourKey, defaultValue: defaultHour) as int,
          minute: box.get(minuteKey, defaultValue: 0) as int,
        ));

  Future<void> toggle(bool value) async {
    state = state.copyWith(enabled: value);
    await _box.put(_enabledKey, value);
    await _schedule(value, state.hour, state.minute);
  }

  Future<void> updateTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _box.put(_hourKey, hour);
    await _box.put(_minuteKey, minute);
    if (state.enabled) {
      await _schedule(true, hour, minute);
    }
  }
}
