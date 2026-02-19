import '../../models/game_model.dart';
import '../utils/score_calculator.dart' as score_util;

/// 最终稳定结构：AI 评分与排序（对接 score_calculator + 爆款算法）
/// Home 算法推荐、不重复 Explore 的浏览逻辑
class AlgorithmService {
  static final AlgorithmService _instance = AlgorithmService._internal();
  factory AlgorithmService() => _instance;
  AlgorithmService._internal();

  /// AI 评分 0~10（折扣 / 好评率 / 热度 / 近期趋势 / 历史低价 / 新发布）
  double calculateScore(GameModel g) {
    return score_util.calculateScore(g);
  }

  /// 按得分从高到低排序，返回新列表
  List<GameModel> sortByScore(List<GameModel> games) {
    final list = List<GameModel>.from(games)
      ..sort((a, b) => score_util.calculateScore(b).compareTo(score_util.calculateScore(a)));
    return list;
  }

  /// 取前 N 条高分（今日热选）
  List<GameModel> topByScore(List<GameModel> games, {int limit = 10}) {
    return sortByScore(games).take(limit).toList();
  }
}
