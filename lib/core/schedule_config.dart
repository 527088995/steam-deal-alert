/// 通知发送时间：目标美国市场，美国晚 7~10 点发送
/// 使用 UTC 午夜（约等于美东 19:00–20:00）作为每日一次发送时刻
class ScheduleConfig {
  ScheduleConfig._();

  /// 每日发送时刻：UTC 00:00（约美东 19:00 EST / 20:00 EDT）
  static const int utcHour = 0;
  static const int utcMinute = 0;

  /// 计算「距离下一个发送时刻」的延迟（用于 registerOneOffTask 的 initialDelay）
  static Duration delayUntilNextUSEvening() {
    final now = DateTime.now().toUtc();
    var next = DateTime.utc(now.year, now.month, now.day, utcHour, utcMinute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next.difference(now);
  }

  /// 每日任务再次调度间隔（任务执行后约 24 小时再跑）
  static const Duration dailyInterval = Duration(hours: 24);
}
