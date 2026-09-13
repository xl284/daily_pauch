import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/database/app_database.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      settings: init,
      onDidReceiveNotificationResponse: _onTap,
    );

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification tapped: $payload');
  }

  static Future<void> scheduleTaskReminders(Task task) async {
    if (kIsWeb) return;
    await cancelTaskReminders(task.id);
    if (!task.enableReminder || task.archivedAt != null) return;
    if (task.reminderTimes == '[]') return;

    final times = _parseReminderTimes(task.reminderTimes);
    for (final t in times) {
      final id = _reminderId(task.id, t);
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day,
        t.hour,
        t.minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: id,
        title: '打卡提醒',
        body: '「${task.name}」还没打卡哦',
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            '任务提醒',
            channelDescription: '任务到期未完成时的提醒',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'task:${task.id}',
      );
    }
  }

  static Future<void> cancelTaskReminders(int taskId) async {
    if (kIsWeb) return;
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += 5) {
        final id = _reminderId(taskId, TimeOfDay(hour: h, minute: m));
        await _plugin.cancel(id: id);
      }
    }
  }

  /// 查询是否已有精确闹钟权限
  static Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// 请求精确闹钟权限。Android 12+ 需要跳系统设置页面手动开启，
  /// request() 会自动跳转；API 34+ 还需要 USE_EXACT_ALARM 额外声明。
  static Future<String> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return '当前平台无需此权限';
    try {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isGranted) return '已获得精确闹钟权限 ✓';

      final result = await Permission.scheduleExactAlarm.request();
      if (result.isGranted) return '权限已授予 ✓';
      if (result.isPermanentlyDenied) {
        await openAppSettings();
        return '已跳转系统设置，请手动打开精确闹钟权限';
      }
      // Android 12+ 上可能 request() 直接跳转了设置页，
      // 不管结果如何，给用户说明需要手动开启
      await openExactAlarmSettings();
      return '已跳转系统设置 → 闹钟与提醒 → 允许精确闹钟';
    } catch (_) {
      // 兜底：直接跳系统设置
      await openExactAlarmSettings();
      return '已跳转系统设置，请手动开启精确闹钟权限';
    }
  }

  /// 直接打开精确闹钟权限设置页面
  static Future<void> openExactAlarmSettings() async {
    final uri = Uri.parse('package:${_plugin.runtimeType.toString()}');
    // 使用 ACTION_REQUEST_SCHEDULE_EXACT_ALARM 对应的 package 设置页
    final pkgUri = Uri.parse(
        'content://com.android.settings.files/my_cache/permission/${Platform.isAndroid ? await _packageName() : ''}');
    try {
      await openAppSettings();
    } catch (_) {
      // openAppSettings() 失败时尝试用 url_launcher
      try {
        await launchUrl(Uri.parse(
            'package:${await _packageName()}?scheme=appops#com.android.settings.action.REQUEST_SCHEDULE_EXACT_ALARM'));
      } catch (_) {}
    }
  }

  static Future<String> _packageName() async {
    return 'com.daily_pauch.app.daily_pauch';
  }

  static List<TimeOfDay> _parseReminderTimes(String json) {
    try {
      final clean = json.replaceAll(RegExp(r'[\[\]\s]'), '');
      if (clean.isEmpty) return [];
      final parts = clean.split('},{');
      final result = <TimeOfDay>[];
      for (final p in parts) {
        final hp = RegExp(r'"h":(\d+)').firstMatch(p)?.group(1);
        final mp = RegExp(r'"m":(\d+)').firstMatch(p)?.group(1);
        if (hp != null && mp != null) {
          result.add(TimeOfDay(hour: int.parse(hp), minute: int.parse(mp)));
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  static int _reminderId(int taskId, TimeOfDay t) {
    return taskId * 10000 + t.hour * 100 + t.minute;
  }
}
