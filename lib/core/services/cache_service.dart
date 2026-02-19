import '../../models/game_model.dart';
import '../../models/wishlist_model.dart';
import '../storage_service.dart';
import '../../data/services/cache_service.dart' as deal_cache;

/// 最终稳定结构：本地缓存服务（愿望单 + 折扣缓存）
/// Wishlist = 本地数据；可扩展 AdMob / 本地缓存策略
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// 愿望单列表（用于 Wishlist 页）
  Future<List<WishlistItem>> getWishlist() async {
    return StorageService.instance.getWishlistItems();
  }

  /// 缓存的折扣列表（秒开用）
  Future<List<GameModel>> getCachedGames() async {
    return deal_cache.CacheService.loadGames();
  }

  /// 保存折扣到本地缓存
  Future<void> saveGames(List<GameModel> games) async {
    await deal_cache.CacheService.saveGames(games);
  }

  /// 上次检查时间
  Future<String?> getLastCheckTime() async {
    return deal_cache.CacheService.getLastCheckTime();
  }
}
