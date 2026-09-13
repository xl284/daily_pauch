import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/tag_dao.dart';
import 'database_provider.dart';

final tagDaoProvider = Provider<TagDao>((ref) {
  return ref.watch(databaseProvider).tagDao;
});

final allTagsStreamProvider = StreamProvider.autoDispose<List<Tag>>((ref) {
  return ref.watch(tagDaoProvider).watchAll();
});

final tagsForTaskStreamProvider =
    StreamProvider.autoDispose.family<List<Tag>, int>((ref, taskId) {
  return ref.watch(tagDaoProvider).watchTagsForTask(taskId);
});
