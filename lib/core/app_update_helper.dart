import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import '../l10n/app_localizations.dart';

/// Google Play 应用内更新：检测到新版本时引导用户更新
class AppUpdateHelper {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (!context.mounted) return;
      final shouldUpdate = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(ctx).get('update_title')),
          content: Text(
            AppLocalizations.of(ctx).get('update_message'),
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(ctx).get('later')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(ctx).get('update_now')),
            ),
          ],
        ),
      );
      if (shouldUpdate != true || !context.mounted) return;

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('AppUpdateHelper.checkForUpdate: $e');
    }
  }
}
