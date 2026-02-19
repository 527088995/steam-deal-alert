import 'constants.dart';
import 'storage_service.dart';

/// 插屏广告触发控制：每日最多 2 次；触发点：每 3 次打开、加入愿望单、每看 5 个详情。
class InterstitialHelper {
  static final StorageService _storage = StorageService.instance;

  /// 记录一次应用打开；若满足「第 3 次打开」且今日未满 2 次则返回 true，并占用一次当日额度。Pro 用户不展示插屏。
  static Future<bool> tryShowAfterAppOpen() async {
    if (!_storage.isInitialized) await _storage.init();
    if (await _storage.isPro()) return false;
    await _storage.incrementAppOpenCount();
    final openCount = await _storage.getAppOpenCount();
    if (openCount % 3 != 0) return false;
    final today = await _storage.getTodayInterstitialCount();
    if (today >= AppConstants.maxInterstitialsPerDay) return false;
    await _storage.incrementTodayInterstitialCount();
    return true;
  }

  /// 加入愿望单后尝试展示插屏；若今日未满 2 次则返回 true 并占用一次。Pro 不展示。
  static Future<bool> tryShowAfterAddToWishlist() async {
    if (!_storage.isInitialized) await _storage.init();
    if (await _storage.isPro()) return false;
    final today = await _storage.getTodayInterstitialCount();
    if (today >= AppConstants.maxInterstitialsPerDay) return false;
    await _storage.incrementTodayInterstitialCount();
    return true;
  }

  /// 记录一次详情页查看；若满足「累计看满 5 个」且今日未满 2 次则返回 true 并占用一次。Pro 不展示。
  static Future<bool> tryShowAfterDetailView() async {
    if (!_storage.isInitialized) await _storage.init();
    if (await _storage.isPro()) return false;
    await _storage.incrementDetailViewCount();
    final count = await _storage.getDetailViewCount();
    if (count % 5 != 0) return false;
    final today = await _storage.getTodayInterstitialCount();
    if (today >= AppConstants.maxInterstitialsPerDay) return false;
    await _storage.incrementTodayInterstitialCount();
    return true;
  }
}
