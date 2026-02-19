import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../storage_service.dart';

/// Google Play Billing 订阅服务（v6+，订阅模式）
class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Google Play Console 配置：7 天 $0.99 / 月 $2.99 / 年 $16.99
  static const String trialWeekId = 'pro_week_099';
  static const String monthlyId = 'pro_month_299';
  static const String yearlyId = 'pro_year_1699';
  static const Set<String> _productIds = {trialWeekId, monthlyId, yearlyId};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    final bool available = await _iap.isAvailable();
    if (!available) return;
    _subscription = _iap.purchaseStream.listen(_listenToPurchase);
    _initialized = true;
  }

  Future<List<ProductDetails>> loadProducts() async {
    if (!_initialized) await init();
    final response = await _iap.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) return [];
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  /// 订阅类产品需用 buyConsumable 或服务端验证；若 Play 配置为订阅，可用 buyNonConsumable
  Future<void> buySubscription(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  void _listenToPurchase(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        StorageService.instance.setPro(true);
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> restore() async {
    await _iap.restorePurchases();
    // 若 restore 后 purchaseStream 会推送历史购买，这里不重复设 isPro；若不会推送，可再查一次
    // 依赖 purchaseStream 推送即可
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
