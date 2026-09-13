import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/app_database.dart';
import '../database/tables/tasks.dart';
import '../database/tables/check_ins.dart';
import '../database/tables/skips.dart';
import '../database/tables/tags.dart';
import '../database/tables/task_tags.dart';

class BackupService {
  static AppDatabase get _db => AppDatabase();

  static Future<void> exportData(BuildContext context) async {
    final db = _db;
    final tasks = await db.select(db.tasks).get();
    final checkIns = await db.select(db.checkIns).get();
    final skips = await db.select(db.skips).get();
    final tags = await db.select(db.tags).get();
    final taskTags = await db.select(db.taskTags).get();

    final json = {
      'schema_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'check_ins': checkIns.map((c) => c.toJson()).toList(),
      'skips': skips.map((s) => s.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'task_tags': taskTags.map((t) => t.toJson()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final ts = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}';
    final file = File('${dir.path}/daily_pauch_backup_$ts.json');
    await file.writeAsString(jsonEncode(json));

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: '打卡数据备份',
    );
  }

  static Future<void> importData(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    try {
      final json = jsonDecode(await file.readAsString());
      if (json['schema_version'] != 1) {
        throw '不支持的备份版本';
      }
      final db = _db;
      await db.transaction(() async {
        // 清空再导入
        await db.delete(db.checkIns).go();
        await db.delete(db.skips).go();
        await db.delete(db.taskTags).go();
        await db.delete(db.tasks).go();
        await db.delete(db.tags).go();

        for (final t in json['tasks']) {
          await db.into(db.tasks).insert(TasksCompanion(
            id: Value(t['id']),
            name: Value(t['name']),
            iconCode: Value(t['iconCode']),
            colorValue: Value(t['colorValue']),
            checkInMode: Value(t['checkInMode']),
            targetCount: Value(t['targetCount']),
            scheduleType: Value(t['scheduleType']),
            weekdays: Value(t['weekdays']),
            dayOfMonth: Value(t['dayOfMonth']),
            monthOfYear: Value(t['monthOfYear']),
            dayOfMonthOfYear: Value(t['dayOfMonthOfYear']),
            customDays: Value(t['customDays']),
            startDate: Value(DateTime.fromMillisecondsSinceEpoch(t['startDate'])),
            endDate: Value(t['endDate'] == null ? null : DateTime.fromMillisecondsSinceEpoch(t['endDate'])),
            reminderTimes: Value(t['reminderTimes']),
            enableReminder: Value(t['enableReminder']),
            sortOrder: Value(t['sortOrder']),
            createdAt: Value(DateTime.fromMillisecondsSinceEpoch(t['createdAt'])),
            updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(t['updatedAt'])),
            archivedAt: Value(t['archivedAt'] == null ? null : DateTime.fromMillisecondsSinceEpoch(t['archivedAt'])),
          ));
        }
        for (final c in json['check_ins']) {
          await db.into(db.checkIns).insert(CheckInsCompanion(
            id: Value(c['id']),
            taskId: Value(c['taskId']),
            checkInDate: Value(DateTime.fromMillisecondsSinceEpoch(c['checkInDate'])),
            seq: Value(c['seq']),
            timestamp: Value(DateTime.fromMillisecondsSinceEpoch(c['timestamp'])),
            note: Value(c['note']),
            mood: Value(c['mood']),
          ));
        }
        for (final s in json['skips']) {
          await db.into(db.skips).insert(SkipsCompanion(
            id: Value(s['id']),
            taskId: Value(s['taskId']),
            skipDate: Value(DateTime.fromMillisecondsSinceEpoch(s['skipDate'])),
            reason: Value(s['reason']),
            createdAt: Value(DateTime.fromMillisecondsSinceEpoch(s['createdAt'])),
          ));
        }
        for (final t in json['tags']) {
          await db.into(db.tags).insert(TagsCompanion(
            id: Value(t['id']),
            name: Value(t['name']),
            colorValue: Value(t['colorValue']),
            createdAt: Value(DateTime.fromMillisecondsSinceEpoch(t['createdAt'])),
          ));
        }
        for (final t in json['task_tags']) {
          await db.into(db.taskTags).insert(TaskTagsCompanion(
            id: Value(t['id']),
            taskId: Value(t['taskId']),
            tagId: Value(t['tagId']),
          ));
        }
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导入成功')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }
}
