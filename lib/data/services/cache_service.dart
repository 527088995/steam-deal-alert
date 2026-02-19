import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/game_model.dart';
/// 数据层：Hive 本地缓存，启动秒开
class CacheService {
  static const String _boxName = 'deal_cache';
  static const String _keyDeals = 'deals';

  static bool _inited = false;
  static bool get isInitialized => _inited;

  static Future<void> init() async {
    if (_inited) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox(_boxName);
      _inited = true;
    } catch (_) {}
  }

  static Future<List<GameModel>> loadGames() async {
    try {
      final box = Hive.box(_boxName);
      final jsonStr = box.get(_keyDeals) as String?;
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => GameModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGames(List<GameModel> games) async {
    try {
      final list = games.map((g) => g.toJson()).toList();
      final box = Hive.box(_boxName);
      await box.put(_keyDeals, jsonEncode(list));
      await box.put('last_check_time', DateTime.now().toIso8601String());
    } catch (_) {}
  }

  static Future<String?> getLastCheckTime() async {
    try {
      return Hive.box(_boxName).get('last_check_time') as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastCheckTime(String iso) async {
    try {
      await Hive.box(_boxName).put('last_check_time', iso);
    } catch (_) {}
  }
}
