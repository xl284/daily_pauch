enum TaskStatus {
  pending,
  done,
  skipped,
  notActive;

  String get label => switch (this) {
        pending => '待打卡',
        done => '已完成',
        skipped => '已跳过',
        notActive => '今日不活跃',
      };
}
