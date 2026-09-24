# 每日打卡 (Daily Pauch)

支持自定义周期、提醒通知、打卡统计的 Flutter 打卡 App。

## 环境要求

- Flutter 3.47.x (stable)
- JDK 17
- Android SDK (compileSdk 37)
- CMake 3.22.1（sqlite3 native 构建用）

## 构建

### Debug（调试）
```powershell
flutter run -d <device-id>
# 或构建 debug APK
flutter build apk --debug --no-tree-shake-icons
```

### Release（正式发布）
```powershell
flutter clean
flutter build apk --release --no-tree-shake-icons --target-platform android-arm64
```

参数说明：
- `--no-tree-shake-icons`：禁用图标摇树优化，因为任务图标是运行时动态选择的
- `--target-platform android-arm64`：只打 arm64-v8a 架构，APK 体积 ~22MB（覆盖 99% 现代 Android 设备）

构建产物：`build/app/outputs/flutter-apk/app-release.apk`

### 签名

签名配置在 `android/app/build.gradle.kts` 中，使用 `android/app/daily_pauch_release.jks` 密钥库。debug 和 release 共用同一签名，可直接覆盖安装。

### 网络问题

如果 `sqlite3` 包下载 `.so` 失败（GitHub 连接超时），设置代理后重试：
```powershell
$env:HTTP_PROXY = "http://127.0.0.1:7890"
$env:HTTPS_PROXY = "http://127.0.0.1:7890"
flutter build apk --release --no-tree-shake-icons --target-platform android-arm64
```

## 安装

```powershell
# 覆盖安装（保留数据，同签名）
adb install "build/app/outputs/flutter-apk/app-release.apk"
```

## 发布版本

```powershell
# 打 tag
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0

# 重命名 APK 带版本号
Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "build/app/outputs/flutter-apk/daily_pauch-v1.0.0-release.apk"
```

然后在 GitHub 创建 Release 并上传 APK。

## 代码生成

修改了 Drift 表结构或 Riverpod provider 后需要重新生成：
```powershell
dart run build_runner build --delete-conflicting-outputs
```
