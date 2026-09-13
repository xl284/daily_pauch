enum ScheduleType {
  once,
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  String get label => switch (this) {
        once => '仅一次',
        daily => '每日',
        weekly => '每周',
        monthly => '每月',
        yearly => '每年',
        custom => '自定义',
      };

  static ScheduleType fromString(String s) =>
      ScheduleType.values.firstWhere((e) => e.name == s, orElse: () => daily);
}
