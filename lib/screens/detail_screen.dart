import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:share_plus/share_plus.dart';
import '../core/notification_permission_helper.dart';
import '../core/storage_service.dart';
import '../core/interstitial_helper.dart';
import '../core/theme/colors.dart';
import '../core/utils/countdown_util.dart';
import '../core/utils/score_calculator.dart';
import '../models/game_model.dart';
import '../models/wishlist_model.dart';
import '../services/steam_api_service.dart';
import '../widgets/discount_badge.dart';
import '../widgets/ad_banner.dart';

class DetailScreen extends StatefulWidget {
  final String appId;
  /// 从列表点进来时传入，API 失败或返回空时用此项显示
  final GameModel? initialGame;

  const DetailScreen({super.key, required this.appId, this.initialGame});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final SteamApiService _api = SteamApiService();
  final StorageService _storage = StorageService.instance;
  GameModel? _game;
  bool _inWishlist = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    GameModel game = await _api.fetchGameById(widget.appId);
    if (game.name.isEmpty || game.name.startsWith('Game #')) {
      if (widget.initialGame != null) game = widget.initialGame!;
    }
    final inList = await _storage.isInWishlist(widget.appId);
    if (mounted) {
      setState(() {
        _game = game;
        _inWishlist = inList;
        _loading = false;
      });
      if (await InterstitialHelper.tryShowAfterDetailView()) {
        // TODO: 展示插屏广告
      }
    }
  }

  Future<void> _openSteamStore(String steamAppID) async {
    final uri = Uri.parse('https://store.steampowered.com/app/$steamAppID');
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleWishlist() async {
    final game = _game;
    if (game == null) return;
    if (_inWishlist) {
      await _storage.removeFromWishlist(game.appId);
    } else {
      await _storage.addToWishlist(WishlistItem.fromGame(game));
      await NotificationPermissionHelper.maybeRequestWithRationale(context);
    }
    setState(() => _inWishlist = !_inWishlist);
  }

  Widget _sectionCard(String title, String value, String subtitle) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(String text, String author, int stars) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) => Icon(Icons.star, size: 16, color: i < stars ? AppColors.gold : AppColors.textSecondary)),
            ),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(author, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).get('loading'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final game = _game;
    if (game == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).get('game'))),
        body: Center(child: Text(AppLocalizations.of(context).get('failed_to_load_game'))),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          game.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).get('share_return_hint')),
                  duration: const Duration(seconds: 4),
                ),
              );
              final steamUrl = game.steamAppID.isNotEmpty
                  ? 'https://store.steampowered.com/app/${game.steamAppID}'
                  : '';
              Share.share(
                '🔥 ${game.name}\nNow \$${game.price.toStringAsFixed(2)}\n$steamUrl',
              );
            },
          ),
          IconButton(
            icon: Icon(
              _inWishlist ? Icons.favorite : Icons.favorite_border,
              color: _inWishlist ? AppColors.danger : AppColors.textSecondary,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (game.images.isNotEmpty || game.image.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final urls = game.images.isNotEmpty ? game.images : [game.image];
                  final w = MediaQuery.of(context).size.width;
                  final h = 220.0;
                  if (urls.length <= 1) {
                    return SizedBox(
                      width: w,
                      height: h,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: urls.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(color: AppColors.card),
                          errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.card),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: h,
                    child: PageView.builder(
                      itemCount: urls.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: urls[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ColoredBox(color: AppColors.card),
                            errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.card),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: theme.textTheme.titleLarge!.copyWith(fontSize: 22, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\$${game.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (game.originalPrice > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '\$${game.originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        if (game.discount > 0) ...[
                          const SizedBox(width: 12),
                          DiscountBadge(discount: game.discount),
                        ],
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final endsIn = game.saleEndTime > 0
                          ? formatCountdown(game.saleEndTime)
                          : (game.lastChange > 0 ? formatLastChange(game.lastChange) : '');
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          endsIn.isNotEmpty ? (game.saleEndTime > 0 ? '${AppLocalizations.of(context).get('ends_in')} $endsIn' : endsIn) : '—',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _sectionCard('🔥 ${AppLocalizations.of(context).get('ai_score')}', calculateScore(game).toStringAsFixed(1), AppLocalizations.of(context).get('based_on_discount')),
                  const SizedBox(height: 24),
                  _sectionCard('📉 ${AppLocalizations.of(context).get('price_history')}', AppLocalizations.of(context).get('lowest_price_30_days'), AppLocalizations.of(context).get('price_history_tap_chart')),
                  const SizedBox(height: 24),
                  Text(
                    '💬 ${AppLocalizations.of(context).get('top_community_reviews')}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _reviewCard('Great deal!', 'User123', 5),
                  const SizedBox(height: 12),
                  _reviewCard('Worth every penny.', 'DealHunter', 5),
                  const SizedBox(height: 12),
                  _reviewCard('Best price I\'ve seen.', 'SteamFan', 5),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _toggleWishlist,
                      icon: Icon(_inWishlist ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 22),
                      label: Text(_inWishlist ? AppLocalizations.of(context).get('remove_from_wishlist') : AppLocalizations.of(context).get('add_to_wishlist')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _inWishlist ? AppColors.danger : AppColors.itadOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (game.steamAppID.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _openSteamStore(game.steamAppID),
                        icon: const Icon(Icons.open_in_new, size: 20),
                        label: Text(AppLocalizations.of(context).get('view_on_steam')),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const AdBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
