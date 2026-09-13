import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../domain/models/task_status.dart';
import '../domain/schedule/schedule_engine.dart';
import 'task_providers.dart';
import 'check_in_providers.dart';

class TaskTodayState {
  final Task task;
  final TaskStatus status;
  final int doneCount;
  final int targetCount;
  final bool isCountMode;

  const TaskTodayState({
    required this.task,
    required this.status,
    required this.doneCount,
    required this.targetCount,
    required this.isCountMode,
  });

  bool get isDone => status == TaskStatus.done;
  bool get isPending => status == TaskStatus.pending;
  bool get isSkipped => status == TaskStatus.skipped;
  bool get isNotActive => status == TaskStatus.notActive;
}

final todayDateProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final todayTasksProvider = FutureProvider.autoDispose<List<TaskTodayState>>((ref) async {
  final today = ref.watch(todayDateProvider);
  final tasks = await ref.watch(activeTasksStreamProvider.future);
  final checkInDao = ref.watch(checkInDaoProvider);
  final skipDao = ref.watch(skipDaoProvider);

  final List<TaskTodayState> result = [];
  for (final task in tasks) {
    final isActive = ScheduleEngine.isTaskActiveOn(task, today);
    if (!isActive) {
      result.add(TaskTodayState(
        task: task,
        status: TaskStatus.notActive,
        doneCount: 0,
        targetCount: task.targetCount,
        isCountMode: task.checkInMode == 'count',
      ));
      continue;
    }
    final checkIns = await checkInDao.getAllByTaskAndDate(task.id, today);
    final skip = await skipDao.getByTaskAndDate(task.id, today);
    final doneCount = checkIns.length;
    final isCountMode = task.checkInMode == 'count';
    final target = task.targetCount;

    TaskStatus status;
    if (skip != null) {
      status = TaskStatus.skipped;
    } else if (isCountMode) {
      status = doneCount >= target ? TaskStatus.done : TaskStatus.pending;
    } else {
      status = doneCount > 0 ? TaskStatus.done : TaskStatus.pending;
    }
    result.add(TaskTodayState(
      task: task,
      status: status,
      doneCount: doneCount,
      targetCount: target,
      isCountMode: isCountMode,
    ));
  }
  return result;
});
