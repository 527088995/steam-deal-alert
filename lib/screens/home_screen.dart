import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/storage_service.dart';
import '../core/shock_deal_algorithm.dart';
import '../models/game_model.dart';
import '../models/wishlist_model.dart';
import '../services/steam_api_service.dart';
import '../widgets/ad_banner.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigateToTab});
  final void Function(int tabIndex)? onNavigateToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SteamApiService _api = SteamApiService();
  final StorageService _storage = StorageService.instance;

  List<GameModel> _deals = [];
  List<WishlistItem> _wishlistItems = [];
  bool _firstFetchDone = false;
  String? _lastCheckTime;
  static const int _pageSize = 60;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await _storage.init();
    final cache = await _storage.getCachedDealsAsGames();
    final wishlist = await _storage.getWishlistItems();
    final lastTime = await _storage.getLastCheckTime();
    if (!mounted) return;
    setState(() {
      _deals = ShockDealAlgorithm.deduplicateDeals(cache);
      _wishlistItems = wishlist;
      _lastCheckTime = lastTime;
    });
    _fetchLatestDeals();
  }

  Future<void> _fetchLatestDeals() async {
    List<GameModel> list = [];
    try {
      list = await _api.fetchDeals(pageSize: _pageSize);
    } catch (_) {}
    if (!mounted) return;
    if (list.isNotEmpty) {
      list = ShockDealAlgorithm.deduplicateDeals(list);
      await _storage.setLastDealsCacheFromGames(list);
    }
    final wishlist = await _storage.getWishlistItems();
    final lastTime = await _storage.getLastCheckTime();
    if (mounted) {
      setState(() {
        if (list.isNotEmpty) _deals = list;
        _wishlistItems = wishlist;
        _lastCheckTime = lastTime;
        _firstFetchDone = true;
      });
    }
  }

  void _openDetail(GameModel game) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(appId: game.appId, initialGame: game),
      ),
    );
  }

  /// 今日算法主推大卡（唯一核心）
  Widget _buildShockCard(GameModel? shock) {
    if (shock == null) {
      return AspectRatio(
        aspectRatio: 2.0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF252A33),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Text(
              "Today's Shock Deal",
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ),
        ),
      );
    }
    final priceText = shock.originalPrice > 0
        ? '\$${shock.originalPrice.toStringAsFixed(0)} → \$${shock.price.toStringAsFixed(2)}'
        : '\$${shock.price.toStringAsFixed(2)}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(shock),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 2.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: shock.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) => const ColoredBox(color: Color(0xFF252A33)),
                  errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF252A33)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B3B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "TODAY'S SHOCK DEAL",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shock.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '-${shock.discount}% OFF · $priceText',
                        style: const TextStyle(
                          color: Color(0xFFFFD600),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  /// 每日刷新标识
  Widget _buildUpdatedAt() {
    if (_lastCheckTime == null || _lastCheckTime!.isEmpty) return const SizedBox.shrink();
    String label = 'Updated today';
    try {
      final dt = DateTime.parse(_lastCheckTime!);
      label = 'Updated ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _horizontalList(List<GameModel> games) {
    if (games.isEmpty) return const SizedBox.shrink();
    final listHeight = MediaQuery.of(context).size.width * 0.5;
    final h = listHeight.clamp(160.0, 240.0);
    final w = (h * 0.8).clamp(140.0, 200.0);
    return SizedBox(
      height: h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: w,
              height: h,
              child: _DealCard(
                game: game,
                onTap: () => _openDetail(game),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _horizontalWishlist(List<WishlistItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final listHeight = MediaQuery.of(context).size.width * 0.38;
    final h = listHeight.clamp(120.0, 180.0);
    final w = (h * 0.85).clamp(100.0, 160.0);
    return SizedBox(
      height: h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _WishlistCard(
              item: item,
              width: w,
              height: h,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailScreen(appId: item.appId),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrRetry() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildShockCard(null),
        const SizedBox(height: 48),
        const Center(
          child: Text(
            'No deals loaded',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() => _firstFetchDone = false);
              _fetchLatestDeals();
            },
            icon: const Icon(Icons.refresh, color: Colors.white70),
            label: Text(AppLocalizations.of(context).get('tap_to_retry'), style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildShockCard(null),
        const SizedBox(height: 24),
        _sectionTitle("🔥 ${AppLocalizations.of(context).get('todays_hottest')}"),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _SkeletonDealCard(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('🆕 ${AppLocalizations.of(context).get('section_just_released')}'),
        const SizedBox(height: 12),
        SizedBox(height: 200, child: _SkeletonDealCard()),
        const SizedBox(height: 24),
        _sectionTitle('📈 ${AppLocalizations.of(context).get('section_trending_now')}'),
        const SizedBox(height: 12),
        SizedBox(height: 200, child: _SkeletonDealCard()),
      ],
    );
  }

  Widget _buildDealsList() {
    final cat = ShockDealAlgorithm.computeCategories(_deals);
    final shock = ShockDealAlgorithm.getShockDeal(_deals);

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchLatestDeals();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildShockCard(shock),
          _buildUpdatedAt(),
          _sectionTitle("🔥 ${AppLocalizations.of(context).get('todays_hottest')}"),
          const SizedBox(height: 12),
          _horizontalList(cat.todayHot),
          const SizedBox(height: 24),
          _sectionTitle('🆕 ${AppLocalizations.of(context).get('section_just_released')}'),
          const SizedBox(height: 12),
          _horizontalList(cat.newRelease),
          const SizedBox(height: 24),
          _sectionTitle('📈 ${AppLocalizations.of(context).get('section_trending_now')}'),
          const SizedBox(height: 12),
          _horizontalList(cat.trending),
          const SizedBox(height: 24),
          _sectionTitle('💎 ${AppLocalizations.of(context).get('section_hidden_gems')}'),
          const SizedBox(height: 12),
          _horizontalList(cat.hiddenGems),
          const SizedBox(height: 24),
          _sectionTitle('⭐ ${AppLocalizations.of(context).get('high_rated_cheap')}'),
          const SizedBox(height: 12),
          _horizontalList(cat.highRatedCheap),
          const SizedBox(height: 24),
          _sectionTitle('🎯 ${AppLocalizations.of(context).get('your_wishlist')}'),
          const SizedBox(height: 12),
          _horizontalWishlist(_wishlistItems),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: const Color(0xFF252A33),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => widget.onNavigateToTab?.call(1),
                borderRadius: BorderRadius.circular(14),
                child: const Center(
                  child: Text(
                    AppLocalizations.of(context).get('track_a_game'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AdBanner(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('home_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => widget.onNavigateToTab?.call(1),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => widget.onNavigateToTab?.call(2),
          ),
        ],
      ),
      body: _deals.isNotEmpty
          ? _buildDealsList()
          : _firstFetchDone
              ? _buildEmptyOrRetry()
              : _buildSkeleton(),
    );
  }
}

class _DealCard extends StatelessWidget {
  final GameModel game;
  final VoidCallback onTap;

  const _DealCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final discountText = game.discount > 0 ? '-${game.discount}%' : 'Sale';
    final priceText = game.originalPrice > 0
        ? '\$${game.originalPrice.toStringAsFixed(0)} → \$${game.price.toStringAsFixed(0)}'
        : '\$${game.price.toStringAsFixed(0)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: game.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => const ColoredBox(color: Color(0xFF252A33)),
                errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF252A33)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      discountText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD600),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _WishlistCard({
    required this.item,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF252A33),
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.image.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: item.image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ColoredBox(color: Color(0xFF252A33)),
                    errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF252A33)),
                  )
                else
                  const ColoredBox(color: Color(0xFF252A33)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _SkeletonDealCard extends StatelessWidget {
  const _SkeletonDealCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF252A33),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const ColoredBox(color: Colors.white12),
    );
  }
}
