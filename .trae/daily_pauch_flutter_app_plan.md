# 每日打卡 App（daily_pauch）实现计划

## Context

在空目录 `e:\Code\my_project\daily_pauch` 从零开发一个 Android 打卡 App。核心需求：

1. 用户创建一个或多个打卡任务，支持**单次打卡**和**次数型打卡**（如每日喝水8杯）两种模型
2. 每个任务可设置一个或多个提示时间，到点未完成则弹手机系统通知
3. 任务周期类型：单次/每日/每周/每月/每年/自定义多日，长期有效或截止某日
4. 今日首页按"待打卡/已完成/已跳过/今日不活跃"分组，可见周期内任务状态
5. 统计页含**打卡率 + 连续打卡天数 + 月度热力图 + 近 30/90 天趋势折线**
6. 打卡完成时播放**抖音点赞式爱心爆炸动画**
7. 任务支持**多对多标签**，可按标签筛选

技术栈：**Flutter**（用户主动选定，接受学习成本）。存储：本地 SQLite + JSON 导出/导入备份。交付：可安装到 Android 的 release APK。

## 环境现状（已验证）

| 项 | 状态 |
|---|---|
| Java | 1.8.0_503（**不满足** Gradle/Flutter 要求的 JDK 17+） |
| Node | v24.15.0 ✓ |
| Flutter SDK | 未装 |
| Android Studio / SDK | 未装 |
| `JAVA_HOME` / `ANDROID_HOME` | 均未配置 |
| 项目目录 | 空 |

## 关键架构决策

| 决策 | 选型 | 理由 |
|---|---|---|
| 状态管理 | Riverpod 2.x + `@riverpod` codegen | 编译时安全、不依赖 BuildContext、与 Drift Stream 无缝接 |
| 数据库 | Drift（基于 SQLite） | 关系型天然适配打卡域 + 日期范围查询；类型安全 codegen；JSON 备份直接 |
| 路由 | go_router | 官方推荐，支持 deep link（通知点击跳转） |
| 通知 | flutter_local_notifications 22.x | 自带 `alarmClock` 调度，不必叠加 alarm_manager |
| 精确闹钟权限 | 同时声明 `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM` | 打卡 App 符合 Google "日历/提醒"豁免类，声明即授予 |
| 打卡动画 | CustomPainter + 粒子系统 | 零依赖、可控；lottie 无现成爱心爆炸资源 |
| 已打卡不发通知 | 反向策略：完成/跳过时 cancel 当日剩余 + 每日 00:01 重调 | alarmClock 到点必弹，靠取消调度而非原生侧异步查库 |
| 备份 | JSON + share_plus | 用户已确认无后端 |
| 图表 | fl_chart | 纯 Dart、Material 3 风格 |
| IDE | VS Code + Flutter/Dart 扩展 | 启动快、命令行友好；Android Studio 仅用于首次装 SDK 和接受 license |

## 环境搭建（Windows）

### 必装清单

| 工具 | 版本 | 入口 | 谁来装 |
|---|---|---|---|
| JDK 17 | Microsoft OpenJDK 17.0.x 或 Temurin 17 | https://learn.microsoft.com/java/openjdk/ | **用户自装**（运行 MSI） |
| Flutter SDK | 3.47.x stable | https://docs.flutter.dev/release/archive | 助手下载 zip 解压到 `C:\tools\flutter` |
| Android Studio | Ladybug+ | https://developer.android.com/studio | **用户自装**（GUI 安装器） |
| Android SDK Platform | API 36（Android 16）+ 34 | Studio 内 SDK Manager | **用户自装**（需 GUI 接受 license） |
| Android Build-Tools / Platform-Tools / cmdline-tools | 最新 | SDK Manager | 同上 |
| Git | 2.x | https://git-scm.com | 用户大概率已有 |

### 环境变量（用户级，持久化）

```powershell
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Microsoft\jdk-17", "User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
$p = [Environment]::GetEnvironmentVariable("Path", "User")
$p = "$p;C:\tools\flutter\bin;$env:LOCALAPPDATA\Android\Sdk\platform-tools;C:\Program Files\Microsoft\jdk-17\bin"
[Environment]::SetEnvironmentVariable("Path", $p, "User")
```

### 验证（新开 PowerShell）

```powershell
flutter --version          # → 3.47.x stable
flutter doctor -v          # 期望 [✓] Flutter [✓] Android toolchain [✓] VS Code
java -version              # → 17.0.x（不是 1.8）
adb --version
flutter doctor --android-licenses   # 全部 y
```

> 助手在 sandbox 内可下载/解压 Flutter SDK、配置 PATH、跑 `flutter doctor`、`flutter create`、写 pubspec/Dart 代码。**JDK 17 MSI、Android Studio GUI、SDK license 接受、连接真机、生成 release keystore** 必须用户在交互式环境完成。

## 项目结构

```
lib/
├── main.dart                          # 入口：ProviderScope + 初始化 + runApp
├── app.dart                           # MaterialApp.router 根 Widget
├── core/
│   ├── constants.dart
│   ├── theme/app_theme.dart           # Material 3 + dynamic_color
│   ├── router/app_router.dart        # GoRouter
│   └── utils/date_utils.dart         # 日期边界、周/月计算
├── data/
│   ├── database/
│   │   ├── app_database.dart         # @DriftDatabase 总入口
│   │   ├── app_database.g.dart       # build_runner 生成
│   │   ├── tables/{tasks,check_ins,skips,tags,task_tags,app_meta}.dart
│   │   └── daos/{task_dao,check_in_dao,tag_dao}.dart
│   ├── backup/backup_service.dart    # 导出/导入 JSON
│   └── notifications/notification_service.dart
├── domain/
│   ├── models/{schedule_type,task_status,task_stats,check_in_mode}.dart
│   └── schedule/schedule_engine.dart  # 周期计算核心
├── providers/                         # Riverpod providers
│   ├── database_provider.dart
│   ├── task_providers.dart
│   ├── check_in_providers.dart
│   ├── stats_providers.dart
│   ├── today_providers.dart
│   ├── tag_providers.dart
│   └── settings_provider.dart
└── features/
    ├── today/{today_screen.dart, widgets/{task_checkin_tile,heart_burst_animation,completion_confetti}.dart}
    ├── tasks/{tasks_list_screen,task_edit_screen,task_detail_screen}.dart + widgets/
    ├── stats/{stats_overview_screen.dart, widgets/{completion_rate_chart,heatmap_calendar,trend_line_chart,streak_card}.dart}
    └── settings/{settings_screen.dart, widgets/{backup_card,theme_mode_selector,tag_manager}.dart}
```

## 数据模型

### Tasks 表

| 字段 | 类型 | 说明 |
|---|---|---|
| id | INTEGER autoIncrement | 主键 |
| name | TEXT notNull | 任务名 |
| iconCode | TEXT notNull | Material Icon codepoint |
| colorValue | INTEGER notNull | ARGB int |
| checkInMode | TEXT notNull | `single` / `count` |
| targetCount | INTEGER notNull default 1 | 次数型目标次数（single=1） |
| scheduleType | TEXT notNull | once/daily/weekly/monthly/yearly/custom |
| weekdays | TEXT nullable | weekly 用，逗号分隔 1-7（ISO） |
| dayOfMonth | INTEGER nullable | monthly，1-31；-1=月末 |
| monthOfYear | INTEGER nullable | yearly，1-12 |
| dayOfMonthOfYear | INTEGER nullable | yearly，1-31 |
| customDays | TEXT nullable | custom，ISO 日期逗号串 |
| startDate | INTEGER notNull | Unix ms，含 |
| endDate | INTEGER nullable | Unix ms，null=长期 |
| reminderTimes | TEXT notNull | JSON `[{"h":8,"m":30}]` |
| enableReminder | BOOLEAN notNull default 1 | 总开关 |
| sortOrder | INTEGER notNull default 0 | 拖拽排序 |
| createdAt / updatedAt | INTEGER notNull | Unix ms |
| archivedAt | INTEGER nullable | null=活跃 |

### CheckIns 表（重设计支持次数型）

| 字段 | 类型 | 说明 |
|---|---|---|
| id | INTEGER autoIncrement | 主键 |
| taskId | INTEGER notNull | FK → tasks(id) ON DELETE CASCADE |
| checkInDate | INTEGER notNull | 当日 00:00 本地 ms |
| seq | INTEGER notNull default 1 | 当日第几次打卡（单次型恒 1） |
| timestamp | INTEGER notNull | 实际打卡时刻 ms |
| note | TEXT nullable | 备注 |
| mood | INTEGER nullable | 1-5 心情评分 |

唯一索引 `uq_task_date_seq` on `(taskId, checkInDate, seq)`：次数型允许多条（seq 递增），单次型始终 seq=1 仍唯一。

### Skips 表

`id, taskId(FK CASCADE), skipDate(00:00 ms), reason(nullable), createdAt`，唯一索引 `uq_skip_task_date` on `(taskId, skipDate)`。

### Tags 表 + TaskTags 关联表

```
Tags: id, name(notNull unique), colorValue(nullable), createdAt
TaskTags: id, taskId(FK CASCADE), tagId(FK CASCADE), UNIQUE(taskId, tagId)
```

### AppMeta 表

`key(TEXT PK), value(TEXT)` —— 存 schema_version、last_backup_at 等。

## 周期计算（`schedule_engine.dart`）

- `isTaskActiveOn(Task, DateTime today) → bool`：依次检查 archived、startDate、endDate、按 scheduleType 匹配
- `dueCount(Task, DateTime upToToday) → int`：从 startDate 到 min(upToToday, endDate) 区间内逐日应用 isTaskActiveOn 累加；首版正确性优先逐日循环（区间通常<1年，性能足够）
- `doneCount(taskId, upToToday) → int`：单次型 = COUNT(*)；次数型 = SUM 取 min(sum, targetCount) 或全量打卡数（统计口径见下）
- `currentStreak(taskId, today) → int`：从今日往前回溯到第一次"应打卡却没打卡"为止的连续完成日数
- `completionRate(task) → TaskStats{due,done,skipped,rate}`：rate = done / (due - skipped)

次数型打卡率口径：`rate = min(done, targetCount*dueDays) / (targetCount*dueDays)`，done 表示累计实际打卡次数（不超 target 上限的"完成天数"）。统计连续天数按"当日 done≥target"才算完成。

## 通知实现

### 依赖与权限

`pubspec.yaml` 加：
```
flutter_local_notifications: ^22.3.0
timezone: ^0.10.0
flutter_timezone: ^3.0.1
permission_handler: ^11.3.1
```

`android/app/src/main/AndroidManifest.xml` 追加权限与 receiver（`POST_NOTIFICATIONS` / `RECEIVE_BOOT_COMPLETED` / `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` / `WAKE_LOCK` / `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`，以及 `ScheduledNotificationReceiver` 和 boot receiver）。

### NotificationService 关键方法

- `init()`：初始化 timezone + 插件，请求 POST_NOTIFICATIONS（API 33+）
- `scheduleTaskReminders(Task)`：先 cancelTaskReminders，对每个 reminderTime 调 `zonedSchedule(alarmClock, matchDateTimeComponents: time)` 按日重复
- 反向取消策略：完成今日打卡/跳过时立即 `cancelTaskReminders(taskId)`
- 每日 00:01 触发的"日重调任务"扫描所有活跃任务，对今日活跃且未完成/未跳过的任务重调当日剩余提醒（cancel→reschedule）
- 通知点击 `onDidReceiveNotificationResponse` 拿 payload（taskId）→ go_router 跳 `/tasks/:id`

## 打卡动画（`heart_burst_animation.dart`）

CustomPainter + AnimationController 粒子系统，零依赖：

- 18 个粒子（心形 Path 贝塞尔两半圆+三角顶 + 小圆混合）
- 角度均匀分布 + 随机扰动、初速度 60-140、重力 120-180、自旋 ±2
- 中心同步画一个 1.0→1.4→0 脉冲大爱心
- 时长 800ms，`addStatusListener(completed)` 后 `OverlayEntry.remove()`
- 触发点：`TaskCheckInTile` 点击 → `checkInDao.insert` → `OverlayEntry` 全屏层播放

## 屏幕清单

| # | 页面 | 路由 | 关键内容 |
|---|---|---|---|
| 1 | 今日 | `/` | 日期 + 完成率进度环；列表分组待/已/跳/不活跃；点击打卡触发爱心动画；左滑跳过右滑撤销；次数型任务显示 `done/target` 进度条 |
| 2 | 任务管理 | `/tasks` | 活跃+归档分组；按标签筛选 chips；右滑归档；FAB 新建 |
| 3 | 新建/编辑 | `/tasks/new` `/tasks/:id/edit` | 名称、图标选择器、颜色选择、checkInMode 切换（single/count+target）、schedule 类型 chips、各类型参数、起止日期、提醒时间多选、标签多选 |
| 4 | 任务详情 | `/tasks/:id` | 统计卡（due/done/skipped/rate/连续天数）+ 月度热力日历 + 历史时间线 |
| 5 | 统计总览 | `/stats` | 全任务汇总 + 各任务打卡率柱状 + 近 30/90 天趋势折线 |
| 6 | 设置 | `/settings` | 主题（系统/亮/暗）、动态色、备份导出/导入、电池白名单引导、通知权限、标签管理入口、关于 |

## 实现里程碑

| M | 内容 | 验证 |
|---|---|---|
| **M1** | 环境搭建 + `flutter create --org com.daily_pauch.app daily_pauch` 骨架 | `flutter run -d <真机>` 跑通 hello world |
| **M2** | Drift 数据层 + `schedule_engine` 周期计算 | `test/schedule_engine_test.dart` 覆盖各 scheduleType、跨周边界、月末、闰年、次数型 rate |
| **M3** | Riverpod 接 Drift + 今日页 + 任务列表 + 新建/编辑页（不含动画） | 能新建任务、今日列表显示、勾选状态刷新 |
| **M4** | 打卡交互：insert → 爱心动画；次数型进度递增；左滑跳过右滑撤销 | 真机点击看到动画；次数型累计正确；关闭重开状态保留 |
| **M5** | NotificationService 接入；保存任务调度提醒；完成/跳过取消当日；每日 00:01 重调；点击跳详情 | 设 1 分钟后提醒、杀进程、到点收到通知；提前完成则不收到 |
| **M6** | 统计页 + 任务详情页热力日历 + 连续天数 + 趋势折线 | 真假数据切换都正确；滚动月份查看历史 |
| **M7** | 备份导出（JSON + share_plus）+ 导入（file_picker + 校验 schema_version + 事务性 upsert）+ 标签管理 | 导出→清库→导入，今日/统计/标签完全恢复 |
| **M8** | release 签名（keytool 生成 keystore + key.properties + build.gradle.kts signingConfig）+ `flutter build apk --release --target-platform android-arm64` | `flutter install` 真机独立运行；锁屏/Doze 下通知仍弹 |

## 关键依赖清单（pubspec.yaml 摘要）

```yaml
environment:
  sdk: ^3.13.2
  flutter: ">=3.27.0"

dependencies:
  flutter: { sdk: flutter }
  flutter_localizations: { sdk: flutter }
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.1
  go_router: ^14.6.0
  drift: ^2.21.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.5
  path: ^1.9.0
  flutter_local_notifications: ^22.3.0
  timezone: ^0.10.0
  flutter_timezone: ^3.0.1
  permission_handler: ^11.3.1
  dynamic_color: ^1.7.0
  intl: ^0.19.0
  uuid: ^4.5.1
  collection: ^1.18.0
  share_plus: ^10.1.3
  file_picker: ^8.1.4
  fl_chart: ^0.69.2
  table_calendar: ^3.1.3

dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  drift_dev: ^2.21.0
  riverpod_generator: ^2.6.3
  riverpod_lint: ^2.6.3
  custom_lint: ^0.6.8
  flutter_launcher_icons: ^0.14.3
  flutter_native_splash: ^2.4.3
```

## 关键文件（实施时核心 5 个）

1. `lib/data/database/app_database.dart` —— Drift `@DriftDatabase(tables: [Tasks, CheckIns, Skips, Tags, TaskTags, AppMeta], daos: [TaskDao, CheckInDao, TagDao])` 总入口
2. `lib/domain/schedule/schedule_engine.dart` —— 周期/打卡率/连续天数业务真相源
3. `lib/data/notifications/notification_service.dart` —— 通知调度 + 反向取消 + 点击跳转 + Android 14+ 合规
4. `lib/features/today/widgets/heart_burst_animation.dart` —— 打卡核心动画体验
5. `android/app/src/main/AndroidManifest.xml` —— 所有权限、receiver、deep link intent-filter

辅助必读：`pubspec.yaml`、`android/app/build.gradle.kts`（compileSdk=36 / minSdk=24 / targetSdk=36 / signingConfig）、`lib/providers/today_providers.dart`（连接数据库与今日 UI）。

## 验证计划

### 单元测试（`test/schedule_engine_test.dart`）

- daily 任务 startDate 前/当日/endDate 后
- weekly 选周一三五跨周边界
- monthly dayOfMonth=31 在 2 月、4 月、12 月
- yearly 闰年 2/29
- 次数型任务 done < target / done > target 的 rate 边界
- dueCount 计算含 skip 扣除
- currentStreak 中途断档重置为 0

### Widget 测试

`test/today_screen_test.dart`：mock DAO，验证单次型点击后 pending→done、次数型点击后 done 递增到 target 后转 done、UI 重绘。

### 最终 APK 真机测试

1. `flutter build apk --release --target-platform android-arm64`
2. `adb install -r build/app/outputs/flutter-apk/app-release.apk`
3. 系统设置 → 应用 → daily_pauch → 权限：通知开、闹钟和提醒开、电池不受限
4. 场景：
   - 新建 daily 任务提醒 1 分钟后；杀进程；到点收到通知；点开跳详情；通知消失
   - 提前完成今日；到提醒时间**不收到**通知
   - 新建次数型任务 target=3；连点 3 次爱心动画；列表显示 `3/3` 已完成
   - 新建 weekly 周一三五；切系统日期到周日确认今日不活跃
   - 导出备份 → 卸载重装 → 导入备份 → 任务/统计/标签完全恢复
5. 锁屏 + Doze 模式下验证通知依然弹出（关键可靠性）
6. 关闭网络确认纯本地功能无依赖

## 用户参与的部分（实施时需用户在交互式环境完成）

- 安装 JDK 17 MSI
- 安装 Android Studio GUI 并在 SDK Manager 接受 license、装 SDK Platform 36+34、Build-Tools、Platform-Tools、cmdline-tools
- 连接 Android 真机并开启 USB 调试
- 生成 release 签名 keystore：`keytool -genkey -v -keystore release.keystore -alias daily_pauch -keyalg RSA -keysize 2048 -validity 10000`
- 真机权限授予（通知、精确闹钟、电池白名单）

助手在 sandbox 内能完成：下载解压 Flutter SDK、配置 PATH、`flutter doctor`、`flutter create`、写所有 Dart/pubspec/Android 文件、跑 `build_runner`、跑 `flutter test`、`flutter build apk`（如本机 Android SDK 已就绪）。

## 起步

实施阶段第一步从 **M1 环境搭建** 开始：用户先装 JDK 17 和 Android Studio + SDK license，完成后告知助手，助手解压 Flutter SDK、配 PATH、跑 `flutter doctor` 验证通过后开始 `flutter create` 项目骨架。
