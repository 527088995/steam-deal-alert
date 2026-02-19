import 'package:flutter/foundation.dart';
import 'game_model.dart';

class WishlistItem {
  final String appId;
  final String name;
  final String image;
  final DateTime addedAt;
  final int targetDiscount;

  WishlistItem({
    required this.appId,
    required this.name,
    this.image = '',
    DateTime? addedAt,
    this.targetDiscount = 0,
  }) : addedAt = addedAt ?? DateTime.now();

  factory WishlistItem.fromGame(GameModel game, {int targetDiscount = 0}) {
    return WishlistItem(
      appId: game.appId,
      name: game.name,
      image: game.image,
      targetDiscount: targetDiscount,
    );
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      appId: json['appId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetDiscount: (json['targetDiscount'] is int)
          ? json['targetDiscount'] as int
          : (json['targetDiscount'] is num)
              ? (json['targetDiscount'] as num).toInt()
              : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'appId': appId,
        'name': name,
        'image': image,
        'addedAt': addedAt.toIso8601String(),
        'targetDiscount': targetDiscount,
      };
}
