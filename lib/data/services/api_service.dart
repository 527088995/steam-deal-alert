import '../../models/game_model.dart';
import '../../services/steam_api_service.dart';

/// 数据层：只负责接口，页面不直接调 SteamApiService
class ApiService {
  static final _api = SteamApiService();

  static Future<List<GameModel>> fetchDeals({int pageSize = 60, int pageNumber = 0}) async {
    return _api.fetchDeals(pageSize: pageSize, pageNumber: pageNumber);
  }

  static Future<GameModel> fetchGameById(String dealId) async {
    return _api.fetchGameById(dealId);
  }

  static Future<List<GameModel>> searchGames(String title, {int pageSize = 20}) async {
    return _api.searchGames(title, pageSize: pageSize);
  }
}
