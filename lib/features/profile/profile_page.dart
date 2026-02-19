import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import '../../core/theme/colors.dart';
import '../../core/storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/review_service.dart';
import '../../l10n/app_localizations.dart';
import '../subscription/subscription_page.dart';
import '../onboarding/onboarding_page.dart';

/// Profile 页：用户信息、登录/登出、Pro、分享、语言、通知等
class ProfilePage extends StatefulWidget {
  final Future<void> Function()? onLocaleChanged;

  const ProfilePage({super.key, this.onLocaleChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isPro = false;
  Map<String, String>? _user;
  String? _currentLocaleCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pro = await StorageService.instance.isPro();
    final user = await AuthService().getCurrentUser();
    final localeCode = await StorageService.instance.getPreferredLocale();
    if (mounted) setState(() {
      _isPro = pro;
      _user = user;
      _currentLocaleCode = localeCode;
    });
  }

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'fr': 'Français',
    'ru': 'Русский',
    'de': 'Deutsch',
    'es': 'Español',
    'ur': 'اردو',
    'id': 'Bahasa Indonesia',
    'tr': 'Türkçe',
    'vi': 'Tiếng Việt',
    'th': 'ไทย',
    'hi': 'हिन्दी',
    'pt': 'Português',
    'ar': 'العربية',
    'pl': 'Polski',
    'it': 'Italiano',
    'nl': 'Nederlands',
    'sv': 'Svenska',
    'he': 'עברית',
    'el': 'Ελληνικά',
  };

  Future<void> _showLanguagePicker() async {
    final locales = ['', ...AppLocalizations.supportedLocales.map((l) => l.languageCode)];
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          AppLocalizations.of(ctx).get('language'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: locales.length,
              itemBuilder: (_, index) {
                final c = locales[index];
                final isSelected = _currentLocaleCode == c || (c.isEmpty && _currentLocaleCode == null);
                return ListTile(
                  title: Text(
                    c.isEmpty ? AppLocalizations.of(ctx).get('system_default') : (_languageNames[c] ?? c),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.itadOrange) : null,
                  onTap: () => Navigator.pop(ctx, c),
                );
              },
            ),
          ),
        ),
      ),
    );
    if (code == null) return;
    await StorageService.instance.setPreferredLocale(code.isEmpty ? null : code);
    await widget.onLocaleChanged?.call();
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.get('profile')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            if (_user != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: _user!['photoUrl'] != null && _user!['photoUrl']!.isNotEmpty
                            ? CachedNetworkImageProvider(_user!['photoUrl']!)
                            : null,
                        child: _user!['photoUrl'] == null || _user!['photoUrl']!.isEmpty
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user!['email']?.isNotEmpty == true ? _user!['email']! : l10n.get('signed_in'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () async {
                                await AuthService().signOut();
                                _load();
                              },
                              child: Text(l10n.get('sign_out')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.login, color: AppColors.itadOrange),
                  title: Text(l10n.get('sign_in_google')),
                  subtitle: Text(l10n.get('sign_in_hint')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    try {
                      await AuthService().signInWithGoogle();
                      _load();
                    } catch (_) {
                      _load();
                      if (!mounted) return;
                      final msg = AuthService.lastSignInError ?? l10n.get('sign_in_failed');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
                      );
                    }
                  },
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.itadOrange, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'v2.0.7+14 · 引导 / 订阅 / 评分 / 分享 已启用',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            if (_isPro)
              Card(
                color: AppColors.successGreen.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: AppColors.successGreen, size: 32),
                      const SizedBox(width: 12),
                      Text(l10n.get('proFeature'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(l10n.get('subscription_title')),
                  subtitle: Text(l10n.get('unlimited_lookups')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                    );
                    _load();
                  },
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.get('language')),
                subtitle: Text(_currentLocaleCode == null || _currentLocaleCode!.isEmpty
                    ? l10n.get('system_default')
                    : (_languageNames[_currentLocaleCode!] ?? _currentLocaleCode!)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showLanguagePicker,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(l10n.get('notifications')),
                subtitle: Text(l10n.get('notifications_hint')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await permission_handler.openAppSettings();
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.get('share_app')),
                subtitle: Text(l10n.get('share_app_hint')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.get('share_return_hint')), duration: const Duration(seconds: 4)),
                    );
                  }
                  final storage = StorageService.instance;
                  final userId = await storage.getOrCreateUserId();
                  const baseUrl = 'https://steamdeals.app/invite';
                  final link = '$baseUrl?ref=$userId';
                  final msg = '${l10n.get('share_message')}\n$link';
                  Share.share(msg);
                  await storage.incrementShareCount();
                  _load();
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.get('daily_limit_hint'),
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.slideshow),
                title: Text(l10n.get('app_guide')),
                subtitle: Text(l10n.get('app_guide_hint')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingPage(showOnlyForReview: true),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.star),
                title: Text(l10n.get('rate_us')),
                subtitle: Text(l10n.get('rate_us_hint')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ReviewService().requestReviewFromUser();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
