import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/services/billing_service.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'subscription_viewmodel.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late SubscriptionViewModel _vm;
  String _selectedProductId = BillingService.monthlyId;

  @override
  void initState() {
    super.initState();
    _vm = SubscriptionViewModel();
    _vm.onNotify = () {
      if (mounted) setState(() {});
    };
    _vm.init();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  ProductDetails? _productById(String id) {
    try {
      return _vm.products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = _vm;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.get('subscription_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: vm.isPro
          ? _buildProActive(l10n)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '🔥 ${l10n.get('sub_title_unlock')}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('sub_subtitle'),
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _featureRow(l10n.get('sub_feature_wishlist')),
                  const SizedBox(height: 10),
                  _featureRow(l10n.get('sub_feature_alerts')),
                  const SizedBox(height: 10),
                  _featureRow(l10n.get('sub_feature_ai')),
                  const SizedBox(height: 10),
                  _featureRow(l10n.get('sub_feature_no_ads')),
                  const SizedBox(height: 28),
                  _buildPriceCards(l10n, vm),
                  const SizedBox(height: 24),
                  if (vm.error != null) ...[
                    Text(vm.error!, style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    const SizedBox(height: 8),
                  ],
                  if (vm.loading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final p = _productById(_selectedProductId) ?? vm.products.firstOrNull;
                          if (p != null) vm.buy(p);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.itadOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(l10n.get('sub_start_trial'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: vm.loading ? null : () => vm.restore(),
                    child: Text(l10n.get('restore'), style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('sub_cancel_anytime'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.get('maybe_later')),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _featureRow(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: AppColors.itadOrange, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
      ],
    );
  }

  Widget _buildPriceCards(AppLocalizations l10n, SubscriptionViewModel vm) {
    final weekly = _productById(BillingService.trialWeekId);
    final monthly = _productById(BillingService.monthlyId);
    final yearly = _productById(BillingService.yearlyId);
    return Row(
      children: [
        Expanded(
          child: _planCard(
            productId: BillingService.trialWeekId,
            title: l10n.get('sub_weekly'),
            price: weekly?.price ?? '\$0.99',
            badge: l10n.get('sub_trial_hook'),
            vm: vm,
            onTap: () => setState(() => _selectedProductId = BillingService.trialWeekId),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _planCard(
            productId: BillingService.monthlyId,
            title: l10n.get('sub_monthly'),
            price: monthly?.price ?? '\$2.99',
            badge: '🔥 ${l10n.get('sub_most_popular')}',
            vm: vm,
            onTap: () => setState(() => _selectedProductId = BillingService.monthlyId),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _planCard(
            productId: BillingService.yearlyId,
            title: l10n.get('sub_yearly'),
            price: yearly?.price ?? '\$16.99',
            badge: l10n.get('sub_best_value'),
            vm: vm,
            onTap: () => setState(() => _selectedProductId = BillingService.yearlyId),
          ),
        ),
      ],
    );
  }

  Widget _planCard({
    required String productId,
    required String title,
    required String price,
    String? badge,
    required SubscriptionViewModel vm,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedProductId == productId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: vm.loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.itadOrange.withOpacity(0.2) : AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: isSelected ? Border.all(color: AppColors.itadOrange, width: 2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null && badge.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.itadOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                title,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProActive(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.successGreen, size: 64),
          const SizedBox(height: 16),
          Text(l10n.get('proFeature'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.get('done')),
          ),
        ],
      ),
    );
  }
}
