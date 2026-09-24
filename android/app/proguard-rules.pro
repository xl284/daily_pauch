# Flutter
# Flutter 的 R8 规则由 Flutter Gradle Plugin 自动处理，
# 这里只补充第三方库的 keep 规则。

# Drift (SQLite + 反射)
-keep class * extends .drift.** { *; }
-keep class .drift.** { *; }
-keep class .sqlite3.** { *; }

# Riverpod
-keep class .riverpod.** { *; }

# 保持 generated 文件不被混淆
-keep class **_g.dart { *; }
-keep class **.generated.** { *; }

# SQLite native
-keep class .sqlite3_flutter_libs.** { *; }
