import 'package:drift/drift.dart';
import '../tables/check_ins.dart';
import '../tables/tasks.dart';
import '../app_database.dart';

part 'check_in_dao.g.dart';

@DriftAccessor(tables: [CheckIns, Tasks])
class CheckInDao extends DatabaseAccessor<AppDatabase> with _$CheckInDaoMixin {
  CheckInDao(super.attachedDatabase);

  Future<List<CheckIn>> getByTaskId(int taskId) =>
      (select(checkIns)..where((c) => c.taskId.equals(taskId))).get();

  Stream<List<CheckIn>> watchByTaskId(int taskId) =>
      (select(checkIns)..where((c) => c.taskId.equals(taskId))).watch();

  Future<CheckIn?> getByTaskAndDate(int taskId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(checkIns)
          ..where((c) => c.taskId.equals(taskId))
          ..where((c) =>
              c.checkInDate.isBiggerOrEqualValue(start) &
              c.checkInDate.isSmallerThanValue(end))
          ..orderBy([(c) => OrderingTerm.asc(c.seq)]))
        .getSingleOrNull();
  }

  Future<List<CheckIn>> getAllByTaskAndDate(int taskId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(checkIns)
          ..where((c) => c.taskId.equals(taskId))
          ..where((c) =>
              c.checkInDate.isBiggerOrEqualValue(start) &
              c.checkInDate.isSmallerThanValue(end))
          ..orderBy([(c) => OrderingTerm.asc(c.seq)]))
        .get();
  }

  Future<int> countByTaskUpTo(int taskId, DateTime upTo) {
    final end = DateTime(upTo.year, upTo.month, upTo.day)
        .add(const Duration(days: 1));
    final count = checkIns.id.count();
    return (selectOnly(checkIns)
          ..addColumns([count])
          ..where(checkIns.taskId.equals(taskId))
          ..where(checkIns.checkInDate.isSmallerThanValue(end)))
        .map((r) => r.read(count)!)
        .getSingle();
  }

  Future<int> insertCheckIn(CheckInsCompanion checkIn) =>
      into(checkIns).insert(checkIn);

  Future<int> deleteCheckIn(int id) =>
      (delete(checkIns)..where((c) => c.id.equals(id))).go();

  Future<int> deleteByTaskAndDate(int taskId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (delete(checkIns)
          ..where((c) => c.taskId.equals(taskId))
          ..where((c) =>
              c.checkInDate.isBiggerOrEqualValue(start) &
              c.checkInDate.isSmallerThanValue(end)))
        .go();
  }

  Future<int> deleteLastByTaskAndDate(int taskId, DateTime date) async {
    final list = await getAllByTaskAndDate(taskId, date);
    if (list.isEmpty) return 0;
    return await deleteCheckIn(list.last.id);
  }
}
