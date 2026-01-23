/*
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String _timeZoneName = 'UTC';

  String get timeZoneName => _timeZoneName;

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);

    // FIX 1: use tzdata.initializeTimeZones() + FlutterTimezone
    tzdata.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final name = tzInfo.identifier; // ✅ correct

      tz.setLocalLocation(tz.getLocation(name));
      _timeZoneName = name;
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
      _timeZoneName = 'UTC';
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await init();

    // FIX 2: correct Android permission method + platform check
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    await init();
    if (!reminder.isEnabled || reminder.isCompleted) return;

    final nowUtc = DateTime.now().toUtc();
    final expiryUtc = reminder.expiryAt.toUtc();
    final nearUtc = expiryUtc.subtract(
      Duration(minutes: reminder.nearExpiryOffsetMinutes),
    );
    final postUtc = expiryUtc.add(
      Duration(minutes: reminder.postExpiryDelayMinutes),
    );

    final baseId = _baseId(reminder.id);
    final details = _notificationDetails();
    final expiryLabel =
        DateFormat('MMM dd, hh:mm a').format(expiryUtc.toLocal());

    if (nearUtc.isAfter(nowUtc)) {
      await _plugin.zonedSchedule(
        baseId + 1,
        'Reminder soon',
        '${reminder.title} expires at $expiryLabel',
        tz.TZDateTime.from(nearUtc, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );
    }

    if (expiryUtc.isAfter(nowUtc)) {
      await _plugin.zonedSchedule(
        baseId + 2,
        'Reminder due',
        '${reminder.title} expires now ($expiryLabel)',
        tz.TZDateTime.from(expiryUtc, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );
    }

    if (postUtc.isAfter(nowUtc)) {
      await _plugin.zonedSchedule(
        baseId + 3,
        'Reminder follow-up',
        '${reminder.title} expired at $expiryLabel',
        tz.TZDateTime.from(postUtc, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    await init();
    final baseId = _baseId(reminderId);
    await _plugin.cancel(baseId + 1);
    await _plugin.cancel(baseId + 2);
    await _plugin.cancel(baseId + 3);
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  int _baseId(String id) {
    return _stableHash(id) & 0x7fffffff;
  }

  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
*/
//
//
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'reminders_alerts';
  static const String _channelName = 'Reminder Alerts';
  static const String _channelDesc = 'Reminder notifications with sound';
  static const int _extraAlertBaseOffset = 100;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String _timeZoneName = 'UTC';

  String get timeZoneName => _timeZoneName;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Create Android notification channel with sound (first creation wins).
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
    }

    // Timezone init
    tzdata.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final name = tzInfo.identifier;

      tz.setLocalLocation(tz.getLocation(name));
      _timeZoneName = name;
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
      _timeZoneName = 'UTC';
    }

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await init();

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    await init();
    if (!reminder.isEnabled || reminder.isCompleted) return;

    final nowUtc = DateTime.now().toUtc();
    final expiryUtc = reminder.expiryAt.toUtc();
    final nearUtc = expiryUtc.subtract(
      Duration(minutes: reminder.nearExpiryOffsetMinutes),
    );
    final postUtc = expiryUtc.add(
      Duration(minutes: reminder.postExpiryDelayMinutes),
    );
    final extraAlerts = List<DateTime>.from(reminder.extraAlerts)
      ..sort((a, b) => a.toUtc().compareTo(b.toUtc()));

    final baseId = _baseId(reminder.id);
    final details = _notificationDetails();
    final expiryLabel = _formatLabel(reminder, expiryUtc);
    final location = _locationForReminder(reminder);

    if (nearUtc.isAfter(nowUtc)) {
      await _plugin.zonedSchedule(
        baseId + 1,
        'Reminder soon',
        '${reminder.title} expires at $expiryLabel',
        tz.TZDateTime.from(nearUtc, location),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );
    }

    if (expiryUtc.isAfter(nowUtc)) {
      await _plugin.zonedSchedule(
        baseId + 2,
        'Reminder due',
        '${reminder.title} expires now ($expiryLabel)',
        tz.TZDateTime.from(expiryUtc, location),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );
    }

    if (postUtc.isAfter(nowUtc)) {
      await _plugin.zonedSchedule(
        baseId + 3,
        'Reminder follow-up',
        '${reminder.title} expired at $expiryLabel',
        tz.TZDateTime.from(postUtc, location),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );
    }

    for (var i = 0; i < extraAlerts.length; i++) {
      final alertUtc = extraAlerts[i].toUtc();
      if (!alertUtc.isAfter(nowUtc)) continue;
      final alertLabel = _formatLabel(reminder, alertUtc);
      await _plugin.zonedSchedule(
        baseId + _extraAlertBaseOffset + i,
        'Reminder alert',
        '${reminder.title} at $alertLabel',
        tz.TZDateTime.from(alertUtc, location),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );
    }
  }

  Future<void> cancelReminder(String reminderId, {int extraCount = 0}) async {
    await init();
    final baseId = _baseId(reminderId);
    await _plugin.cancel(baseId + 1);
    await _plugin.cancel(baseId + 2);
    await _plugin.cancel(baseId + 3);
    for (var i = 0; i < extraCount; i++) {
      await _plugin.cancel(baseId + _extraAlertBaseOffset + i);
    }
  }

  Future<void> cancelReminderFor(Reminder reminder) async {
    await cancelReminder(
      reminder.id,
      extraCount: reminder.extraAlerts.length,
    );
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const ios = DarwinNotificationDetails(
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return const NotificationDetails(android: android, iOS: ios);
  }

  tz.Location _locationForReminder(Reminder reminder) {
    if (reminder.timeZone == 'UTC') {
      return tz.UTC;
    }
    try {
      return tz.getLocation(reminder.timeZone);
    } catch (_) {
      return tz.local;
    }
  }

  String _formatLabel(Reminder reminder, DateTime utc) {
    final display =
        reminder.timeZone == 'UTC' ? utc.toUtc() : utc.toLocal();
    return DateFormat('MMM dd, hh:mm a').format(display);
  }

  int _baseId(String id) {
    return _stableHash(id) & 0x7fffffff;
  }

  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
