import 'package:drift/drift.dart';
import '../tables/skips.dart';
import '../app_database.dart';

part 'skip_dao.g.dart';

@DriftAccessor(tables: [Skips])
class SkipDao extends DatabaseAccessor<AppDatabase> with _$SkipDaoMixin {
  SkipDao(super.attachedDatabase);

  Future<Skip?> getByTaskAndDate(int taskId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return (select(skips)
          ..where((s) => s.taskId.equals(taskId))
          ..where((s) => s.skipDate.equals(start)))
        .getSingleOrNull();
  }

  Stream<Skip?> watchByTaskAndDate(int taskId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return (select(skips)
          ..where((s) => s.taskId.equals(taskId))
          ..where((s) => s.skipDate.equals(start)))
        .watchSingleOrNull();
  }

  Future<int> countByTaskUpTo(int taskId, DateTime upTo) {
    final end = DateTime(upTo.year, upTo.month, upTo.day)
        .add(const Duration(days: 1));
    final count = skips.id.count();
    return (selectOnly(skips)
          ..addColumns([count])
          ..where(skips.taskId.equals(taskId))
          ..where(skips.skipDate.isSmallerThanValue(end)))
        .map((r) => r.read(count)!)
        .getSingle();
  }

  Future<List<Skip>> getAllByTaskId(int taskId) =>
      (select(skips)..where((s) => s.taskId.equals(taskId))).get();

  Future<int> insertSkip(SkipsCompanion skip) => into(skips).insert(skip);

  Future<int> deleteByTaskAndDate(int taskId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return (delete(skips)
          ..where((s) => s.taskId.equals(taskId))
          ..where((s) => s.skipDate.equals(start)))
        .go();
  }
}
