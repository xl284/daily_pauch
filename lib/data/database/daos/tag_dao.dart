import 'package:drift/drift.dart';
import '../tables/tags.dart';
import '../tables/task_tags.dart';
import '../app_database.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags, TaskTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.attachedDatabase);

  Future<List<Tag>> getAll() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Stream<List<Tag>> watchAll() =>
      (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<Tag?> getById(int id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTag(TagsCompanion tag) => into(tags).insert(tag);

  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  Future<List<Tag>> getTagsForTask(int taskId) {
    return (select(tags).join([
      innerJoin(taskTags, taskTags.tagId.equalsExp(tags.id)),
    ])
          ..where(taskTags.taskId.equals(taskId))
          ..orderBy([OrderingTerm.asc(tags.name)]))
        .map((r) => r.readTable(tags))
        .get();
  }

  Stream<List<Tag>> watchTagsForTask(int taskId) {
    return (select(tags).join([
      innerJoin(taskTags, taskTags.tagId.equalsExp(tags.id)),
    ])
          ..where(taskTags.taskId.equals(taskId))
          ..orderBy([OrderingTerm.asc(tags.name)]))
        .map((r) => r.readTable(tags))
        .watch();
  }

  Future<void> setTagsForTask(int taskId, List<int> tagIds) async {
    await (delete(taskTags)..where((t) => t.taskId.equals(taskId))).go();
    for (final tagId in tagIds) {
      await into(taskTags)
          .insert(TaskTagsCompanion(taskId: Value(taskId), tagId: Value(tagId)));
    }
  }
}
