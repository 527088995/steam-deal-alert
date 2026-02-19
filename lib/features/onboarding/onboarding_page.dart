import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/storage_service.dart';
import '../../l10n/app_localizations.dart';
import '../subscription/subscription_page.dart';

/// 首日引导：3 页（通知 -> 愿望单 -> 订阅 CTA）
/// [showOnlyForReview] 为 true 时仅展示引导内容，最后一页显示 Done 并 pop
/// [onSkip] / [onUnlockPro] 若提供则作为 overlay 模式，不执行 Navigator，避免 pop 白屏
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    this.showOnlyForReview = false,
    this.onSkip,
    this.onUnlockPro,
  });

  final bool showOnlyForReview;
  final VoidCallback? onSkip;
  final VoidCallback? onUnlockPro;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _page = 0;

  void _finishAndGoToSubscription(BuildContext context) {
    StorageService.instance.setFirstLaunchDone();
    if (widget.onUnlockPro != null) {
      widget.onUnlockPro!();
      return;
    }
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
    );
  }

  void _finishAndGoToMain(BuildContext context) {
    StorageService.instance.setFirstLaunchDone();
    if (widget.onSkip != null) {
      widget.onSkip!();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Slide(
                    icon: Icons.notifications_active,
                    title: l10n.get('onboarding_slide1_title'),
                    body: l10n.get('onboarding_slide1_body'),
                  ),
                  _Slide(
                    icon: Icons.favorite,
                    title: l10n.get('add_to_wishlist'),
                    body: l10n.get('onboarding_slide2_body'),
                  ),
                  _Slide(
                    icon: Icons.workspace_premium,
                    title: l10n.get('onboarding_slide3_title'),
                    body: l10n.get('onboarding_slide3_body'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  ...List.generate(3, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? AppColors.itadOrange : AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ],
              ),
            ),
            if (_page < 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_page < 2) _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.itadOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.get('next')),
                  ),
                ),
              )
            else if (widget.showOnlyForReview)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.itadOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.get('done')),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _finishAndGoToSubscription(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.itadOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.get('unlock_pro_features')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _finishAndGoToMain(context),
                      child: Text(l10n.get('skip_for_now'), style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Slide({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: AppColors.itadOrange),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
