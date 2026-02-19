import 'package:workmanager/workmanager.dart';
import '../services/steam_api_service.dart';
import 'constants.dart';
import 'notification_copy.dart';
import 'schedule_config.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'shock_deal_algorithm.dart';
import 'utils/score_calculator.dart' show calculateScore;

/// 后台任务：愿望单检测 + 爆款 2.0 每日通知（算法驱动、带数字）
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final api = SteamApiService();
    final storage = StorageService.instance;
    final notification = NotificationService.instance;

    await storage.init();
    await notification.init();

    final isDaily = task == AppConstants.taskDailyDealCheck;

    // 1) 愿望单检测：折扣变大则推送（仅 Pro 用户有价格提醒）
    final isPro = await storage.isPro();
    final wishlist = await storage.getWishlist();
    final lastDiscounts = await storage.getLastKnownDiscounts();

    for (var game in wishlist) {
      final latest = await api.fetchGameById(game.appId);
      final lastDiscount = lastDiscounts[game.appId];
      final currentDiscount = latest.discount;

      if (isPro && lastDiscount != null && currentDiscount > lastDiscount) {
        final priceStr = latest.price > 0
            ? '\$${latest.price.toStringAsFixed(2)}'
            : '$currentDiscount% OFF';
        await notification.showNotification(
          '🔥 Price Dropped!',
          '${latest.name} now $priceStr',
          notificationId: game.appId.hashCode.abs() % 100000 + 10000,
          payload: game.appId,
          usePriceAlertChannel: true,
        );
      }

      await storage.setLastKnownDiscount(game.appId, currentDiscount);
    }

    // 2) 每日任务：爆款 2.0 算法通知（只发一条，优先级：主推 > 80%+ > Under $5）
    if (isDaily) {
      const pageSize = 60;
      var deals = await api.fetchDeals(pageSize: pageSize, pageNumber: 0);
      deals = ShockDealAlgorithm.deduplicateDeals(deals);
      if (deals.isEmpty) {
        await _rescheduleDaily();
        return Future.value(true);
      }

      final stats = ShockDealAlgorithm.getStats(deals);
      final shock = ShockDealAlgorithm.getShockDeal(deals);
      final shockScore = shock != null ? calculateScore(shock) : 0.0;

      // 主推得分阈值（AI 评分 0~10，≥8 才发主推）
      const shockScoreThreshold = 8.0;

      bool sent = false;

      if (shock != null && shockScore >= shockScoreThreshold) {
        final priceStr = shock.price > 0
            ? '\$${shock.price.toStringAsFixed(2)}'
            : '${shock.discount}% OFF';
        await notification.showNotification(
          NotificationCopy.shockDealTitle(shock.name, shock.discount),
          NotificationCopy.shockDealBody(priceStr),
          notificationId: 99998,
          payload: shock.appId,
        );
        sent = true;
      }

      if (!sent && stats.over80 >= 5) {
        await notification.showNotification(
          NotificationCopy.over80Title(stats.over80),
          NotificationCopy.over80Body(),
          notificationId: 99997,
          payload: AppConstants.payloadTop5,
        );
        sent = true;
      }

      if (!sent && stats.under5 >= 5) {
        await notification.showNotification(
          NotificationCopy.under5Title(stats.under5),
          NotificationCopy.under5Body(),
          notificationId: 99996,
          payload: AppConstants.payloadTop5,
        );
      }

      // 3) 二次唤醒：超过 N 天未打开则发召回通知
      final lastOpen = await storage.getLastOpenDate();
      if (lastOpen != null && lastOpen.isNotEmpty) {
        try {
          final last = DateTime.parse(lastOpen);
          final daysInactive = DateTime.now().difference(last).inDays;
          if (daysInactive >= AppConstants.reengagementDaysInactive) {
            final today = DateTime.now().toIso8601String().substring(0, 10);
            final lastRe = await storage.getLastReengagementDate();
            if (lastRe != today) {
              await notification.showNotification(
                '🔥 We miss you!',
                'Check today\'s hottest Steam deals.',
                notificationId: 99995,
                payload: AppConstants.payloadTop5,
              );
              await storage.setLastReengagementDate(today);
            }
          }
        } catch (_) {}
      }

      await _rescheduleDaily();
    }

    return Future.value(true);
  });
}

Future<void> _rescheduleDaily() async {
  await Workmanager().registerOneOffTask(
    AppConstants.taskDailyDealCheck,
    AppConstants.taskDailyDealCheck,
    initialDelay: ScheduleConfig.dailyInterval,
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}
