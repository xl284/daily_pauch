import '../../data/database/app_database.dart';
import '../models/schedule_type.dart';

/// 周期计算核心：判定任务在某日是否应打卡、应打卡次数、打卡率、连续天数。
class ScheduleEngine {
  /// 任务在 [date] 当天是否"活跃"（应打卡）。
  static bool isTaskActiveOn(Task task, DateTime date) {
    if (task.archivedAt != null) return false;
    final today = DateTime(date.year, date.month, date.day);
    final start = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
    if (today.isBefore(start)) return false;
    if (task.endDate != null) {
      final end = DateTime(task.endDate!.year, task.endDate!.month, task.endDate!.day);
      if (today.isAfter(end)) return false;
    }
    final type = ScheduleType.fromString(task.scheduleType);
    switch (type) {
      case ScheduleType.once:
        return today == start;
      case ScheduleType.daily:
        return true;
      case ScheduleType.weekly:
        final wds = _parseWeekdays(task.weekdays);
        return wds.contains(date.weekday);
      case ScheduleType.monthly:
        final dom = task.dayOfMonth ?? 1;
        if (dom == -1) return date.day == _lastDayOfMonth(date);
        return date.day == dom;
      case ScheduleType.yearly:
        return date.month == (task.monthOfYear ?? 1) &&
            date.day == (task.dayOfMonthOfYear ?? 1);
      case ScheduleType.custom:
        final days = _parseCustomDays(task.customDays);
        final iso = '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
        return days.contains(iso);
    }
  }

  /// 从任务开始日到 [upTo] 之间的应打卡总次数。
  static int dueCount(Task task, DateTime upTo) {
    final start = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
    DateTime end = DateTime(upTo.year, upTo.month, upTo.day);
    if (task.endDate != null) {
      final e = DateTime(task.endDate!.year, task.endDate!.month, task.endDate!.day);
      if (e.isBefore(end)) end = e;
    }
    if (end.isBefore(start)) return 0;
    int count = 0;
    final type = ScheduleType.fromString(task.scheduleType);
    var d = start;
    while (!d.isAfter(end)) {
      if (_matchesSchedule(task, type, d)) count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  /// 当前连续打卡天数（从 [today] 向前回溯到第一个"应打卡却没完成"为止）。
  ///
  /// [doneDates] 是该任务所有已打卡日期的 Set（按当天 00:00 归一化）。
  /// [skippedDates] 是该任务所有已跳过日期的 Set。
  static int currentStreak(
    Task task,
    DateTime today,
    Set<DateTime> doneDates,
    Set<DateTime> skippedDates,
  ) {
    int streak = 0;
    var d = DateTime(today.year, today.month, today.day);
    final start = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
    // 安全上限：最多回溯 3650 天（10 年），同时不能早于 startDate 前一年
    final earliest = start.subtract(const Duration(days: 365));
    final todayKey = DateTime(today.year, today.month, today.day);
    int guard = 0;
    while (guard++ < 3650) {
      if (!isTaskActiveOn(task, d)) {
        d = d.subtract(const Duration(days: 1));
        if (d.isBefore(earliest)) break;
        continue;
      }
      final key = DateTime(d.year, d.month, d.day);
      if (doneDates.contains(key)) {
        streak++;
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      if (skippedDates.contains(key)) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      // 今天还没打卡不算断签，跳过今天继续往前数
      if (key == todayKey) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      // 过去的应打卡日没做 → 连续中断
      break;
    }
    return streak;
  }

  static int _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  static Set<int> _parseWeekdays(String? s) {
    if (s == null || s.isEmpty) return {};
    return s
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e >= 1 && e <= 7)
        .toSet();
  }

  static Set<String> _parseCustomDays(String? s) {
    if (s == null || s.isEmpty) return {};
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  static bool _matchesSchedule(Task task, ScheduleType type, DateTime d) {
    switch (type) {
      case ScheduleType.once:
        return DateTime(d.year, d.month, d.day) ==
            DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
      case ScheduleType.daily:
        return true;
      case ScheduleType.weekly:
        return _parseWeekdays(task.weekdays).contains(d.weekday);
      case ScheduleType.monthly:
        final dom = task.dayOfMonth ?? 1;
        if (dom == -1) return d.day == _lastDayOfMonth(d);
        return d.day == dom;
      case ScheduleType.yearly:
        return d.month == (task.monthOfYear ?? 1) &&
            d.day == (task.dayOfMonthOfYear ?? 1);
      case ScheduleType.custom:
        final iso = '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
        return _parseCustomDays(task.customDays).contains(iso);
    }
  }
}
