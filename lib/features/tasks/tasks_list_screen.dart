import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/task_providers.dart';
import '../../data/database/app_database.dart';
import 'widgets/icon_picker.dart';

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('任务管理')),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('出错了: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('暂无任务，点击右下角添加'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (_, i) {
              final task = tasks[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(task.colorValue).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TaskIcon(
                      iconCode: task.iconCode,
                      taskName: task.name,
                      color: Color(task.colorValue),
                      size: 22,
                    ),
                  ),
                  title: Text(task.name),
                  subtitle: Text(_scheduleLabel(task)),
                  trailing: task.archivedAt != null
                      ? const Icon(Icons.archive, size: 18)
                      : const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tasks/${task.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _scheduleLabel(Task task) {
    final mode = task.checkInMode == 'count' ? '次数型 ' : '';
    return '$mode${task.scheduleType}';
  }
}
