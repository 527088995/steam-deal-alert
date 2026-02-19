/// 限时折扣倒计时（无 API 结束时间时可显示「刚更新」等）
String formatCountdown(int endTimestampSec) {
  if (endTimestampSec <= 0) return '';
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final diff = endTimestampSec - now;
  if (diff <= 0) return 'Ended';
  final h = diff ~/ 3600;
  final m = (diff % 3600) ~/ 60;
  final s = diff % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// 最近更新时间描述
String formatLastChange(int lastChangeSec) {
  if (lastChangeSec <= 0) return '';
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final diff = now - lastChangeSec;
  if (diff < 3600) return 'Updated ${(diff ~/ 60)}m ago';
  if (diff < 86400) return 'Updated ${(diff ~/ 3600)}h ago';
  return 'Updated ${(diff ~/ 86400)}d ago';
}
