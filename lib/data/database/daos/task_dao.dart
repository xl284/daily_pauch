import 'package:drift/drift.dart';
import '../tables/tasks.dart';
import '../tables/check_ins.dart';
import '../tables/skips.dart';
import '../tables/task_tags.dart';
import '../app_database.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks, CheckIns, Skips, TaskTags])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.attachedDatabase);

  Future<List<Task>> getAllActive({int? tagId}) {
    final query = select(tasks)
      ..where((t) => t.archivedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.get();
  }

  Future<List<Task>> getAll() =>
      (select(tasks)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Stream<List<Task>> watchAllActive() {
    return (select(tasks)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<Task?> getById(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Task?> watchById(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);

  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// 级联删除：任务 + 其所有打卡记录 + 跳过记录 + 标签关联
  Future<void> deleteTaskCascade(int id) async {
    await transaction(() async {
      await (delete(taskTags)..where((t) => t.taskId.equals(id))).go();
      await (delete(checkIns)..where((c) => c.taskId.equals(id))).go();
      await (delete(skips)..where((s) => s.taskId.equals(id))).go();
      await (delete(tasks)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> archiveTask(int id) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(archivedAt: Value(DateTime.now())));

  Future<void> unarchiveTask(int id) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(const TasksCompanion(archivedAt: Value(null)));
}
