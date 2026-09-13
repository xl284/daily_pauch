import 'package:drift/drift.dart';
import 'tasks.dart';

@DataClassName('Skip')
class Skips extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get skipDate => dateTime()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {taskId, skipDate},
      ];
}
