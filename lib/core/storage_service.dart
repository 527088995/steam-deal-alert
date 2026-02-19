import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'services/review_service.dart';
import '../models/game_model.dart';
import '../models/wishlist_model.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService();

  late SharedPreferences _prefs;
  static const String _hiveDealsKey = 'deals';
  static const String _hiveBoxName = 'deal_cache';

  Future<void> init() async {
    if (!_inited) {
      _prefs = await SharedPreferences.getInstance();
      _inited = true;
    }
  }

  SharedPreferences get prefs => _prefs;

  bool _inited = false;
  bool get isInitialized => _inited;

  static const String _keyWishlistItems = 'wishlist_items';

  Future<List<WishlistItem>> getWishlistItems() async {
    if (!_inited) return [];
    final json = _prefs.getString(_keyWishlistItems);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WishlistItem>> getWishlist() async => getWishlistItems();

  Future<List<String>> getWishlistAppIds() async {
    final items = await getWishlistItems();
    return items.map((e) => e.appId).toList();
  }

  Future<void> _saveWishlistItems(List<WishlistItem> items) async {
    if (!_inited) return;
    await _prefs.setString(
      _keyWishlistItems,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addToWishlist(WishlistItem item) async {
    final items = await getWishlistItems();
    if (items.any((e) => e.appId == item.appId)) return;
    items.add(item);
    await _saveWishlistItems(items);
    ReviewService().checkAndRequestReviewAfterWishlistAdd();
  }

  Future<void> removeFromWishlist(String appId) async {
    final items = await getWishlistItems();
    items.removeWhere((e) => e.appId == appId);
    await _saveWishlistItems(items);
  }

  Future<bool> isInWishlist(String appId) async {
    final ids = await getWishlistAppIds();
    return ids.contains(appId);
  }

  Future<void> setLastDealsCache(List<Map<String, dynamic>> deals) async {
    if (!_inited) return;
    await _prefs.setString(AppConstants.keyLastDealsCache, jsonEncode(deals));
    await _prefs.setString(
        AppConstants.keyLastCheckTime, DateTime.now().toIso8601String());
  }

  Future<List<Map<String, dynamic>>> getLastDealsCache() async {
    if (!_inited) return [];
    final json = _prefs.getString(AppConstants.keyLastDealsCache);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 上次刷新时间（用于展示「Updated at HH:mm」）
  Future<String?> getLastCheckTime() async {
    if (!_inited) return null;
    return _prefs.getString(AppConstants.keyLastCheckTime);
  }

  /// 首屏秒开：优先从 Hive 读缓存（<100ms），无则回退 SharedPreferences
  Future<List<GameModel>> getCachedDealsAsGames() async {
    try {
      final box = Hive.box(_hiveBoxName);
      final jsonStr = box.get(_hiveDealsKey) as String?;
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        final result = <GameModel>[];
        for (final e in list) {
          try {
            result.add(GameModel.fromJson(Map<String, dynamic>.from(e as Map)));
          } catch (_) {
            continue;
          }
        }
        if (result.isNotEmpty) return result;
      }
    } catch (_) {}
    try {
      final list = await getLastDealsCache();
      final result = <GameModel>[];
      for (final e in list) {
        try {
          final map = Map<String, dynamic>.from(e as Map);
          if (map.containsKey('dealID') && map.containsKey('title')) {
            result.add(GameModel.fromCheapSharkDeal(map));
          } else {
            result.add(GameModel.fromJson(map));
          }
        } catch (_) {
          continue;
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  /// 请求成功后写入 Hive + SharedPreferences，供下次启动秒开
  Future<void> setLastDealsCacheFromGames(List<GameModel> deals) async {
    if (!_inited) return;
    final list = deals.map((g) => g.toJson()).toList();
    try {
      await Hive.box(_hiveBoxName).put(_hiveDealsKey, jsonEncode(list));
    } catch (_) {}
    await setLastDealsCache(list);
  }

  static const String _keyLastKnownDiscounts = 'wishlist_last_discount';

  /// 上次检测时各愿望单游戏的折扣（appId -> discount%）
  Future<Map<String, int>> getLastKnownDiscounts() async {
    if (!_inited) return {};
    final json = _prefs.getString(_keyLastKnownDiscounts);
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v is int) ? v : (v is num ? (v as num).toInt() : 0)));
    } catch (_) {
      return {};
    }
  }

  /// 更新某游戏的“上次折扣”，检测到折扣变大后用于对比
  Future<void> setLastKnownDiscount(String appId, int discount) async {
    if (!_inited) return;
    final map = await getLastKnownDiscounts();
    map[appId] = discount;
    await _prefs.setString(_keyLastKnownDiscounts, jsonEncode(map));
  }

  Future<bool> getHasAskedNotification() async {
    if (!_inited) return false;
    return _prefs.getBool(AppConstants.keyHasAskedNotification) ?? false;
  }

  Future<void> setHasAskedNotification(bool value) async {
    if (!_inited) return;
    await _prefs.setBool(AppConstants.keyHasAskedNotification, value);
  }

  Future<bool> getHasSeenEnableAlertsPrompt() async {
    if (!_inited) return false;
    return _prefs.getBool(AppConstants.keyHasSeenEnableAlertsPrompt) ?? false;
  }

  Future<void> setHasSeenEnableAlertsPrompt(bool value) async {
    if (!_inited) return;
    await _prefs.setBool(AppConstants.keyHasSeenEnableAlertsPrompt, value);
  }

  /// 插屏：应用打开次数
  Future<int> getAppOpenCount() async {
    if (!_inited) return 0;
    return _prefs.getInt(AppConstants.keyAppOpenCount) ?? 0;
  }

  Future<void> incrementAppOpenCount() async {
    if (!_inited) return;
    final n = await getAppOpenCount();
    await _prefs.setInt(AppConstants.keyAppOpenCount, n + 1);
  }

  /// 插屏：当日已展示次数与日期
  Future<int> getTodayInterstitialCount() async {
    if (!_inited) return 0;
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final last = _prefs.getString(AppConstants.keyLastInterstitialDate);
    if (last != date) return 0;
    return _prefs.getInt(AppConstants.keyTodayInterstitialCount) ?? 0;
  }

  Future<void> incrementTodayInterstitialCount() async {
    if (!_inited) return;
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final last = _prefs.getString(AppConstants.keyLastInterstitialDate);
    int count = 0;
    if (last == date) count = _prefs.getInt(AppConstants.keyTodayInterstitialCount) ?? 0;
    await _prefs.setString(AppConstants.keyLastInterstitialDate, date);
    await _prefs.setInt(AppConstants.keyTodayInterstitialCount, count + 1);
  }

  /// 插屏：详情页查看次数
  Future<int> getDetailViewCount() async {
    if (!_inited) return 0;
    return _prefs.getInt(AppConstants.keyDetailViewCount) ?? 0;
  }

  Future<void> incrementDetailViewCount() async {
    if (!_inited) return;
    final n = await getDetailViewCount();
    await _prefs.setInt(AppConstants.keyDetailViewCount, n + 1);
  }

  // --- Pro 订阅（含分享奖励的临时 Pro）---
  Future<void> setPro(bool value) async {
    if (!_inited) return;
    await _prefs.setBool(AppConstants.keyIsPro, value);
  }

  Future<bool> isPro() async {
    if (!_inited) return false;
    if (_prefs.getBool(AppConstants.keyIsPro) == true) return true;
    final until = _prefs.getString(AppConstants.keyProFreeUntil);
    if (until != null && until.isNotEmpty) {
      try {
        if (DateTime.parse(until).isAfter(DateTime.now())) return true;
      } catch (_) {}
    }
    return false;
  }

  /// 设置分享奖励的 Pro 截止日（本地 1 天 Pro）
  Future<void> setProFreeUntil(DateTime dateTime) async {
    if (!_inited) return;
    await _prefs.setString(AppConstants.keyProFreeUntil, dateTime.toIso8601String());
  }

  // --- 评分 ---
  Future<bool> getHasReviewed() async {
    if (!_inited) return false;
    return _prefs.getBool(AppConstants.keyHasReviewed) ?? false;
  }

  Future<void> setHasReviewed(bool value) async {
    if (!_inited) return;
    await _prefs.setBool(AppConstants.keyHasReviewed, value);
  }

  // --- 首日引导（完成引导后调用 setFirstLaunchDone）---
  Future<bool> isFirstLaunch() async {
    if (!_inited) await init();
    return _prefs.getBool(AppConstants.keyFirstLaunchDone) != true;
  }

  Future<void> setFirstLaunchDone() async {
    if (!_inited) return;
    await _prefs.setBool(AppConstants.keyFirstLaunchDone, true);
  }

  // --- 二次唤醒：上次打开日期 ---
  Future<void> setLastOpenDate(DateTime date) async {
    if (!_inited) return;
    await _prefs.setString(AppConstants.keyLastOpenDate, date.toIso8601String().substring(0, 10));
  }

  Future<String?> getLastOpenDate() async {
    if (!_inited) return null;
    return _prefs.getString(AppConstants.keyLastOpenDate);
  }

  Future<String?> getLastReengagementDate() async {
    if (!_inited) return null;
    return _prefs.getString(AppConstants.keyLastReengagementDate);
  }

  Future<void> setLastReengagementDate(String dateStr) async {
    if (!_inited) return;
    await _prefs.setString(AppConstants.keyLastReengagementDate, dateStr);
  }

  // --- 分享拉新奖励（本地）---
  Future<int> getShareCount() async {
    if (!_inited) return 0;
    return _prefs.getInt(AppConstants.keyShareCount) ?? 0;
  }

  Future<void> incrementShareCount() async {
    if (!_inited) return;
    final n = await getShareCount();
    await _prefs.setInt(AppConstants.keyShareCount, n + 1);
    if (n + 1 >= AppConstants.sharesNeededForOneDayPro) {
      final until = DateTime.now().add(const Duration(days: 1));
      await setProFreeUntil(until);
    }
  }

  // --- 拉新：userId / referrerId ---
  Future<String> getOrCreateUserId() async {
    if (!_inited) await init();
    var id = _prefs.getString(AppConstants.keyUserId);
    if (id == null || id.isEmpty) {
      id = 'u_${DateTime.now().millisecondsSinceEpoch}_${_prefs.getInt(AppConstants.keyAppOpenCount) ?? 0}';
      await _prefs.setString(AppConstants.keyUserId, id);
    }
    return id;
  }

  Future<void> setReferrerId(String referrerId) async {
    if (!_inited) return;
    await _prefs.setString(AppConstants.keyReferrerId, referrerId);
  }

  Future<String?> getReferrerId() async {
    if (!_inited) return null;
    return _prefs.getString(AppConstants.keyReferrerId);
  }

  // --- 登录（Google）：user_id / email / photo_url ---
  Future<bool> isLoggedIn() async {
    if (!_inited) return false;
    final id = _prefs.getString(AppConstants.keyAuthUserId);
    return id != null && id.isNotEmpty;
  }

  Future<void> setAuthUser({required String userId, String? email, String? photoUrl}) async {
    if (!_inited) return;
    await _prefs.setString(AppConstants.keyAuthUserId, userId);
    await _prefs.setString(AppConstants.keyAuthEmail, email ?? '');
    await _prefs.setString(AppConstants.keyAuthPhotoUrl, photoUrl ?? '');
  }

  Future<Map<String, String>> getAuthUser() async {
    if (!_inited) return {};
    final id = _prefs.getString(AppConstants.keyAuthUserId);
    if (id == null || id.isEmpty) return {};
    return {
      'userId': id,
      'email': _prefs.getString(AppConstants.keyAuthEmail) ?? '',
      'photoUrl': _prefs.getString(AppConstants.keyAuthPhotoUrl) ?? '',
    };
  }

  Future<void> clearAuthUser() async {
    if (!_inited) return;
    await _prefs.remove(AppConstants.keyAuthUserId);
    await _prefs.remove(AppConstants.keyAuthEmail);
    await _prefs.remove(AppConstants.keyAuthPhotoUrl);
  }

  // --- Free 每日查询次数 ---
  Future<int> getQueryCountToday() async {
    if (!_inited) return 0;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final stored = _prefs.getString(AppConstants.keyQueryCountDate);
    if (stored != today) return 0;
    return _prefs.getInt(AppConstants.keyQueryCountToday) ?? 0;
  }

  Future<void> incrementQueryCountToday() async {
    if (!_inited) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final stored = _prefs.getString(AppConstants.keyQueryCountDate);
    int count = 0;
    if (stored == today) count = _prefs.getInt(AppConstants.keyQueryCountToday) ?? 0;
    await _prefs.setString(AppConstants.keyQueryCountDate, today);
    await _prefs.setInt(AppConstants.keyQueryCountToday, count + 1);
  }

  /// 用户选择的语言（en/zh/ja/ko/fr/ru/de/es），null 表示跟随系统
  Future<String?> getPreferredLocale() async {
    if (!_inited) return null;
    return _prefs.getString(AppConstants.keyPreferredLocale);
  }

  Future<void> setPreferredLocale(String? languageCode) async {
    if (!_inited) return;
    if (languageCode == null || languageCode.isEmpty) {
      await _prefs.remove(AppConstants.keyPreferredLocale);
    } else {
      await _prefs.setString(AppConstants.keyPreferredLocale, languageCode);
    }
  }
}
