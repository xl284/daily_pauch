class TaskStats {
  final int due;
  final int done;
  final int skipped;
  final double rate;
  final int streak;

  const TaskStats({
    required this.due,
    required this.done,
    required this.skipped,
    required this.rate,
    required this.streak,
  });

  int get effectiveDue => due - skipped;

  static const empty = TaskStats(
    due: 0,
    done: 0,
    skipped: 0,
    rate: 1.0,
    streak: 0,
  );
}
