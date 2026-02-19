/// 通知文案：爆款 2.0 带数字，提高 CTR
class NotificationCopy {
  NotificationCopy._();

  /// 按日轮换（0 或 1），便于长期对比
  static int get variant => DateTime.now().day % 2;

  // ---------- 愿望单游戏折扣提醒（保留） ----------
  static String wishlistTitle(String gameName, int discountPercent) {
    if (variant == 0) {
      return '🔥 $gameName -$discountPercent% OFF!';
    }
    return '$gameName is $discountPercent% off!';
  }

  static String wishlistBody(String priceStr) {
    if (variant == 0) {
      return 'Now only $priceStr\nLimited time deal!';
    }
    return 'Just $priceStr — tap to see deal';
  }

  // ---------- 爆款 2.0：算法驱动，必须带数字 ----------

  /// 80%+ 数量达标：X Steam Games Dropped 90%
  static String over80Title(int count) {
    return '🔥 $count Steam Games Dropped 90%';
  }

  static String over80Body() {
    return 'Tap to see the biggest discounts today';
  }

  /// Under $5 数量达标
  static String under5Title(int count) {
    return '🔥 $count Games Under \$5 – Just Updated';
  }

  static String under5Body() {
    return 'Tap to grab them before they\'re gone';
  }

  /// 今日主推（Shock Deal）得分达标
  static String shockDealTitle(String gameName, int discount) {
    return '🔥 Today\'s Best: $gameName is $discount% OFF';
  }

  static String shockDealBody(String priceStr) {
    return 'Now $priceStr — tap to see deal';
  }

  /// 兼容旧逻辑：每日 Top 5 汇总（备用）
  static const String top5Title = "🔥 Today's Top 5 Deals";
  static const String top5Body = "Tap to see today's best discounts";
}
