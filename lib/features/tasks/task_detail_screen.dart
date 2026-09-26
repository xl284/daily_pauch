import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:drift/drift.dart' hide Column;
import '../../providers/task_providers.dart';
import '../../providers/check_in_providers.dart';
import '../../providers/stats_providers.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/task_stats.dart';
import 'widgets/icon_picker.dart';

class TaskDetailScreen extends ConsumerWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskByIdProvider(taskId));
    final statsAsync = ref.watch(taskStatsProvider(taskId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '编辑',
            onPressed: () => context.push('/tasks/$taskId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: '删除',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('出错了: $e')),
        data: (task) {
          if (task == null) return const Center(child: Text('任务不存在'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TaskHeader(task: task),
              const SizedBox(height: 16),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => _StatsCard(stats: stats),
              ),
              const SizedBox(height: 16),
              const Text('打卡日历',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _HeatmapCalendar(taskId: taskId),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    bool clearHistory = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('删除任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('确定删除此任务吗？'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: const Text('同时清空历史打卡数据',
                        style: TextStyle(fontSize: 14)),
                  ),
                  Switch(
                    value: clearHistory,
                    onChanged: (v) => setDialogState(() => clearHistory = v),
                  ),
                ],
              ),
              if (!clearHistory)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '任务将被归档，历史打卡记录会保留在统计中',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(clearHistory ? '彻底删除' : '归档',
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final taskDao = ref.read(taskDaoProvider);
    if (clearHistory) {
      await taskDao.deleteTaskCascade(taskId);
    } else {
      await taskDao.archiveTask(taskId);
    }
    if (context.mounted) {
      context.go('/tasks');
    }
  }
}

class _TaskHeader extends StatelessWidget {
  final Task task;
  const _TaskHeader({required this.task});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Color(task.colorValue).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TaskIcon(
            iconCode: task.iconCode,
            taskName: task.name,
            color: Color(task.colorValue),
            size: 32,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.name,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${task.checkInMode == 'count' ? '次数型 (目标 ${task.targetCount})' : '单次打卡'} · ${task.scheduleType}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final TaskStats stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: '应打卡', value: '${stats.due}'),
                _StatItem(label: '已打卡', value: '${stats.done}'),
                _StatItem(label: '已跳过', value: '${stats.skipped}'),
                _StatItem(label: '连续', value: '${stats.streak} 天'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stats.rate,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('打卡率 ${(stats.rate * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('历史最长连续 ${stats.longestStreak} 天',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HeatmapCalendar extends ConsumerStatefulWidget {
  final int taskId;
  const _HeatmapCalendar({required this.taskId});

  @override
  ConsumerState<_HeatmapCalendar> createState() => _HeatmapCalendarState();
}

class _HeatmapCalendarState extends ConsumerState<_HeatmapCalendar> {
  DateTime _focused = DateTime.now();
  Map<DateTime, int> _counts = {};
  DateTime? _selectedDay;

  static const int _makeUpWindowDays = 7;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focused);
  }

  Future<void> _loadMonth(DateTime month) async {
    final dao = ref.read(checkInDaoProvider);
    final all = await dao.getByTaskId(widget.taskId);
    final map = <DateTime, int>{};
    for (final c in all) {
      final key = DateTime(c.checkInDate.year, c.checkInDate.month, c.checkInDate.day);
      map[key] = (map[key] ?? 0) + 1;
    }
    if (mounted) setState(() => _counts = map);
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskByIdProvider(widget.taskId)).value;
    final target = task?.targetCount ?? 1;
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: _focused,
          selectedDayPredicate: (d) => _selectedDay != null && isSameDay(_selectedDay, d),
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: '月'},
          onDaySelected: _onDaySelected,
          onPageChanged: (d) {
            setState(() => _focused = d);
            _loadMonth(d);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) => _cell(day, target),
            todayBuilder: (context, day, _) => _cell(day, target, isToday: true),
            selectedBuilder: (context, day, _) => _cell(day, target, isSelected: true),
          ),
        ),
        const SizedBox(height: 4),
        Text('点击 7 天内的日期可补打卡或取消打卡',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                )),
      ],
    );
  }

  Future<void> _onDaySelected(DateTime selected, DateTime focused) async {
    setState(() {
      _selectedDay = selected;
      _focused = focused;
    });
    final key = DateTime(selected.year, selected.month, selected.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = today.subtract(const Duration(days: _makeUpWindowDays));

    if (key.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('不能给未来日期打卡')),
      );
      return;
    }

    final count = _counts[key] ?? 0;
    if (count > 0) {
      // 有打卡记录，直接查看（不受 7 天限制）
      await _showCheckInsDialog(key);
    } else if (key.isBefore(earliest)) {
      // 无打卡记录且超出补打卡窗口
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('只能补打卡 $_makeUpWindowDays 天内的记录')),
      );
    } else {
      // 无打卡记录且在补打卡窗口内
      await _showMakeUpDialog(key);
    }
  }

  Future<void> _showMakeUpDialog(DateTime date) async {
    final task = ref.read(taskByIdProvider(widget.taskId)).value;
    if (task == null) return;
    final label = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('补打卡'),
        content: Text('确定为 $label 补打卡吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认打卡'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final dao = ref.read(checkInDaoProvider);
    final existing = await dao.getAllByTaskAndDate(widget.taskId, date);
    await dao.insertCheckIn(CheckInsCompanion(
      taskId: Value(widget.taskId),
      checkInDate: Value(date),
      seq: Value(existing.length + 1),
      timestamp: Value(DateTime.now()),
    ));
    await _loadMonth(_focused);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已为 $label 补打卡')),
      );
    }
  }

  Future<void> _showCheckInsDialog(DateTime date) async {
    final dao = ref.read(checkInDaoProvider);
    final checkIns = await dao.getAllByTaskAndDate(widget.taskId, date);
    final label = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$label 的打卡记录 (${checkIns.length})',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (checkIns.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('无打卡记录'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: checkIns.length,
                  itemBuilder: (_, i) {
                    final c = checkIns[i];
                    final time = '${c.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${c.timestamp.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text('${c.seq}'),
                      ),
                      title: Text('第 ${c.seq} 次打卡'),
                      subtitle: Text('打卡时间: $time'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await dao.deleteCheckIn(c.id);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          await _loadMonth(_focused);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(DateTime day, int target, {bool isToday = false, bool isSelected = false}) {
    final key = DateTime(day.year, day.month, day.day);
    final count = _counts[key] ?? 0;
    Color color;
    if (count == 0) {
      color = Colors.transparent;
    } else if (count >= target) {
      color = Colors.green.withValues(alpha: 0.8);
    } else {
      color = Colors.orange.withValues(alpha: 0.5 + 0.3 * (count / target));
    }
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
            : isToday
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
      ),
      child: Center(child: Text('${day.day}')),
    );
  }
}
