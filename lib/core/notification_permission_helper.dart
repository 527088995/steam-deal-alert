import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';
import '../l10n/app_localizations.dart';

/// 愿望单通知权限：在合适时机向用户说明并引导开启
class NotificationPermissionHelper {
  /// 若尚未询问过且用户有愿望单，可弹出说明并引导去设置开启通知
  static Future<void> maybeRequestWithRationale(BuildContext context) async {
    final storage = StorageService.instance;
    if (!storage.isInitialized) return;
    final asked = await storage.getHasAskedNotification();
    if (asked) return;
    final items = await storage.getWishlistItems();
    if (items.isEmpty) return;

    await storage.setHasAskedNotification(true);

    if (context == null) return;
    final shouldOpen = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).get('notification_title')),
        content: Text(
          AppLocalizations.of(ctx).get('notification_message'),
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx).get('later')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(ctx).get('go_settings')),
          ),
        ],
      ),
    );
    if (shouldOpen == true) {
      await openAppSettings();
    }
  }
}
