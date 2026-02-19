import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/score_calculator.dart';
import '../../../core/storage_service.dart';
import '../../../core/access_control.dart';
import '../../../core/services/game_service.dart';
import '../../../core/services/algorithm_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/game_model.dart';
import '../detail/detail_page.dart';
import '../detail/game_detail_page.dart';
import '../subscription/subscription_page.dart';
import 'widgets/top_deal_banner.dart';
import 'widgets/top_list_item.dart';
import '../../../widgets/ad_banner.dart';

/// 极简爆款首页：一大 Banner + Top 10 列表，秒开 + 后台刷新
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GameModel> _deals = [];
  List<GameModel> _top10 = [];
  GameModel? _topDeal;
  String? _updatedAt;
  bool _loading = false;
  bool _isPro = false;
  bool _queryLimitReached = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final storage = StorageService.instance;
    _isPro = await storage.isPro();
    final cache = CacheService();
    final cached = await cache.getCachedGames();
    if (cached.isNotEmpty && mounted) {
      _applyDeals(deduplicateDeals(cached));
    }
    _updatedAt = await cache.getLastCheckTime();
    if (mounted) setState(() {});

    final canSearch = await AccessControl().canSearchToday();
    _queryLimitReached = !canSearch;
    final canFetch = canSearch;
    if (mounted) setState(() {});

    if (!canFetch) return;

    await storage.incrementQueryCountToday();
    final latest = await GameService().fetchGames(pageSize: 60);
    if (latest.isEmpty || !mounted) return;
    final deduped = deduplicateDeals(latest);
    await cache.saveGames(deduped);
    _updatedAt = await cache.getLastCheckTime();
    if (mounted) _applyDeals(deduped);
  }

  void _applyDeals(List<GameModel> list) {
    _deals = list;
    _top10 = AlgorithmService().topByScore(list, limit: 10);
    _topDeal = _top10.isNotEmpty ? _top10.first : null;
    if (mounted) setState(() {});
  }

  void _openDetail(GameModel game) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GameDetailPage(game: game),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _loading = true);
            await _initData();
            if (mounted) setState(() => _loading = false);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                AppLocalizations.of(context).get('steam_deals_today'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_updatedAt != null && _updatedAt!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatUpdatedAt(context, _updatedAt!),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TopDealBanner(
                game: _topDeal,
                onTap: _topDeal != null ? () => _openDetail(_topDeal!) : null,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).get('top_10_deals_today'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (_top10.isEmpty && !_loading)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).get('no_deals_pull'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...() {
                  final list = <Widget>[];
                  for (var i = 0; i < _top10.length; i++) {
                    if (i == 2 && !_isPro) {
                      list.add(const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: AdBanner(),
                      ));
                    }
                    list.add(TopListItem(
                      game: _top10[i],
                      rank: i + 1,
                      onTap: () => _openDetail(_top10[i]),
                    ));
                  }
                  return list;
                }(),
              if (_queryLimitReached)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_outlined, color: AppColors.itadOrange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).get('lookups_used_tap_unlock'),
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!_isPro) const SizedBox(height: 24),
              if (!_isPro) const AdBanner(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUpdatedAt(BuildContext context, String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${AppLocalizations.of(context).get('updated_today')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return AppLocalizations.of(context).get('updated_today');
    }
  }
}
