import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/game_model.dart';

/// 使用 CheapShark 公开 API 获取折扣列表与详情
/// 文档: https://apidocs.cheapshark.com/
class SteamApiService {
  static const String _baseUrl = 'https://www.cheapshark.com/api/1.0';

  /// 拉取当前折扣列表（分页），5 秒超时防止卡死
  Future<List<GameModel>> fetchDeals({int pageSize = 25, int pageNumber = 0}) async {
    try {
      final uri = Uri.parse('$_baseUrl/deals').replace(
        queryParameters: <String, String>{
          'pageSize': pageSize.toString(),
          'pageNumber': pageNumber.toString(),
        },
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Deals request timeout'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((e) => GameModel.fromCheapSharkDeal(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('fetchDeals error: $e');
    }
    return [];
  }

  /// 按 dealID 拉取单条折扣详情（用于详情页）
  Future<GameModel> fetchGameById(String dealId) async {
    if (dealId.isEmpty) return _emptyGame('');
    try {
      final uri = Uri.parse('$_baseUrl/deals').replace(
        queryParameters: <String, String>{'id': dealId},
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Detail request timeout'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final gameInfo = data['gameInfo'] as Map<String, dynamic>?;
        if (gameInfo != null) {
          return GameModel.fromCheapSharkGameInfo(dealId, gameInfo);
        }
      }
    } catch (e) {
      debugPrint('fetchGameById error: $e');
    }
    return _emptyGame(dealId);
  }

  Future<GameModel> fetchGameDetail(String appId) async {
    return fetchGameById(appId);
  }

  GameModel _emptyGame(String id) {
    return GameModel(
      appId: id,
      name: 'Game #$id',
      image: '',
      price: 0,
      originalPrice: 0,
      discount: 0,
    );
  }

  /// 从 Steam 商店 API 拉取游戏截图（多图轮播用），返回 path_full 列表，最多 12 张
  Future<List<String>> fetchSteamScreenshots(String steamAppID) async {
    if (steamAppID.isEmpty) return [];
    try {
      final uri = Uri.parse('https://store.steampowered.com/api/appdetails').replace(
        queryParameters: <String, String>{'appids': steamAppID, 'l': 'en'},
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 6),
        onTimeout: () => throw Exception('Steam store timeout'),
      );
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final appData = data[steamAppID];
      if (appData is! Map<String, dynamic>) return [];
      final success = appData['success'];
      if (success != true) return [];
      final gameData = appData['data'] as Map<String, dynamic>?;
      if (gameData == null) return [];
      final screenshots = gameData['screenshots'];
      if (screenshots is! List || screenshots.isEmpty) return [];
      final urls = <String>[];
      for (final s in screenshots.take(12)) {
        if (s is Map && s['path_full'] != null) {
          urls.add(s['path_full'].toString());
        }
      }
      return urls;
    } catch (e) {
      debugPrint('fetchSteamScreenshots error: $e');
      return [];
    }
  }

  /// Steam 评测单项（内容、作者、点赞数、时间、语言）
  static Map<String, dynamic> parseReview(Map<String, dynamic> r) {
    final author = r['author'];
    final authorStr = author is Map
        ? (author['steamid']?.toString() ?? 'User')
        : (author?.toString().isNotEmpty == true ? author.toString() : 'User');
    final ts = r['timestamp_created'];
    final created = ts is int ? ts : (ts is num ? ts.toInt() : int.tryParse(ts?.toString() ?? '0') ?? 0);
    final updated = r['timestamp_updated'];
    final updatedSec = updated is int ? updated : (updated is num ? updated.toInt() : int.tryParse(updated?.toString() ?? '0') ?? 0);
    return {
      'content': r['review']?.toString().replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '',
      'author': authorStr,
      'votes_up': (r['votes_up'] is int) ? r['votes_up'] as int : int.tryParse(r['votes_up']?.toString() ?? '0') ?? 0,
      'voted_up': r['voted_up'] == true,
      'language': r['language']?.toString() ?? '',
      'timestamp_created': created,
      'timestamp_updated': updatedSec > 0 ? updatedSec : created,
    };
  }

  /// 拉取 Steam 评测，按点赞数排序后取前 topN 条（最多 3 条）
  Future<List<Map<String, dynamic>>> fetchSteamReviews(String steamAppID, {int topN = 3}) async {
    if (steamAppID.isEmpty) return [];
    try {
      final uri = Uri.parse('https://store.steampowered.com/appreviews/$steamAppID').replace(
        queryParameters: <String, String>{
          'json': '1',
          'language': 'all',
          'num_per_page': '30',
          'filter': 'recent',
        },
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 6),
        onTimeout: () => throw Exception('Steam reviews timeout'),
      );
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reviews = data['reviews'];
      if (reviews is! List || reviews.isEmpty) return [];
      final list = <Map<String, dynamic>>[];
      for (final r in reviews) {
        if (r is Map<String, dynamic>) list.add(parseReview(r));
      }
      list.sort((a, b) => ((b['votes_up'] as int?) ?? 0).compareTo((a['votes_up'] as int?) ?? 0));
      return list.take(topN).where((e) => (e['content'] as String).isNotEmpty).toList();
    } catch (e) {
      debugPrint('fetchSteamReviews error: $e');
      return [];
    }
  }

  /// 价格历史折线图用：无真实 API 时用当前价+原价构造两点（过去→现在）
  List<Map<String, dynamic>> getPriceHistoryPoints(double currentPrice, double originalPrice, {int lastChangeSec = 0}) {
    final now = DateTime.now();
    final past = lastChangeSec > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastChangeSec * 1000)
        : now.subtract(const Duration(days: 30));
    return [
      {'t': past.millisecondsSinceEpoch, 'price': originalPrice},
      {'t': now.millisecondsSinceEpoch, 'price': currentPrice},
    ];
  }

  /// 优先拉取 IsThereAnyDeal 真实价格历史；无 key 或失败时返回 fallback 两点
  Future<List<Map<String, dynamic>>> fetchPriceHistory(
    String steamAppID,
    double currentPrice,
    double originalPrice, {
    int lastChangeSec = 0,
  }) async {
    if (AppConstants.itadApiKey.trim().isNotEmpty && steamAppID.isNotEmpty) {
      final fromItad = await fetchPriceHistoryFromItad(steamAppID);
      if (fromItad.isNotEmpty) return fromItad;
    }
    return getPriceHistoryPoints(
      currentPrice,
      originalPrice > 0 ? originalPrice : currentPrice,
      lastChangeSec: lastChangeSec,
    );
  }

  static const String _itadBase = 'https://api.isthereanydeal.com';

  /// IsThereAnyDeal：先 lookup 再取 history，返回 [ {t: ms, price}, ... ]
  Future<List<Map<String, dynamic>>> fetchPriceHistoryFromItad(String steamAppID) async {
    final key = AppConstants.itadApiKey.trim();
    if (key.isEmpty) return [];
    try {
      final lookupUri = Uri.parse('$_itadBase/v01/games/lookup/v1').replace(
        queryParameters: <String, String>{'key': key, 'appid': steamAppID},
      );
      final lookupResp = await http.get(lookupUri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('ITAD lookup timeout'),
      );
      if (lookupResp.statusCode != 200) return [];
      final lookupData = jsonDecode(lookupResp.body) as Map<String, dynamic>;
      final game = lookupData['data'] ?? lookupData['game'];
      if (game is! Map<String, dynamic>) return [];
      final plain = game['plain']?.toString() ?? game['id']?.toString();
      if (plain == null || plain.isEmpty) return [];

      final historyUri = Uri.parse('$_itadBase/v01/game/history/').replace(
        queryParameters: <String, String>{'key': key, 'plain': plain, 'region': 'us', 'country': 'US'},
      );
      final historyResp = await http.get(historyUri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('ITAD history timeout'),
      );
      if (historyResp.statusCode != 200) return [];
      final historyData = jsonDecode(historyResp.body) as Map<String, dynamic>;
      final list = historyData['data'] ?? historyData['list'] ?? historyData['history'];
      if (list is! List || list.isEmpty) return [];

      final points = <Map<String, dynamic>>[];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final priceVal = (e['price'] is num) ? (e['price'] as num).toDouble() : double.tryParse(e['price']?.toString() ?? '');
        final amountVal = (e['amount'] is num) ? (e['amount'] as num).toDouble() : double.tryParse(e['amount']?.toString() ?? '');
        final value = priceVal ?? amountVal;
        if (value == null) continue;
        final dateStr = e['date']?.toString() ?? e['timestamp']?.toString();
        int tMs = 0;
        if (dateStr != null && dateStr.isNotEmpty) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null) tMs = dt.millisecondsSinceEpoch;
        }
        if (tMs == 0 && e['ts'] != null) tMs = (e['ts'] is int) ? (e['ts'] as int) * 1000 : (int.tryParse(e['ts']?.toString() ?? '0') ?? 0) * 1000;
        if (tMs == 0) continue;
        points.add({'t': tMs, 'price': value});
      }
      points.sort((a, b) => (a['t'] as int).compareTo(b['t'] as int));
      return points;
    } catch (e) {
      debugPrint('fetchPriceHistoryFromItad error: $e');
      return [];
    }
  }

  /// 按游戏名搜索（CheapShark /games）
  Future<List<GameModel>> searchGames(String title, {int pageSize = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/games').replace(
        queryParameters: <String, String>{
          'title': title,
          'pageSize': pageSize.toString(),
        },
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Search request timeout'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final list = <GameModel>[];
          for (final e in data) {
            final m = e as Map<String, dynamic>;
            final dealId = m['cheapestDealID']?.toString();
            final cheapest = m['cheapest']?.toString();
            final titleStr = m['external']?.toString() ?? m['internalName']?.toString() ?? '';
            final steamId = m['steamAppID']?.toString();
            final thumb = m['thumb']?.toString();
            if (dealId != null && dealId.isNotEmpty) {
              list.add(GameModel(
                appId: dealId,
                dealID: dealId,
                name: titleStr,
                image: thumb ?? '',
                price: cheapest != null ? double.tryParse(cheapest) ?? 0 : 0,
                originalPrice: 0,
                discount: 0,
                steamAppID: steamId ?? '',
              ));
            }
          }
          return list;
        }
      }
    } catch (e) {
      debugPrint('searchGames error: $e');
    }
    return [];
  }
}
