import 'package:drift/drift.dart';
import 'tasks.dart';

@DataClassName('CheckIn')
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get checkInDate => dateTime()();
  IntColumn get seq => integer().withDefault(const Constant(1))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
  IntColumn get mood => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {taskId, checkInDate, seq},
      ];
}
