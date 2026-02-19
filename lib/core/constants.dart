/// 应用常量
class AppConstants {
  AppConstants._();

  /// 存储 Key
  static const String keyWishlistIds = 'wishlist_app_ids';
  static const String keyLastDealsCache = 'last_deals_cache';
  static const String keyLastCheckTime = 'last_check_time';
  static const String keyWishlistLastDiscount = 'wishlist_last_discount';
  static const String keyHasAskedNotification = 'has_asked_notification';
  static const String keyHasSeenEnableAlertsPrompt = 'has_seen_enable_alerts_prompt';

  /// WorkManager 任务
  static const String taskCheckDeals = 'check_steam_deals';
  static const String taskDailyDealCheck = 'dailyDealCheck';
  static const String taskTag = 'steam_deal_tag';

  /// Top 5 通知 payload，点击打开首页列表
  static const String payloadTop5 = 'top5';

  /// 通知
  static const String notificationChannelId = 'deal_channel';
  static const String notificationChannelName = 'Deals';

  /// 轮询间隔（分钟）
  static const int checkIntervalMinutes = 60;

  /// 插屏广告控制
  static const String keyAppOpenCount = 'app_open_count';
  static const String keyLastInterstitialDate = 'last_interstitial_date';
  static const String keyTodayInterstitialCount = 'today_interstitial_count';
  static const String keyDetailViewCount = 'detail_view_count';
  static const int maxInterstitialsPerDay = 2;

  /// Pro 订阅与拉新
  static const String keyIsPro = 'isPro';
  static const String keyUserId = 'user_id';
  static const String keyReferrerId = 'referrer_id';
  static const String keyQueryCountDate = 'query_count_date';
  static const String keyQueryCountToday = 'query_count_today';
  static const int freeDailyQueryLimit = 3;

  /// 评分弹窗
  static const String keyLaunchCount = 'launch_count';
  static const String keyHasReviewed = 'has_reviewed';
  static const int reviewTriggerLaunchCount = 3;

  /// 首日引导
  static const String keyFirstLaunchDone = 'first_launch_done';

  /// 二次唤醒：上次打开日期、上次发送召回通知日期
  static const String keyLastOpenDate = 'last_open_date';
  static const String keyLastReengagementDate = 'last_reengagement_date';
  static const int reengagementDaysInactive = 3;

  /// 分享拉新奖励（本地）：分享次数、奖励 Pro 截止日
  static const String keyShareCount = 'share_count';
  static const String keyProFreeUntil = 'pro_free_until';
  static const int sharesNeededForOneDayPro = 3;

  /// 登录（Google）：存储 user_id / email / photo_url
  static const String keyAuthUserId = 'auth_user_id';
  static const String keyAuthEmail = 'auth_email';
  static const String keyAuthPhotoUrl = 'auth_photo_url';

  /// Google OAuth Web 客户端 ID（serverClientId），须与 Cloud 同一项目下的 Web 应用客户端一致
  static const String googleSignInClientId = '803425642695-iab5dhn0recggqnotmlldlthoj5sldua.apps.googleusercontent.com';

  /// IsThereAnyDeal API Key（可选）。填写后详情页 Price History 将拉取真实历史价格。
  /// 获取方式：https://isthereanydeal.com/apps/my/ 注册应用后得到 key。
  static const String itadApiKey = '0eafa0a03e481bf08c1ac74d6e11df34466a2749';

  /// 用户选择的语言（如 en, zh），空表示跟随系统
  static const String keyPreferredLocale = 'preferred_locale';
}
