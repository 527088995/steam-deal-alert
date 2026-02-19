import 'package:flutter/material.dart';
import '../../../core/access_control.dart';
import '../../../core/theme/colors.dart';
import '../../../core/shock_deal_algorithm.dart';
import '../../../core/utils/score_calculator.dart' as score_util;
import '../../../core/storage_service.dart';
import '../../../data/services/cache_service.dart';
import '../../../data/services/api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/game_model.dart';
import '../../../screens/search_screen.dart';
import '../detail/detail_page.dart';
import '../detail/game_detail_page.dart';
import '../subscription/subscription_page.dart';
import 'widgets/game_card_small.dart';

/// Explore：搜索栏 + 四横滑（Just Released / Trending / Hidden Gems / Biggest Discounts）
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<GameModel> _deals = [];
  DealCategories? _cat;
  bool _loading = true;
  bool _queryLimitReached = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    var list = await CacheService.loadGames();
    final canSearch = await AccessControl().canSearchToday();
    final canFetch = list.isEmpty && canSearch;
    if (list.isEmpty) {
      if (canFetch) {
        await StorageService.instance.incrementQueryCountToday();
        list = await ApiService.fetchDeals(pageSize: 60);
        if (list.isNotEmpty) {
          list = ShockDealAlgorithm.deduplicateDeals(list);
          await CacheService.saveGames(list);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _deals = list;
      _cat = list.isNotEmpty ? ShockDealAlgorithm.computeCategories(list) : null;
      _queryLimitReached = list.isEmpty && !canSearch;
      _loading = false;
    });
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

  Widget _section(BuildContext context, String titleKey, List<GameModel> games) {
    if (games.isEmpty) return const SizedBox.shrink();
    final title = AppLocalizations.of(context).get(titleKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (_, i) => GameCardSmall(
              game: games[i],
              onTap: () => _openDetail(games[i]),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('explore_tab')),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).get('search_hint'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (q) {
                if (q.trim().isEmpty) return;
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SearchScreen(),
                    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _queryLimitReached
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_outlined, size: 48, color: AppColors.itadOrange),
                              const SizedBox(height: 16),
                              Text(AppLocalizations.of(context).get('daily_limit_reached'), style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                                ),
                                child: Text(AppLocalizations.of(context).get('unlock_unlimited')),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _cat == null
                    ? Center(child: Text(AppLocalizations.of(context).get('no_deals_refresh'), style: const TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: () {
                            final usedIds = <String>{};
                            final aiSorted = score_util.topDealsByScore(_deals, limit: 30);
                            final aiList = score_util.uniqueList(aiSorted, usedIds);
                            final newR = score_util.uniqueList(_cat!.newRelease, usedIds);
                            final hidden = score_util.uniqueList(_cat!.hiddenGems, usedIds);
                            // Trending Now 与 Biggest Discount 用完整分类列表，保证两个区块始终有内容
                            final trend = _cat!.trending;
                            final hot = _cat!.todayHot;
                            return [
                              _section(context, 'section_just_released', newR),
                              _section(context, 'section_ai_picks', aiList),
                              _section(context, 'section_trending_now', trend),
                              _section(context, 'section_hidden_gems', hidden),
                              _section(context, 'section_biggest_discount', hot),
                            ];
                          }(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

