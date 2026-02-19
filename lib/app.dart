import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'core/app_update_helper.dart';
import 'core/interstitial_helper.dart';
import 'core/storage_service.dart';
import 'core/services/review_service.dart';
import 'features/home/home_page.dart';
import 'features/explore/explore_page.dart';
import 'features/wishlist/wishlist_page.dart';
import 'features/profile/profile_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/subscription/subscription_page.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SteamDealApp extends StatefulWidget {
  const SteamDealApp({super.key});

  @override
  State<SteamDealApp> createState() => _SteamDealAppState();
}

class _SteamDealAppState extends State<SteamDealApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final code = await StorageService.instance.getPreferredLocale();
    if (!mounted) return;
    setState(() => _locale = code != null && code.isNotEmpty ? Locale(code) : null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppLocalizations.of(context).get('home_title'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1116),
      ),
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizationsDelegate(),
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainPage(onLocaleChanged: _loadLocale),
    );
  }
}

/// 最终稳定结构：MainNavigation = Home / Explore / Wishlist / Profile（IndexedStack 防白屏）
class MainPage extends StatefulWidget {
  final Future<void> Function()? onLocaleChanged;

  const MainPage({super.key, this.onLocaleChanged});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;
  bool _showOnboarding = false;
  bool _showEnableAlertsPrompt = false;

  List<Widget> get _pages => [
    const HomePage(),
    const ExplorePage(),
    WishlistPage(currentTabIndex: _index),
    ProfilePage(onLocaleChanged: widget.onLocaleChanged),
  ];

  Future<void> _dismissEnableAlertsAndContinue(bool enableNow) async {
    await StorageService.instance.setHasSeenEnableAlertsPrompt(true);
    if (enableNow) {
      try {
        await permission_handler.Permission.notification.request();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _showEnableAlertsPrompt = false);
    if (await StorageService.instance.isFirstLaunch()) {
      if (mounted) setState(() => _showOnboarding = true);
    }
  }

  Widget _buildEnableAlertsOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active, size: 56, color: Colors.greenAccent.shade400),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context).get('enable_price_alerts'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).get('notification_message'),
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _dismissEnableAlertsAndContinue(false),
                            child: Text(AppLocalizations.of(context).get('later')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => _dismissEnableAlertsAndContinue(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(AppLocalizations.of(context).get('enable_now')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _closeOnboardingAndMaybeOpenSubscription({bool openSubscription = false}) {
    setState(() => _showOnboarding = false);
    if (openSubscription) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SubscriptionPage()),
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // 先让首帧绘制完成，再执行存储/插屏/评分/引导，减少启动即崩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () async {
        if (!mounted) return;
        try {
          await StorageService.instance.setLastOpenDate(DateTime.now());
        } catch (_) {}
        try {
          if (await InterstitialHelper.tryShowAfterAppOpen()) {}
        } catch (_) {}
        if (!mounted) return;
        try {
          ReviewService().checkAndRequestReviewOnLaunch();
        } catch (_) {}
        if (!mounted) return;
        try {
          final isFirst = await StorageService.instance.isFirstLaunch();
          if (isFirst && Platform.isAndroid) {
            final status = await permission_handler.Permission.notification.status;
            final seen = await StorageService.instance.getHasSeenEnableAlertsPrompt();
            if (status.isDenied && !seen && mounted) {
              setState(() => _showEnableAlertsPrompt = true);
            } else if (mounted) {
              setState(() => _showOnboarding = true);
            }
          } else if (isFirst && mounted) {
            setState(() => _showOnboarding = true);
          }
        } catch (_) {}
      });
    });
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        final status = await permission_handler.Permission.notification.status;
        if (status.isDenied) await permission_handler.Permission.notification.request();
      } catch (_) {}
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      try {
        AppUpdateHelper.checkForUpdate(context);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: _pages,
          ),
          if (_showEnableAlertsPrompt) _buildEnableAlertsOverlay(),
          if (_showOnboarding)
            Positioned.fill(
              child: Material(
                color: AppColors.background,
                child: SafeArea(
                  child: OnboardingPage(
                    onSkip: () => _closeOnboardingAndMaybeOpenSubscription(),
                    onUnlockPro: () => _closeOnboardingAndMaybeOpenSubscription(openSubscription: true),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF151A22),
        selectedItemColor: AppColors.itadOrange,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppLocalizations.of(context).get('home_tab')),
          BottomNavigationBarItem(icon: const Icon(Icons.explore), label: AppLocalizations.of(context).get('explore_tab')),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: AppLocalizations.of(context).get('wishlist_tab')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: AppLocalizations.of(context).get('profile_tab')),
        ],
      ),
    );
  }
}
