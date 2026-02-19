import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/notification_permission_helper.dart';
import '../core/storage_service.dart';
import '../models/game_model.dart';
import '../models/wishlist_model.dart';
import '../services/steam_api_service.dart';
import '../widgets/game_card.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SteamApiService _api = SteamApiService();
  final StorageService _storage = StorageService.instance;
  final TextEditingController _controller = TextEditingController();
  List<GameModel> _allGames = [];
  List<GameModel> _filtered = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDeals();
    _controller.addListener(() => setState(() {}));
  }

  Future<void> _loadDeals() async {
    final list = await _api.fetchDeals();
    if (mounted) {
      setState(() {
        _allGames = list;
        _filtered = list;
        _loaded = true;
      });
    }
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _filtered = _allGames;
        _loaded = true;
      });
      return;
    }
    setState(() => _loaded = false);
    _searchFromApi(query);
  }

  Future<void> _searchFromApi(String query) async {
    final list = await _api.searchGames(query, pageSize: 25);
    if (mounted) {
      setState(() {
        _filtered = list;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('search_title')),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).get('search_hint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context).get('no_results'),
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final game = _filtered[index];
                    return FutureBuilder<bool>(
                      future: _storage.isInWishlist(game.appId),
                      builder: (ctx, ws) => GameCard(
                        game: game,
                        isInWishlist: ws.data ?? false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(appId: game.appId, initialGame: game),
                          ),
                        ),
                        onWishlistToggle: () async {
                          final inList =
                              await _storage.isInWishlist(game.appId);
                          if (inList) {
                            await _storage.removeFromWishlist(game.appId);
                          } else {
                            await _storage
                                .addToWishlist(WishlistItem.fromGame(game));
                            await NotificationPermissionHelper.maybeRequestWithRationale(context);
                          }
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
