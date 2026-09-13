enum CheckInMode {
  single,
  count;

  String get label => switch (this) {
        single => '单次打卡',
        count => '次数打卡',
      };

  static CheckInMode fromString(String s) =>
      CheckInMode.values.firstWhere((e) => e.name == s, orElse: () => single);
}
