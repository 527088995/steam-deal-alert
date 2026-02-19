import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/models/game.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/algorithm_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/utils/countdown_util.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/steam_api_service.dart';
import '../../../widgets/ad_banner.dart';

/// 商业版详情页：多图轮播 + 折扣 + AI 评分 + Steam 跳转 + 分享(deep link) + 愿望单 + 倒计时
class GameDetailPage extends StatefulWidget {
  final GameModel game;

  const GameDetailPage({super.key, required this.game});

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  final WishlistService _wishlist = WishlistService();
  final SteamApiService _steamApi = SteamApiService();
  late PageController _pageController;
  bool _inWishlist = false;
  List<String> _imageUrls = [];
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _pricePoints = [];
  List<Map<String, dynamic>> _topReviews = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imageUrls = widget.game.images.isNotEmpty
        ? List<String>.from(widget.game.images)
        : (widget.game.image.isNotEmpty ? [widget.game.image] : []);
    _checkWishlist();
    _loadMoreImages();
    _loadPriceHistory();
    _loadReviews();
  }

  Future<void> _loadPriceHistory() async {
    final g = widget.game;
    final points = await _steamApi.fetchPriceHistory(
      g.steamAppID,
      g.price,
      g.originalPrice > 0 ? g.originalPrice : g.price,
      lastChangeSec: g.lastChange,
    );
    if (mounted) setState(() => _pricePoints = points);
  }

  Future<void> _loadReviews() async {
    if (widget.game.steamAppID.isEmpty) return;
    final list = await _steamApi.fetchSteamReviews(widget.game.steamAppID, topN: 3);
    if (mounted) setState(() => _topReviews = list);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 若当前只有 1 张图且有 steamAppID，从 Steam 商店 API 拉取多张截图用于轮播
  Future<void> _loadMoreImages() async {
    if (_imageUrls.length > 1) return;
    final steamId = widget.game.steamAppID;
    if (steamId.isEmpty) return;
    try {
      final list = await _steamApi.fetchSteamScreenshots(steamId);
      if (list.isEmpty || !mounted) return;
      final first = widget.game.image.isNotEmpty ? widget.game.image : (list.isNotEmpty ? list.first : '');
      final rest = list.where((u) => u != first).toList();
      final combined = first.isNotEmpty ? [first, ...rest] : list;
      if (combined.length > 1 && mounted) {
        setState(() => _imageUrls = combined);
      }
    } catch (_) {}
  }

  Future<void> _checkWishlist() async {
    final inList = await _wishlist.isInWishlist(widget.game.appId);
    if (mounted) setState(() => _inWishlist = inList);
  }

  String get _storeUrl => widget.game.steamAppID.isNotEmpty
      ? 'https://store.steampowered.com/app/${widget.game.steamAppID}'
      : '';

  Future<void> _openSteam() async {
    if (_storeUrl.isEmpty) return;
    final uri = Uri.parse(_storeUrl);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleWishlist() async {
    if (_inWishlist) {
      await _wishlist.remove(widget.game.appId);
    } else {
      await _wishlist.add(widget.game);
    }
    if (mounted) setState(() => _inWishlist = !_inWishlist);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final l10n = AppLocalizations.of(context);
    final score = AlgorithmService().calculateScore(game);
    final imageUrls = _imageUrls.isNotEmpty ? _imageUrls : (game.image.isNotEmpty ? [game.image] : []);
    final hasImages = imageUrls.isNotEmpty && imageUrls.first.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF151A22),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImages
                  ? PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentImageIndex = i),
                      itemCount: imageUrls.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: imageUrls[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ColoredBox(color: AppColors.cardDark),
                        errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.cardDark),
                      ),
                    )
                  : const ColoredBox(color: AppColors.cardDark),
            ),
            bottom: imageUrls.length > 1
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(24),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageUrls.length.clamp(0, 10),
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentImageIndex ? Colors.white : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            actions: [
              IconButton(
                icon: Icon(_inWishlist ? Icons.favorite : Icons.favorite_border),
                color: _inWishlist ? AppColors.discountRed : Colors.white70,
                onPressed: _toggleWishlist,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.get('share_return_hint')), duration: const Duration(seconds: 4)),
                    );
                  }
                  Share.share(
                    'Check this deal: ${game.name} 🔥\n\$${game.price.toStringAsFixed(2)}\n$_storeUrl',
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _priceSection(),
                      const Spacer(),
                      _aiScore(score),
                    ],
                  ),
                  if (game.saleEndTime > 0 || game.lastChange > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        game.saleEndTime > 0
                            ? 'Ends in ${formatCountdown(game.saleEndTime)}'
                            : (game.lastChange > 0 ? formatLastChange(game.lastChange) : ''),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _toggleWishlist,
                      icon: Icon(_inWishlist ? Icons.favorite : Icons.favorite_border, size: 20),
                      label: Text(_inWishlist ? l10n.get('remove_from_wishlist') : l10n.get('add_to_wishlist')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _inWishlist ? AppColors.discountRed : AppColors.itadOrange,
                        side: BorderSide(color: _inWishlist ? AppColors.discountRed : AppColors.itadOrange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AdBanner(),
                  const SizedBox(height: 20),
                  _sectionCard(
                    l10n.get('ai_score'),
                    score.toStringAsFixed(1),
                    l10n.get('based_on_discount'),
                    valueColor: AppColors.neonPurple,
                  ),
                  const SizedBox(height: 14),
                  _priceHistoryCard(context, game),
                  const SizedBox(height: 14),
                  _reviewsSection(context, game),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.get('share_return_hint')), duration: const Duration(seconds: 4)),
                              );
                            }
                            Share.share(
                              'Check this deal: ${game.name} 🔥\n\$${game.price.toStringAsFixed(2)}\n$_storeUrl',
                            );
                          },
                          icon: const Icon(Icons.share, size: 20),
                          label: Text(l10n.get('share')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.textSecondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (game.steamAppID.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openSteam,
                            icon: const Icon(Icons.open_in_new, size: 20),
                            label: Text(l10n.get('view_on_steam')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.itadOrange,
                              side: const BorderSide(color: AppColors.itadOrange),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPriceHistoryDate(int tMs) {
    return DateFormat('MM/dd').format(DateTime.fromMillisecondsSinceEpoch(tMs));
  }

  Widget _priceHistoryCard(BuildContext context, GameModel game) {
    final l10n = AppLocalizations.of(context);
    final points = _pricePoints;
    if (points.isEmpty) {
      return _sectionCard(
        l10n.get('price_history'),
        '—',
        l10n.get('price_history_no_history'),
        onTap: game.steamAppID.isNotEmpty ? _openSteam : null,
      );
    }
    final spots = points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['price'] as num).toDouble())).toList();
    final prices = points.map((p) => (p['price'] as num).toDouble()).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final minY = (minP - 1).clamp(0.0, double.infinity);
    final maxY = maxP + 1;
    final showBottomAt = <int>{0, points.length ~/ 2, points.length - 1}.where((i) => i >= 0 && i < points.length).toSet();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('price_history'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.itadOrange,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppColors.itadOrange.withOpacity(0.15)),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= points.length || !showBottomAt.contains(i)) return const SizedBox.shrink();
                    final t = points[i]['t'];
                    final tMs = t is int ? t : (t is num ? t.toInt() : 0);
                    final dateStr = tMs > 0 ? _formatPriceHistoryDate(tMs) : '';
                    final price = (points[i]['price'] as num).toStringAsFixed(2);
                    return Text('$dateStr\n\$$price', style: const TextStyle(color: AppColors.textSecondary, fontSize: 9), textAlign: TextAlign.center, maxLines: 2);
                  })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.textSecondary.withOpacity(0.2))),
                borderData: FlBorderData(show: false),
              ),
              duration: const Duration(milliseconds: 200),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: points.length,
              itemBuilder: (_, i) {
                final t = points[i]['t'];
                final tMs = t is int ? t : (t is num ? t.toInt() : 0);
                final dateStr = tMs > 0 ? _formatPriceHistoryDate(tMs) : '—';
                final price = (points[i]['price'] as num).toStringAsFixed(2);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        Text('\$$price', style: const TextStyle(color: AppColors.itadOrangeLight, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (game.steamAppID.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: _openSteam,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.get('view_full_history_steam'), style: const TextStyle(fontSize: 12, color: AppColors.itadOrange, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new, size: 12, color: AppColors.itadOrange),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard(String title, String value, String subtitle, {Color? valueColor, VoidCallback? onTap}) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.itadOrange,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      );
    }
    return card;
  }

  Widget _reviewsSection(BuildContext context, GameModel game) {
    final l10n = AppLocalizations.of(context);
    final hasSteam = game.steamAppID.isNotEmpty;
    final reviewsUrl = hasSteam ? 'https://store.steampowered.com/app/${game.steamAppID}/#app_reviews_hash' : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('top_community_reviews'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (game.steamRatingText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              game.steamRatingText,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            if (game.steamRatingCount > 0) Text('${game.steamRatingCount} ${l10n.get('reviews_count')}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
          if (_topReviews.isEmpty && hasSteam)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(height: 24, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))),
          ..._topReviews.map((r) => _reviewTile(r, l10n)),
          if (hasSteam) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                if (reviewsUrl.isEmpty) return;
                final uri = Uri.parse(reviewsUrl);
                if (await url_launcher.canLaunchUrl(uri)) {
                  await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.get('see_more_on_steam'), style: const TextStyle(fontSize: 13, color: AppColors.itadOrange, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new, size: 14, color: AppColors.itadOrange),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> r, AppLocalizations l10n) {
    final content = (r['content'] as String?) ?? '';
    if (content.isEmpty) return const SizedBox.shrink();
    final text = content.length > 200 ? '${content.substring(0, 200)}…' : content;
    final votes = (r['votes_up'] as int?) ?? 0;
    final votedUp = r['voted_up'] == true;
    final language = (r['language'] as String?) ?? '';
    final ts = (r['timestamp_created'] as int?) ?? 0;
    String timeStr = '';
    if (ts > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays > 365) timeStr = '${(diff.inDays / 365).floor()}y ago';
      else if (diff.inDays > 30) timeStr = '${diff.inDays ~/ 30}mo ago';
      else if (diff.inDays > 0) timeStr = '${diff.inDays}d ago';
      else if (diff.inHours > 0) timeStr = '${diff.inHours}h ago';
      else if (diff.inMinutes > 0) timeStr = '${diff.inMinutes}m ago';
      else timeStr = l10n.get('just_now');
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(votedUp ? Icons.thumb_up : Icons.thumb_down, size: 14, color: votedUp ? AppColors.itadOrange : AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.35)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$votes ${l10n.get('reviews_helpful')}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    if (timeStr.isNotEmpty) ...[
                      const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                    if (language.isNotEmpty) ...[
                      const Text(' · ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(language, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceSection() {
    final game = widget.game;
    return Row(
      children: [
        Text(
          '\$${game.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.itadOrangeLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (game.originalPrice > 0) ...[
          const SizedBox(width: 8),
          Text(
            '\$${game.originalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          if (game.discount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.itadOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-${game.discount}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _aiScore(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.neonPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'AI ${score.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
