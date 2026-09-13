// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skip_dao.dart';

// ignore_for_file: type=lint
mixin _$SkipDaoMixin on DatabaseAccessor<AppDatabase> {
  $TasksTable get tasks => attachedDatabase.tasks;
  $SkipsTable get skips => attachedDatabase.skips;
  SkipDaoManager get managers => SkipDaoManager(this);
}

class SkipDaoManager {
  final _$SkipDaoMixin _db;
  SkipDaoManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$SkipsTableTableManager get skips =>
      $$SkipsTableTableManager(_db.attachedDatabase, _db.skips);
}
