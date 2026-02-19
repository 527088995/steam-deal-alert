import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/score_calculator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/game_model.dart';

/// 今日 #1 超大 Banner：占屏 40%、红胶囊（字体大于价格）、倒计时实时跳动、View Details
class TopDealBanner extends StatefulWidget {
  final GameModel? game;
  final VoidCallback? onTap;

  const TopDealBanner({super.key, this.game, this.onTap});

  @override
  State<TopDealBanner> createState() => _TopDealBannerState();
}

class _TopDealBannerState extends State<TopDealBanner> {
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final bannerH = screenH * 0.40;

    if (widget.game == null) {
      return SizedBox(
        height: bannerH,
        child: _placeholder(),
      );
    }
    final g = widget.game!;

    return SizedBox(
      height: bannerH,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        elevation: 8,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: g.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(color: AppColors.card),
                  errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.card),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.92),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.itadOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      g.discount > 0 ? '-${g.discount}%' : AppLocalizations.of(context).get('sale_label'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.neonPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'AI ${calculateScore(g).toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          g.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '\$${g.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.itadOrangeLight,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Steam',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (g.originalPrice > 0)
                          Text(
                            '\$${g.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: Material(
                            color: AppColors.itadOrange,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: widget.onTap,
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context).get('view_details'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          AppLocalizations.of(context).get('todays_top_deal'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 18),
        ),
      ),
    );
  }
}
