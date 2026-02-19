import 'dart:math' show log;
import '../../models/game_model.dart';

/// 将 Steam 评价文案转为 0~1 分数
double _reviewScoreFromText(String text) {
  if (text.isEmpty) return 0.7;
  final t = text.toLowerCase();
  if (t.contains('overwhelmingly positive')) return 0.95;
  if (t.contains('very positive')) return 0.85;
  if (t.contains('positive') && !t.contains('mostly')) return 0.75;
  if (t.contains('mostly positive')) return 0.65;
  if (t.contains('mixed')) return 0.5;
  if (t.contains('mostly negative')) return 0.35;
  if (t.contains('negative') && !t.contains('very')) return 0.25;
  if (t.contains('very negative') || t.contains('overwhelmingly negative')) return 0.1;
  return 0.7;
}

/// AI Score 2.0：6 维加权，真正拉开差距
/// 1. 折扣力度 2. 评论评分 3. 评论数量 4. 评论增长率(代理) 5. 历史最低价(代理) 6. 新游戏加权
/// 返回 0~10
double calculateScore(GameModel g) {
  final discount = (g.discount.clamp(0, 100) / 100).toDouble();
  final rating = _reviewScoreFromText(g.steamRatingText);
  final reviewVolume = (log(g.steamRatingCount + 1) / 10).clamp(0.0, 1.0);
  // 评论增长率：无 reviewGrowth30d，用 lastChange 代理（最近更新=高活跃）
  final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final daysSinceChange = g.lastChange > 0 ? (nowSec - g.lastChange) / 86400.0 : 30.0;
  final growth = (1.0 / (1.0 + daysSinceChange / 14.0)).clamp(0.0, 1.0);
  // 历史最低价：无 isHistoricalLow，用大折扣(>=70%)或低价占原价<=40% 代理
  final isHistoricalLow = g.originalPrice > 0
      ? (g.discount >= 70 || (g.price / g.originalPrice) <= 0.4)
      : false;
  final historicalLow = isHistoricalLow ? 0.3 : 0.0;
  // 新游戏：30 天内发售
  final daysSinceRelease = g.releaseDate > 0
      ? (nowSec - g.releaseDate) / 86400.0
      : 999.0;
  final freshness = daysSinceRelease < 30 ? 0.2 : 0.0;

  double score = discount * 0.30 +
      rating * 0.25 +
      reviewVolume * 0.15 +
      growth * 0.15 +
      historicalLow * 0.10 +
      freshness * 0.05;

  return (score.clamp(0.0, 1.0) * 10).clamp(0.0, 10.0);
}

/// 按得分排序（高到低），取前 N
List<GameModel> topDealsByScore(List<GameModel> deals, {int limit = 10}) {
  final list = List<GameModel>.from(deals)
    ..sort((a, b) => calculateScore(b).compareTo(calculateScore(a)));
  return list.take(limit).toList();
}

/// 去重：同一游戏只保留折扣最高的一条
List<GameModel> deduplicateDeals(List<GameModel> list) {
  final byKey = <String, GameModel>{};
  for (final g in list) {
    final key = g.steamAppID.trim().isNotEmpty
        ? 's:${g.steamAppID.trim()}'
        : 'n:${g.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')}';
    if (key == 'n:') continue;
    final existing = byKey[key];
    if (existing == null || g.discount > existing.discount) byKey[key] = g;
  }
  return byKey.values.toList();
}

/// 模块间去重：已出现的 appId 不再进入后续列表（用于多模块展示不重复）
List<GameModel> uniqueList(List<GameModel> list, Set<String> usedIds) {
  return list.where((g) {
    final id = g.appId;
    if (usedIds.contains(id)) return false;
    usedIds.add(id);
    return true;
  }).toList();
}
