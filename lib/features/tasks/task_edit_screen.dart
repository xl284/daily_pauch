import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import '../../providers/task_providers.dart';
import '../../providers/tag_providers.dart';
import '../../providers/database_provider.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/schedule_type.dart';
import '../../domain/models/check_in_mode.dart';
import '../../data/notifications/notification_service.dart';
import 'widgets/icon_picker.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  final int? taskId;
  const TaskEditScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  CheckInMode _mode = CheckInMode.single;
  int _targetCount = 1;
  ScheduleType _schedule = ScheduleType.daily;
  Set<int> _weekdays = {1, 2, 3, 4, 5};
  int _dayOfMonth = 1;
  int _monthOfYear = 1;
  int _dayOfMonthOfYear = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<TimeOfDay> _reminders = [const TimeOfDay(hour: 8, minute: 0)];
  bool _enableReminder = true;
  int _colorValue = 0xFF4B3FE3;
  String _iconCode = '0xe85d';
  Set<int> _selectedTagIds = {};

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      _isEditing = true;
      _loadTask();
    }
  }

  Future<void> _loadTask() async {
    final task = await ref.read(taskByIdProvider(widget.taskId!).future);
    if (task == null) return;
    setState(() {
      _nameCtrl.text = task.name;
      _mode = CheckInMode.fromString(task.checkInMode);
      _targetCount = task.targetCount;
      _schedule = ScheduleType.fromString(task.scheduleType);
      _weekdays = (task.weekdays ?? '')
          .split(',')
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .toSet();
      _dayOfMonth = task.dayOfMonth ?? 1;
      _monthOfYear = task.monthOfYear ?? 1;
      _dayOfMonthOfYear = task.dayOfMonthOfYear ?? 1;
      _startDate = task.startDate;
      _endDate = task.endDate;
      _enableReminder = task.enableReminder;
      _colorValue = task.colorValue;
      _iconCode = task.iconCode;
    });
    _reminders = _parseReminders(task.reminderTimes);
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(allTagsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑任务' : '新建任务'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '任务名称'),
              validator: (v) => (v == null || v.isEmpty) ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),
            // 图标 + 颜色
            Row(
              children: [
                IconButton(
                  icon: TaskIcon(
                    iconCode: _iconCode,
                    taskName: _nameCtrl.text,
                    color: Color(_colorValue),
                    size: 32,
                  ),
                  onPressed: _pickIcon,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickColor,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(_colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 打卡模式
            const Text('打卡模式', style: TextStyle(fontWeight: FontWeight.bold)),
            SegmentedButton<CheckInMode>(
              segments: const [
                ButtonSegment(value: CheckInMode.single, label: Text('单次')),
                ButtonSegment(value: CheckInMode.count, label: Text('次数')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            if (_mode == CheckInMode.count) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('每日目标次数：'),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => setState(() =>
                        _targetCount = _targetCount > 1 ? _targetCount - 1 : 1),
                  ),
                  Text('$_targetCount'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        setState(() => _targetCount = _targetCount + 1),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // 周期类型
            const Text('重复周期', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: ScheduleType.values.map((t) {
                return ChoiceChip(
                  label: Text(t.label),
                  selected: _schedule == t,
                  onSelected: (_) => setState(() => _schedule = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (_schedule == ScheduleType.weekly)
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final names = ['一', '二', '三', '四', '五', '六', '日'];
                  return FilterChip(
                    label: Text('周${names[i]}'),
                    selected: _weekdays.contains(day),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _weekdays.add(day);
                      } else {
                        _weekdays.remove(day);
                      }
                    }),
                  );
                }),
              ),
            if (_schedule == ScheduleType.monthly)
              DropdownButton<int>(
                value: _dayOfMonth,
                items: List.generate(31, (i) => i + 1)
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d 日')))
                    .toList()
                  ..add(const DropdownMenuItem(value: -1, child: Text('月末'))),
                onChanged: (v) => setState(() => _dayOfMonth = v ?? 1),
              ),
            if (_schedule == ScheduleType.yearly)
              Row(
                children: [
                  DropdownButton<int>(
                    value: _monthOfYear,
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m 月')))
                        .toList(),
                    onChanged: (v) => setState(() => _monthOfYear = v ?? 1),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _dayOfMonthOfYear,
                    items: List.generate(31, (i) => i + 1)
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d 日')))
                        .toList(),
                    onChanged: (v) => setState(() => _dayOfMonthOfYear = v ?? 1),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // 起止日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('开始日期'),
              subtitle: Text(_fmt(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('长期有效'),
              value: _endDate == null,
              onChanged: (v) => setState(() => _endDate = v ? null : DateTime.now()),
            ),
            if (_endDate != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('截止日期'),
                subtitle: Text(_fmt(_endDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _endDate!,
                    firstDate: _startDate,
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _endDate = d);
                },
              ),
            const SizedBox(height: 16),
            // 提醒
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('开启提醒'),
              value: _enableReminder,
              onChanged: (v) => setState(() => _enableReminder = v),
            ),
            if (_enableReminder) ...[
              Wrap(
                spacing: 8,
                children: [
                  ..._reminders.map((t) => Chip(
                        label: Text(t.format(context)),
                        onDeleted: () => setState(() => _reminders.remove(t)),
                      )),
                  ActionChip(
                    label: const Text('+ 添加'),
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 8, minute: 0),
                      );
                      if (t != null) setState(() => _reminders.add(t));
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // 标签
            tagsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (tags) {
                if (tags.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('标签', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: tags.map((tag) {
                        return FilterChip(
                          label: Text(tag.name),
                          selected: _selectedTagIds.contains(tag.id),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _selectedTagIds.add(tag.id);
                            } else {
                              _selectedTagIds.remove(tag.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_schedule == ScheduleType.weekly && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请至少选择一天')));
      return;
    }
    final now = DateTime.now();
    final companion = TasksCompanion(
      name: Value(_nameCtrl.text),
      iconCode: Value(_iconCode),
      colorValue: Value(_colorValue),
      checkInMode: Value(_mode.name),
      targetCount: Value(_mode == CheckInMode.count ? _targetCount : 1),
      scheduleType: Value(_schedule.name),
      weekdays: Value(_schedule == ScheduleType.weekly
          ? _weekdays.toList().join(',')
          : null),
      dayOfMonth: Value(_schedule == ScheduleType.monthly ? _dayOfMonth : null),
      monthOfYear: Value(_schedule == ScheduleType.yearly ? _monthOfYear : null),
      dayOfMonthOfYear:
          Value(_schedule == ScheduleType.yearly ? _dayOfMonthOfYear : null),
      startDate: Value(_startDate),
      endDate: Value(_endDate),
      reminderTimes: Value(_serializeReminders()),
      enableReminder: Value(_enableReminder),
      updatedAt: Value(now),
    );
    final db = ref.read(databaseProvider);
    final taskDao = db.taskDao;
    int taskId;
    if (_isEditing) {
      await taskDao.updateTask(companion.copyWith(id: Value(widget.taskId!)));
      taskId = widget.taskId!;
    } else {
      taskId = await taskDao.insertTask(companion);
    }
    // 标签
    if (_selectedTagIds.isNotEmpty) {
      await db.tagDao.setTagsForTask(taskId, _selectedTagIds.toList());
    }
    // 通知
    final task = await taskDao.getById(taskId);
    if (task != null) {
      await NotificationService.scheduleTaskReminders(task);
    }
    ref.invalidate(activeTasksStreamProvider);
    ref.invalidate(allTasksStreamProvider);
    if (mounted) context.pop();
  }

  void _pickIcon() async {
    final result = await IconPicker.show(
      context,
      currentCode: _iconCode,
      taskName: _nameCtrl.text,
    );
    if (result != null) setState(() => _iconCode = result);
  }

  void _pickColor() async {
    final colors = <int>[
      0xFF4B3FE3, 0xFFFF3B5C, 0xFFFF9500, 0xFF34C759,
      0xFF007AFF, 0xFFAF52DE, 0xFFFF2D55, 0xFF8E8E93,
    ];
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('选择颜色'),
        content: Wrap(
          spacing: 16,
          children: colors
              .map((c) => GestureDetector(
                    onTap: () => Navigator.pop(context, c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (result != null) setState(() => _colorValue = result);
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _serializeReminders() {
    return '[${_reminders.map((t) => '{"h":${t.hour},"m":${t.minute}}').join(',')}]';
  }

  List<TimeOfDay> _parseReminders(String json) {
    try {
      final clean = json.replaceAll(RegExp(r'[\[\]\s]'), '');
      if (clean.isEmpty) return [];
      return clean.split('},{').map((p) {
        final h = RegExp(r'"h":(\d+)').firstMatch(p)?.group(1);
        final m = RegExp(r'"m":(\d+)').firstMatch(p)?.group(1);
        return TimeOfDay(hour: int.parse(h ?? '8'), minute: int.parse(m ?? '0'));
      }).toList();
    } catch (_) {
      return [const TimeOfDay(hour: 8, minute: 0)];
    }
  }
}
