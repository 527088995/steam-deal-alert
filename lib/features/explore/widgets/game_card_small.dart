import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/score_calculator.dart';
import '../../../models/game_model.dart';

/// Explore 横滑用：小卡片，圆角 20，elevation 6
class GameCardSmall extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const GameCardSmall({super.key, required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Material(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: game.image,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ColoredBox(color: AppColors.bgDark),
                        errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.bgDark),
                      ),
                    ),
                    if (game.discount > 0)
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.itadOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${game.discount}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'AI ${calculateScore(game).toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (game.originalPrice > 0)
                        Text(
                          '\$${game.originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Row(
                        children: [
                          Text(
                            '\$${game.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.itadOrangeLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Steam',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
