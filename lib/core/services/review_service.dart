import 'package:in_app_review/in_app_review.dart';
import '../storage_service.dart';
import '../constants.dart';

/// 评分弹窗：第 3 次打开或成功加入愿望单时触发
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _review = InAppReview.instance;

  /// 应用启动时检查（第 3 次打开触发）
  Future<void> checkAndRequestReviewOnLaunch() async {
    final storage = StorageService.instance;
    if (!storage.isInitialized) await storage.init();
    final launchCount = await storage.getAppOpenCount();
    final hasReviewed = await storage.getHasReviewed();
    if (launchCount >= AppConstants.reviewTriggerLaunchCount && !hasReviewed) {
      await _requestReview(storage);
    }
  }

  /// 加入愿望单后调用
  Future<void> checkAndRequestReviewAfterWishlistAdd() async {
    final storage = StorageService.instance;
    if (!storage.isInitialized) await storage.init();
    final hasReviewed = await storage.getHasReviewed();
    if (hasReviewed) return;
    await _requestReview(storage);
  }

  /// Profile 里「去评分」按钮：主动请求评分（不校验次数）
  Future<void> requestReviewFromUser() async {
    final storage = StorageService.instance;
    if (!storage.isInitialized) await storage.init();
    await _requestReview(storage);
  }

  Future<void> _requestReview(StorageService storage) async {
    if (!await _review.isAvailable()) return;
    await _review.requestReview();
    await storage.setHasReviewed(true);
  }
}
