import 'package:flutter/foundation.dart';

/// 游戏/折扣信息，兼容 CheapShark API 字段
/// appId 在 CheapShark 下为 dealID，用于拉取详情
class GameModel {
  final String appId;
  final String name;
  final String image;
  final double price;
  final double originalPrice;
  final int discount;
  final String steamAppID;
  final String steamRatingText;
  final String metacriticScore;
  final String dealID;
  /// Steam 评价数量，用于排序「最热门」
  final int steamRatingCount;
  /// 折扣最后更新时间（Unix 秒），0 表示未知；用于「最近更新」算法
  final int lastChange;
  /// 游戏发售日（Unix 秒），0 表示未知；用于「新游戏」模块
  final int releaseDate;
  /// 折扣结束时间（Unix 秒），0 表示未知；用于「Ends in」倒计时
  final int saleEndTime;
  /// 多图时使用（详情/轮播），为空则用 [image]
  final List<String> images;

  GameModel({
    required this.appId,
    required this.name,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.discount,
    this.steamAppID = '',
    this.steamRatingText = '',
    this.metacriticScore = '',
    this.dealID = '',
    this.steamRatingCount = 0,
    this.lastChange = 0,
    this.releaseDate = 0,
    this.saleEndTime = 0,
    List<String>? images,
  }) : images = images ?? const [];

  /// 从 CheapShark /deals 列表项解析
  factory GameModel.fromCheapSharkDeal(Map<String, dynamic> json) {
    final salePrice = _parseDouble(json['salePrice'], 0.0);
    final normalPrice = _parseDouble(json['normalPrice'], 0.0);
    final savings = _parseDouble(json['savings'], 0.0);
    final count = json['steamRatingCount'];
    final ratingCount = count is int ? count : (count is num ? count.toInt() : int.tryParse(count?.toString() ?? '0') ?? 0);
    final lc = json['lastChange'];
    final lastChangeSec = lc == null ? 0 : (lc is int ? lc : (lc is num ? lc.toInt() : int.tryParse(lc.toString()) ?? 0));
    final rd = json['releaseDate'];
    final releaseSec = rd == null ? 0 : (rd is int ? rd : (rd is num ? rd.toInt() : int.tryParse(rd.toString()) ?? 0));
    final thumb = json['thumb']?.toString() ?? '';
    return GameModel(
      dealID: json['dealID']?.toString() ?? '',
      appId: json['dealID']?.toString() ?? '',
      name: json['title']?.toString() ?? '',
      image: thumb,
      price: salePrice,
      originalPrice: normalPrice,
      discount: savings.round(),
      steamAppID: json['steamAppID']?.toString() ?? '',
      steamRatingText: json['steamRatingText']?.toString() ?? '',
      metacriticScore: json['metacriticScore']?.toString() ?? '',
      steamRatingCount: ratingCount,
      lastChange: lastChangeSec,
      releaseDate: releaseSec,
      saleEndTime: _parseInt(json['saleEndTime'], 0),
      images: thumb.isNotEmpty ? [thumb] : [],
    );
  }

  /// 从 CheapShark /deals?id= 详情 gameInfo 解析（点击游戏时从 API 拉取）
  factory GameModel.fromCheapSharkGameInfo(String dealId, Map<String, dynamic> gameInfo) {
    final salePrice = _parseDouble(gameInfo['salePrice'], 0.0);
    final retailPrice = _parseDouble(gameInfo['retailPrice'], 0.0);
    final discount = retailPrice > 0
        ? ((1 - salePrice / retailPrice) * 100).round()
        : 0;
    final count = gameInfo['steamRatingCount'];
    final ratingCount = count is int ? count : (count is num ? count.toInt() : int.tryParse(count?.toString() ?? '0') ?? 0);
    final thumb = gameInfo['thumb']?.toString() ?? '';
    final pics = gameInfo['screenshots'];
    List<String> imgList = [];
    if (pics is List && pics.isNotEmpty) {
      for (final p in pics) {
        if (p is Map && p['full'] != null) imgList.add(p['full'].toString());
      }
    }
    if (imgList.isEmpty && thumb.isNotEmpty) imgList = [thumb];
    return GameModel(
      dealID: dealId,
      appId: dealId,
      name: gameInfo['name']?.toString() ?? '',
      image: thumb,
      price: salePrice,
      originalPrice: retailPrice,
      discount: discount,
      steamAppID: gameInfo['steamAppID']?.toString() ?? '',
      steamRatingText: gameInfo['steamRatingText']?.toString() ?? '',
      metacriticScore: gameInfo['metacriticScore']?.toString() ?? '',
      steamRatingCount: ratingCount,
      saleEndTime: _parseInt(gameInfo['saleEndTime'], 0),
      images: imgList,
    );
  }

  static double _parseDouble(dynamic v, double def) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  static int _parseInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  factory GameModel.fromJson(Map<String, dynamic> json) {
    final img = json['image']?.toString() ?? json['thumb']?.toString() ?? '';
    return GameModel(
      appId: json['appid']?.toString() ?? json['dealID']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      image: img,
      price: _parseDouble(json['price'] ?? json['salePrice'], 0.0),
      originalPrice: _parseDouble(json['original_price'] ?? json['normalPrice'] ?? json['retailPrice'], 0.0),
      discount: (json['discount_percent'] is int)
          ? json['discount_percent'] as int
          : (json['discount_percent'] is num)
              ? (json['discount_percent'] as num).toInt()
              : (json['savings'] is num)
                  ? (json['savings'] as num).round()
                  : 0,
      steamAppID: json['steamAppID']?.toString() ?? '',
      steamRatingText: json['steamRatingText']?.toString() ?? '',
      metacriticScore: json['metacriticScore']?.toString() ?? '',
      dealID: json['dealID']?.toString() ?? '',
      steamRatingCount: _parseInt(json['steamRatingCount'], 0),
      lastChange: _parseInt(json['last_change'], 0),
      releaseDate: _parseInt(json['release_date'], 0),
      saleEndTime: _parseInt(json['sale_end_time'], 0),
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? (img.isNotEmpty ? [img] : []),
    );
  }

  Map<String, dynamic> toJson() => {
        'appid': appId,
        'name': name,
        'image': image,
        'price': price,
        'original_price': originalPrice,
        'discount_percent': discount,
        if (steamAppID.isNotEmpty) 'steamAppID': steamAppID,
        if (dealID.isNotEmpty) 'dealID': dealID,
        if (lastChange > 0) 'last_change': lastChange,
        if (releaseDate > 0) 'release_date': releaseDate,
      };
}
