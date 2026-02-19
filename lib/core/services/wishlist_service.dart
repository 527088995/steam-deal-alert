import '../../models/game_model.dart';
import '../../models/wishlist_model.dart';
import '../storage_service.dart';

/// 最终稳定结构：愿望单服务（对接 StorageService）
/// 详情页「加入愿望单」、Wishlist 页数据
class WishlistService {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  StorageService get _storage => StorageService.instance;

  Future<void> add(GameModel game, {int targetDiscount = 0}) async {
    await _storage.addToWishlist(WishlistItem.fromGame(game, targetDiscount: targetDiscount));
  }

  Future<void> remove(String appId) async {
    await _storage.removeFromWishlist(appId);
  }

  Future<bool> isInWishlist(String appId) async {
    return _storage.isInWishlist(appId);
  }

  Future<List<WishlistItem>> getWishlist() async {
    return _storage.getWishlistItems();
  }
}
