import 'package:in_app_purchase/in_app_purchase.dart';
import 'billing_service.dart';
import '../storage_service.dart';

/// 最终稳定结构：订阅服务（对接 BillingService）
/// Profile 订阅入口、Pro 权益判断
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final BillingService _billing = BillingService();

  Future<bool> get isPro async => StorageService.instance.isPro();

  Future<void> init() async => _billing.init();

  Future<List<ProductDetails>> loadProducts() async {
    await _billing.init();
    return _billing.loadProducts();
  }

  /// 购买月订（骨架命名：purchaseMonthly）
  Future<void> purchaseMonthly() async {
    final products = await _billing.loadProducts();
    final monthly = products.where((p) => p.id == BillingService.monthlyId).firstOrNull;
    if (monthly != null) await _billing.buy(monthly);
  }

  /// 购买周试用
  Future<void> purchaseWeekTrial() async {
    final products = await _billing.loadProducts();
    final week = products.where((p) => p.id == BillingService.trialWeekId).firstOrNull;
    if (week != null) await _billing.buy(week);
  }

  /// 购买年订
  Future<void> purchaseYearly() async {
    final products = await _billing.loadProducts();
    final yearly = products.where((p) => p.id == BillingService.yearlyId).firstOrNull;
    if (yearly != null) await _billing.buy(yearly);
  }

  Future<void> restorePurchases() async => _billing.restore();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
