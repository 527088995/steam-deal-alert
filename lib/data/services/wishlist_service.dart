import '../../models/wishlist_model.dart';
import '../../core/storage_service.dart';

/// 数据层：愿望单纯本地，无后端
class WishlistService {
  static StorageService get _storage => StorageService.instance;

  static Future<List<WishlistItem>> getWishlist() async {
    await _storage.init();
    return _storage.getWishlistItems();
  }

  static Future<void> add(WishlistItem item) async {
    await _storage.init();
    await _storage.addToWishlist(item);
  }

  static Future<void> remove(String appId) async {
    await _storage.init();
    await _storage.removeFromWishlist(appId);
  }

  static Future<bool> isInWishlist(String appId) async {
    await _storage.init();
    return _storage.isInWishlist(appId);
  }

  static Future<List<String>> getWishlistAppIds() async {
    await _storage.init();
    return _storage.getWishlistAppIds();
  }
}
