import '../../models/game_model.dart';
import '../../data/services/api_service.dart';

/// 最终稳定结构：游戏数据服务（对接 ApiService / SteamApiService）
/// Home = 算法推荐、Explore = 搜索+筛选 均通过本服务拉取
class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  /// 拉取折扣列表，支持分页
  Future<List<GameModel>> fetchGames({int pageSize = 60, int pageNumber = 0}) async {
    return ApiService.fetchDeals(pageSize: pageSize, pageNumber: pageNumber);
  }

  /// 按 dealId 拉取单条详情（详情页用）
  Future<GameModel> fetchGameById(String dealId) async {
    return ApiService.fetchGameById(dealId);
  }

  /// 搜索游戏
  Future<List<GameModel>> searchGames(String query, {int pageSize = 20}) async {
    return ApiService.searchGames(query, pageSize: pageSize);
  }
}
