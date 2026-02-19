import 'package:flutter/material.dart';
import '../core/storage_service.dart';
import '../core/services/auth_service.dart';
import '../core/theme/colors.dart';
import '../l10n/app_localizations.dart';
import '../models/game_model.dart';
import '../models/wishlist_model.dart';
import '../services/steam_api_service.dart';
import '../widgets/game_card.dart';
import '../features/subscription/subscription_page.dart';
import 'detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key, this.currentTabIndex = 0});
  final int currentTabIndex;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final StorageService _storage = StorageService.instance;
  final SteamApiService _api = SteamApiService();
  List<WishlistItem> _items = [];
  List<GameModel> _deals = [];
  Map<String, int> _lastDiscounts = {};
  bool _loading = true;
  bool _isLoggedIn = false;
  int _lastTabIndex = -1;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  Future<void> _checkAuthAndLoad() async {
    final loggedIn = await AuthService().isLoggedIn();
    if (mounted) setState(() => _isLoggedIn = loggedIn);
    if (loggedIn) await _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WishlistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTabIndex == 2 && oldWidget.currentTabIndex != 2) {
      _checkAuthAndLoad();
    }
  }

  Future<void> _load() async {
    if (!StorageService.instance.isInitialized) await StorageService.instance.init();
    final items = await _storage.getWishlistItems();
    final deals = await _api.fetchDeals(pageSize: 100);
    final lastDiscounts = await _storage.getLastKnownDiscounts();
    if (mounted) {
      setState(() {
        _items = items;
        _deals = deals;
        _lastDiscounts = lastDiscounts;
        _loading = false;
      });
    }
  }

  List<WishlistItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((item) => item.name.toLowerCase().contains(q)).toList();
  }

  GameModel? _gameFor(WishlistItem item) {
    try {
      return _deals.firstWhere((g) => g.appId == item.appId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildListContent(ThemeData theme, List<WishlistItem> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? '' : AppLocalizations.of(context).get('search_no_match'),
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          final game = _gameFor(item);
                      if (game == null) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            leading: item.image != null && item.image.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                          item.image,
                          width: 56,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.games),
                title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(AppLocalizations.of(context).get('deal_ended'), style: theme.textTheme.bodySmall),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(appId: item.appId),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _storage.removeFromWishlist(item.appId);
                    _load();
                  },
                ),
              ),
            );
          }
          final lastD = _lastDiscounts[item.appId];
          final priceDropped = lastD != null && game.discount > lastD;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (priceDropped)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_down, size: 16, color: AppColors.danger),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context).get('price_dropped'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
                      ],
                    ),
                  ),
                ),
              GameCard(
                game: game,
                showWishlistButton: true,
                isInWishlist: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(appId: item.appId, initialGame: game),
                  ),
                ),
                onWishlistToggle: () async {
                  await _storage.removeFromWishlist(item.appId);
                  _load();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(AppLocalizations.of(context).get('wishlist_tab'), style: const TextStyle(color: AppColors.textPrimary)),
        ),
        body: _LoginGate(
          onSignIn: () async {
            await AuthService().signInWithGoogle();
            _checkAuthAndLoad();
          },
        ),
      );
    }
    final filtered = _filteredItems;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocalizations.of(context).get('wishlist_tab'), style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _EmptyWishlist(theme: theme)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.rocket_launch, color: AppColors.itadOrange, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).get('upgrade_to_pro_instant_alerts'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).get('wishlist_search_hint'),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      child: _buildListContent(theme, filtered),
                    ),
                  ],
                ),
    );
  }
}

class _LoginGate extends StatelessWidget {
  final VoidCallback onSignIn;

  const _LoginGate({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).get('sign_in_to_use_wishlist'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).get('sign_in_google_wishlist_hint'),
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login),
                label: Text(AppLocalizations.of(context).get('sign_in_google')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.itadOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  final ThemeData theme;

  const _EmptyWishlist({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 72, color: theme.textTheme.bodySmall!.color),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).get('empty_wishlist_title'),
              style: theme.textTheme.titleLarge!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).get('empty_wishlist_subtitle'),
              style: theme.textTheme.bodySmall!,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
