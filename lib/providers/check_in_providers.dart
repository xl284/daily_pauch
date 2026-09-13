import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/check_in_dao.dart';
import '../data/database/daos/skip_dao.dart';
import 'database_provider.dart';

final checkInDaoProvider = Provider<CheckInDao>((ref) {
  return ref.watch(databaseProvider).checkInDao;
});

final skipDaoProvider = Provider<SkipDao>((ref) {
  return ref.watch(databaseProvider).skipDao;
});

/// 某任务某日的打卡记录列表（次数型可能有多条）
final checkInsForTaskDateProvider =
    FutureProvider.autoDispose.family<List<CheckIn>, (int, DateTime)>((ref, args) {
  return ref.watch(checkInDaoProvider).getAllByTaskAndDate(args.$1, args.$2);
});

/// 某任务某日的跳过记录
final skipForTaskDateProvider =
    FutureProvider.autoDispose.family<Skip?, (int, DateTime)>((ref, args) {
  return ref.watch(skipDaoProvider).getByTaskAndDate(args.$1, args.$2);
});
