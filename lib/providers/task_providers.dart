import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/task_dao.dart';
import 'database_provider.dart';

final taskDaoProvider = Provider<TaskDao>((ref) {
  return ref.watch(databaseProvider).taskDao;
});

final activeTasksStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).watchAllActive();
});

final allTasksStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(databaseProvider).select(ref.watch(databaseProvider).tasks).watch();
});

final taskByIdProvider = FutureProvider.family<Task?, int>((ref, id) {
  return ref.watch(taskDaoProvider).getById(id);
});
