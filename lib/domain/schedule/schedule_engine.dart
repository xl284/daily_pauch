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
    final todayKey = DateTime(today.year, today.month, today.day);
    // 安全上限：最多回溯 3650 天（10 年）
    int guard = 0;
    while (guard++ < 3650) {
      final key = DateTime(d.year, d.month, d.day);
      final hasCheckIn = doneDates.contains(key);
      final hasSkip = skippedDates.contains(key);
      final isActive = isTaskActiveOn(task, d);

      if (hasCheckIn) {
        // 有打卡 → 连续 +1（即使是非活跃日/startDate 之前的补打卡也算）
        streak++;
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      if (!isActive) {
        // 非活跃日且没打卡 → 跳过，不断签（如 weekly 任务的非打卡日、startDate 之前的日子）
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      if (hasSkip) {
        // 活跃日 + 跳过 → 跳过，不断签
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      // 活跃日 + 没打卡 + 没跳过
      if (key == todayKey) {
        // 今天还没打卡不算断签，跳过今天继续往前数
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      // 过去的活跃日没做 → 连续中断
      break;
    }
    return streak;
  }

  /// 历史最长连续打卡天数（从 startDate 正向遍历到 today，取连续区间的最大值）。
  ///
  /// 连续判定规则与 [currentStreak] 一致：
  /// - 有打卡 → 当前连续 +1
  /// - 非活跃日且没打卡 → 跳过，不中断（如 weekly 的非打卡日）
  /// - 活跃日 + 跳过 → 跳过，不中断
  /// - 活跃日 + 没打卡 + 没跳过 + 不是今天 → 连续中断
  static int longestStreak(
    Task task,
    DateTime today,
    Set<DateTime> doneDates,
    Set<DateTime> skippedDates,
  ) {
    final start = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
    final todayKey = DateTime(today.year, today.month, today.day);
    int maxStreak = 0;
    int current = 0;
    var d = start;
    while (!d.isAfter(todayKey)) {
      final key = DateTime(d.year, d.month, d.day);
      final hasCheckIn = doneDates.contains(key);
      final hasSkip = skippedDates.contains(key);
      final isActive = isTaskActiveOn(task, d);

      if (hasCheckIn) {
        current++;
        if (current > maxStreak) maxStreak = current;
      } else if (!isActive || hasSkip || key == todayKey) {
        // 非活跃日 / 跳过 / 今天还没打卡 → 不中断，保持当前连续计数
      } else {
        // 活跃日 + 没打卡 + 没跳过 → 连续中断
        current = 0;
      }
      d = d.add(const Duration(days: 1));
    }
    return maxStreak;
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
