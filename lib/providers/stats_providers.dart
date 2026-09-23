import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/task_stats.dart';
import '../domain/schedule/schedule_engine.dart';
import 'task_providers.dart';
import 'check_in_providers.dart';

/// 所有活跃任务的打卡率（含任务名），一次性聚合，避免 widget build 里循环 watch。
/// 返回 List<(taskId, taskName, rate)>。
final allTaskRatesProvider = FutureProvider<List<(int, String, double)>>((ref) async {
  final tasks = await ref.watch(activeTasksStreamProvider.future);
  final checkInDao = ref.read(checkInDaoProvider);
  final skipDao = ref.read(skipDaoProvider);
  final today = DateTime.now();
  final List<(int, String, double)> result = [];
  for (final task in tasks) {
    final due = ScheduleEngine.dueCount(task, today);
    final done = await checkInDao.countByTaskUpTo(task.id, today);
    final skipped = await skipDao.countByTaskUpTo(task.id, today);
    final effectiveDue = due - skipped;
    final rate = effectiveDue == 0 ? 1.0 : (done / effectiveDue).clamp(0.0, 1.0);
    result.add((task.id, task.name, rate));
  }
  return result;
});

/// 单个任务的统计（非 autoDispose，详情页频繁进出不会重建）
final taskStatsProvider = FutureProvider.family<TaskStats, int>((ref, taskId) async {
  final task = await ref.read(taskDaoProvider).getById(taskId);
  if (task == null) return TaskStats.empty;

  final checkInDao = ref.read(checkInDaoProvider);
  final skipDao = ref.read(skipDaoProvider);
  final today = DateTime.now();

  final due = ScheduleEngine.dueCount(task, today);
  final done = await checkInDao.countByTaskUpTo(taskId, today);
  final skipped = await skipDao.countByTaskUpTo(taskId, today);

  final allCheckIns = await checkInDao.getByTaskId(taskId);
  final doneDates = allCheckIns
      .map((c) => DateTime(c.checkInDate.year, c.checkInDate.month, c.checkInDate.day))
      .toSet();
  final skips = await skipDao.getAllByTaskId(taskId);
  final skippedDates = skips
      .map((s) => DateTime(s.skipDate.year, s.skipDate.month, s.skipDate.day))
      .toSet();

  final streak = ScheduleEngine.currentStreak(task, today, doneDates, skippedDates);
  final longestStreak =
      ScheduleEngine.longestStreak(task, today, doneDates, skippedDates);

  final effectiveDue = due - skipped;
  final rate = effectiveDue == 0 ? 1.0 : (done / effectiveDue).clamp(0.0, 1.0);

  return TaskStats(
    due: due,
    done: done,
    skipped: skipped,
    rate: rate,
    streak: streak,
    longestStreak: longestStreak,
  );
});

/// 近 [days] 天的每日总完成数（用于趋势折线图）
final trendProvider = FutureProvider.family<List<(DateTime, int, int)>, int>((ref, days) async {
  final today = DateTime.now();
  final tasks = await ref.watch(activeTasksStreamProvider.future);
  final checkInDao = ref.read(checkInDaoProvider);
  final List<(DateTime, int, int)> data = [];
  for (int i = days - 1; i >= 0; i--) {
    final d = today.subtract(Duration(days: i));
    int totalDue = 0;
    int totalDone = 0;
    for (final task in tasks) {
      if (ScheduleEngine.isTaskActiveOn(task, d)) {
        totalDue += task.targetCount;
        final cs = await checkInDao.getAllByTaskAndDate(task.id, d);
        totalDone += cs.length.clamp(0, task.targetCount);
      }
    }
    data.add((DateTime(d.year, d.month, d.day), totalDue, totalDone));
  }
  return data;
});
