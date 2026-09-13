import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tasks.dart';
import 'tables/check_ins.dart';
import 'tables/skips.dart';
import 'tables/tags.dart';
import 'tables/task_tags.dart';
import 'tables/app_meta.dart';
import 'daos/task_dao.dart';
import 'daos/check_in_dao.dart';
import 'daos/skip_dao.dart';
import 'daos/tag_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Tasks, CheckIns, Skips, Tags, TaskTags, AppMeta],
  daos: [TaskDao, CheckInDao, SkipDao, TagDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'daily_pauch.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
