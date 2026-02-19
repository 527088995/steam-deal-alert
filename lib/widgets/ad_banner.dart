import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 底部 Banner 广告（测试 ID，上线前替换为真实广告位）
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // 测试 ID
    }
    return 'ca-app-pub-3940256099942544/2435281174'; // iOS 测试 ID
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoading) {
      // 延迟一帧再加载，避免首帧与 MobileAds 初始化竞争导致 WebView 崩
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _bannerAd == null && !_isLoading) _loadAd();
      });
    }
  }

  Future<void> _loadAd() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final w = MediaQuery.of(context).size.width.truncate();
      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(w);
      if (!mounted) return;
      if (size == null) return;

      final ad = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('AdBanner failed: $err');
            ad.dispose();
          },
        ),
      );
      ad.load();
    } catch (e) {
      debugPrint('AdBanner _loadAd: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 320,
            height: 50,
            child: ColoredBox(
              color: Color(0xFF252A33),
              child: Center(
                child: Text(
                  'Ad',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
