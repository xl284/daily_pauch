import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/backup/backup_service.dart';
import '../../data/notifications/notification_service.dart';
import 'widgets/tag_manager.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasExactAlarm = false;

  @override
  void initState() {
    super.initState();
    _refreshAlarmStatus();
  }

  Future<void> _refreshAlarmStatus() async {
    final ok = await NotificationService.hasExactAlarmPermission();
    if (mounted) setState(() => _hasExactAlarm = ok);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('主题模式'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(themeModeProvider.notifier).set(v);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('导出备份'),
            subtitle: const Text('将所有任务和打卡记录导出为 JSON'),
            onTap: () => BackupService.exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入备份'),
            subtitle: const Text('从 JSON 文件恢复数据'),
            onTap: () => BackupService.importData(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('标签管理'),
            subtitle: const Text('管理任务分类标签'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TagManagerScreen()),
            ),
          ),
          ListTile(
            leading: Icon(_hasExactAlarm ? Icons.check_circle : Icons.notifications_active,
                color: _hasExactAlarm ? Colors.green : null),
            title: const Text('申请精确闹钟权限'),
            subtitle: Text(_hasExactAlarm ? '已授权，提醒可准时送达' : '确保提醒通知准时送达'),
            onTap: () async {
              final msg = await NotificationService.requestExactAlarmPermission();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                _refreshAlarmStatus();
              }
            },
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info),
            applicationName: '每日打卡',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2026',
          ),
        ],
      ),
    );
  }
}
