import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/services/billing_service.dart';
import '../../core/storage_service.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final BillingService _billing = BillingService();
  final StorageService _storage = StorageService.instance;

  List<ProductDetails> _products = [];
  bool _loading = true;
  String? _error;

  List<ProductDetails> get products => List.unmodifiable(_products);
  bool get loading => _loading;
  String? get error => _error;
  bool _isPro = false;
  bool get isPro => _isPro;

  VoidCallback? onNotify;

  void _notify() {
    notifyListeners();
    onNotify?.call();
  }

  Future<void> refreshPro() async {
    final pro = await _storage.isPro();
    if (pro != _isPro) {
      _isPro = pro;
      _notify();
    }
  }

  Future<void> init() async {
    _loading = true;
    _error = null;
    _notify();
    _isPro = await _storage.isPro();
    try {
      await _billing.init();
      _products = await _billing.loadProducts();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    _notify();
  }

  Future<void> buy(ProductDetails product) async {
    _error = null;
    _notify();
    try {
      await _billing.buy(product);
      await refreshPro();
    } catch (e) {
      _error = e.toString();
      _notify();
    }
  }

  Future<void> restore() async {
    _error = null;
    _notify();
    try {
      await _billing.restore();
      await refreshPro();
    } catch (e) {
      _error = e.toString();
    }
    _notify();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
