import 'package:drift/drift.dart';

@DataClassName('Task')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconCode => text().withDefault(const Constant('0xe85d'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF4B3FE3))();
  TextColumn get checkInMode => text().withDefault(const Constant('single'))();
  IntColumn get targetCount => integer().withDefault(const Constant(1))();
  TextColumn get scheduleType => text().withDefault(const Constant('daily'))();
  TextColumn get weekdays => text().nullable()();
  IntColumn get dayOfMonth => integer().nullable()();
  IntColumn get monthOfYear => integer().nullable()();
  IntColumn get dayOfMonthOfYear => integer().nullable()();
  TextColumn get customDays => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get reminderTimes => text().withDefault(const Constant('[]'))();
  BoolColumn get enableReminder => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
