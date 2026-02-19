import '../models/game_model.dart';
import 'utils/score_calculator.dart' show calculateScore;

/// 爆款 2.0 本地算法：一次拉接口 → 本地计算 → 分类排序 → 本地缓存
/// 权重：折扣 40% + 评论热度 30% + 增长 20%（无数据用 0）+ 低价 10%
class ShockDealAlgorithm {
  ShockDealAlgorithm._();

  /// 去重：同一游戏只保留折扣最高的一条
  static List<GameModel> deduplicateDeals(List<GameModel> list) {
    final byKey = <String, GameModel>{};
    for (final g in list) {
      final key = _identityKey(g);
      if (key.isEmpty) continue;
      final existing = byKey[key];
      if (existing == null || g.discount > existing.discount) {
        byKey[key] = g;
      }
    }
    return byKey.values.toList();
  }

  static String _identityKey(GameModel g) {
    if (g.steamAppID.trim().isNotEmpty) {
      return 's:${g.steamAppID.trim()}';
    }
    final name = g.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return 'n:$name';
  }

  /// 按得分排序（高到低），统一用 score_calculator.calculateScore
  static List<GameModel> _sortedByScore(List<GameModel> deals) {
    final list = List<GameModel>.from(deals)
      ..sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));
    return list;
  }

  static const int _recentlyUpdatedSeconds = 24 * 3600;
  static const int _newReleaseDays = 30;

  static bool _isRecentlyUpdated(GameModel d) {
    if (d.lastChange <= 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - d.lastChange) <= _recentlyUpdatedSeconds;
  }

  static bool _isNewRelease(GameModel d) {
    if (d.releaseDate <= 0) return false;
    final release = DateTime.fromMillisecondsSinceEpoch(d.releaseDate * 1000);
    return release.isAfter(DateTime.now().subtract(const Duration(days: _newReleaseDays)));
  }

  static bool _isPositiveRated(GameModel d) {
    final t = d.steamRatingText.toLowerCase();
    return t.contains('positive') || t.contains('overwhelmingly') || t.contains('very');
  }

  /// 一次计算，得到五类列表
  /// todayHot 按折扣从高到低（最大折扣区块），与 AI 推荐（按综合得分）区分开
  static DealCategories computeCategories(List<GameModel> deals) {
    final byDiscount = List<GameModel>.from(deals)
      ..sort((a, b) => b.discount.compareTo(a.discount));
    final todayHot = byDiscount.take(20).toList();
    final newRelease = deals.where(_isNewRelease).toList()
      ..sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));
    final trending = deals.where(_isRecentlyUpdated).toList()
      ..sort((a, b) => b.lastChange.compareTo(a.lastChange));
    final highRatedCheap = deals.where((d) => _isPositiveRated(d) && d.price > 0 && d.price < 10).toList()
      ..sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));
    final hiddenGems = deals.where((d) {
      if (!_isPositiveRated(d) || d.price >= 15) return false;
      return d.steamRatingCount > 0 && d.steamRatingCount < 5000;
    }).toList()
      ..sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));

    return DealCategories(
      todayHot: todayHot,
      newRelease: newRelease,
      trending: trending,
      highRatedCheap: highRatedCheap,
      hiddenGems: hiddenGems,
    );
  }

  /// 今日主推（单条）：得分最高
  static GameModel? getShockDeal(List<GameModel> deals) {
    if (deals.isEmpty) return null;
    final sorted = _sortedByScore(deals);
    return sorted.first;
  }

  /// 兼容旧统计（通知等）
  static ShockStats getStats(List<GameModel> deals) {
    final over80 = deals.where((d) => d.discount >= 80).length;
    final under5 = deals.where((d) => d.price >= 0 && d.price <= 5).length;
    final recentlyUpdated = deals.where(_isRecentlyUpdated).length;
    return ShockStats(over80: over80, under5: under5, recentlyUpdated: recentlyUpdated);
  }
}

class DealCategories {
  final List<GameModel> todayHot;
  final List<GameModel> newRelease;
  final List<GameModel> trending;
  final List<GameModel> highRatedCheap;
  final List<GameModel> hiddenGems;

  const DealCategories({
    required this.todayHot,
    required this.newRelease,
    required this.trending,
    required this.highRatedCheap,
    required this.hiddenGems,
  });
}

class ShockStats {
  final int over80;
  final int under5;
  final int recentlyUpdated;

  const ShockStats({
    required this.over80,
    required this.under5,
    required this.recentlyUpdated,
  });
}
