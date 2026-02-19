import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/colors.dart';
import '../core/utils/score_calculator.dart';
import '../models/game_model.dart';

class GameCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback? onTap;
  final bool showWishlistButton;
  final bool isInWishlist;
  final VoidCallback? onWishlistToggle;

  const GameCard({
    super.key,
    required this.game,
    this.onTap,
    this.showWishlistButton = true,
    this.isInWishlist = false,
    this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.cardDark,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.topLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: game.image,
                      width: 96,
                      height: 54,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(color: AppColors.cardElevated),
                      errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.cardElevated),
                    ),
                  ),
                  if (game.discount > 0)
                    Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.itadOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${game.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        calculateScore(game).toStringAsFixed(1),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 14,
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
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          '\$${game.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.itadOrangeLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Steam',
                            style: TextStyle(
                              fontSize: 10,
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
              if (showWishlistButton)
                IconButton(
                  icon: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? AppColors.discountRed : AppColors.textSecondary,
                  ),
                  onPressed: onWishlistToggle ?? () {},
                ),
            ],
          ),
        ),
      ),
    );
  }
}
