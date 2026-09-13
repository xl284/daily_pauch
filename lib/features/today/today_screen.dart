import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import '../../providers/today_providers.dart';
import '../../providers/check_in_providers.dart';
import '../../data/database/app_database.dart';
import 'widgets/heart_burst_animation.dart';
import '../tasks/widgets/icon_picker.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayDateProvider);
    final todayAsync = ref.watch(todayTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日打卡', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(
              DateFormat('yyyy年M月d日 EEEE', 'zh').format(today),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayDateProvider);
          ref.invalidate(todayTasksProvider);
          await ref.read(todayTasksProvider.future);
        },
        child: todayAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [Center(child: Text('出错了: $e'))],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [_EmptyState()],
              );
            }
            final pending = items.where((e) => e.isPending).toList();
            final done = items.where((e) => e.isDone).toList();
            final skipped = items.where((e) => e.isSkipped).toList();
            final notActive = items.where((e) => e.isNotActive).toList();
            final total = items.length;
            final doneCount = done.length + (skipped.isEmpty ? 0 : 0);
            final rate = total == 0 ? 0.0 : doneCount / total;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProgressHeader(rate: rate, done: doneCount, total: total),
                const SizedBox(height: 16),
                if (pending.isNotEmpty) ...[
                  _SectionTitle('待打卡 (${pending.length})'),
                  ...pending.map((e) => _TaskTile(state: e, ref: ref)),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionTitle('已完成 (${done.length})'),
                  ...done.map((e) => _TaskTile(state: e, ref: ref)),
                ],
                if (skipped.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionTitle('已跳过 (${skipped.length})'),
                  ...skipped.map((e) => _TaskTile(state: e, ref: ref)),
                ],
                if (notActive.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionTitle('今日不活跃 (${notActive.length})'),
                  ...notActive.map((e) => _TaskTile(state: e, ref: ref)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final double rate;
  final int done;
  final int total;
  const _ProgressHeader({required this.rate, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: rate,
                      strokeWidth: 6,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(scheme.primary),
                    ),
                  ),
                  Text('${(rate * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今日完成 $done / $total',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    rate >= 1 ? '全部完成，太棒了！' : '加油，继续打卡！',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              )),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('还没有打卡任务',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('去「任务」页面创建第一个任务吧',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskTodayState state;
  final WidgetRef ref;
  const _TaskTile({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    final scheme = Theme.of(context).colorScheme;
    final iconColor = Color(task.colorValue);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/tasks/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: TaskIcon(
                    iconCode: task.iconCode,
                    taskName: task.name,
                    color: iconColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: state.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                    const SizedBox(height: 2),
                    if (state.isCountMode)
                      LinearProgressIndicator(
                        value: state.targetCount == 0
                            ? 0
                            : (state.doneCount / state.targetCount).clamp(0.0, 1.0),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      state.isCountMode
                          ? '${state.doneCount} / ${state.targetCount}'
                          : state.status.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: state.isDone
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (state.isNotActive)
                const Icon(Icons.block, size: 20)
              else if (state.isDone)
                _UndoButton(state: state, ref: ref)
              else if (state.isSkipped)
                Icon(Icons.skip_next, color: scheme.outline, size: 28)
              else
                _CheckInButton(state: state, ref: ref),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInButton extends StatelessWidget {
  final TaskTodayState state;
  final WidgetRef ref;
  const _CheckInButton({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final today = DateTime.now();
        final checkInDate = DateTime(today.year, today.month, today.day);
        final checkInDao = ref.read(checkInDaoProvider);
        final existing = await checkInDao.getAllByTaskAndDate(task.id, today);
        final nextSeq = existing.length + 1;
        await checkInDao.insertCheckIn(CheckInsCompanion(
          taskId: Value(task.id),
          checkInDate: Value(checkInDate),
          seq: Value(nextSeq),
          timestamp: Value(today),
        ));
        // 爱心爆炸动画
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.localToGlobal(box.size.center(Offset.zero));
          showHeartBurst(context, pos, color: Color(task.colorValue));
        }
        ref.invalidate(todayTasksProvider);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(task.colorValue),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 22),
      ),
    );
  }
}

class _UndoButton extends StatelessWidget {
  final TaskTodayState state;
  final WidgetRef ref;
  const _UndoButton({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final task = state.task;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final today = DateTime.now();
        final checkInDao = ref.read(checkInDaoProvider);
        final existing = await checkInDao.getAllByTaskAndDate(task.id, today);
        if (existing.isEmpty) return;
        // 次数型只删最后一次，单次型删唯一一次
        await checkInDao.deleteCheckIn(existing.last.id);
        ref.invalidate(todayTasksProvider);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Color(task.colorValue).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.undo, color: Colors.grey, size: 20),
      ),
    );
  }
}
