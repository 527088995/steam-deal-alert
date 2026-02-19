import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:workmanager/workmanager.dart';
import 'package:app_links/app_links.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'core/background_task.dart';
import 'core/constants.dart';
import 'core/services/billing_service.dart';
import 'core/storage_service.dart';
import 'data/services/cache_service.dart';
import 'core/notification_service.dart';
import 'core/schedule_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局捕获 Flutter 框架错误与异步未捕获异常，避免启动白屏/闪退无日志
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  // 构建阶段异常时显示简单提示而非红屏，便于真机排查
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('ErrorWidget: ${details.exception}\n${details.stack}');
    return Material(
      color: const Color(0xFF0B141B),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Something went wrong.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[300], fontSize: 16),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                Text(details.exceptionAsString(), style: TextStyle(color: Colors.grey[500], fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  };
  runZonedGuarded(() async {
    try {
      await _init();
    } catch (e, stack) {
      debugPrint('_init error: $e\n$stack');
    }
    // 无论 _init 是否异常都启动 UI，避免白屏/闪退
    runApp(const SteamDealApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

Future<void> _init() async {
  // 优先初始化存储，首屏与延迟回调都依赖
  try {
    await StorageService.instance.init();
  } catch (e) {
    debugPrint('StorageService.init: $e');
  }

  try {
    await CacheService.init();
  } catch (e) {
    debugPrint('CacheService.init: $e');
  }

  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('MobileAds.init: $e');
  }

  try {
    await BillingService().init();
  } catch (e) {
    debugPrint('BillingService.init: $e');
  }

  try {
    final appLinks = AppLinks();
    final uri = await appLinks.getInitialLink();
    if (uri != null) {
      final ref = uri.queryParameters['ref'];
      if (ref != null && ref.isNotEmpty) {
        await StorageService.instance.setReferrerId(ref);
      }
    }
  } catch (e) {
    debugPrint('AppLinks.getInitialLink: $e');
  }

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('NotificationService.init: $e');
  }

  try {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied) await Permission.notification.request();
    }
  } catch (e) {
    debugPrint('NotificationPermission: $e');
  }

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    final delay = ScheduleConfig.delayUntilNextUSEvening();
    await Workmanager().registerOneOffTask(
      AppConstants.taskDailyDealCheck,
      AppConstants.taskDailyDealCheck,
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  } catch (e) {
    debugPrint('Workmanager.init: $e');
  }
}
