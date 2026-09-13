import 'package:drift/drift.dart';
import 'tasks.dart';
import 'tags.dart';

@DataClassName('TaskTag')
class TaskTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {taskId, tagId},
      ];
}
