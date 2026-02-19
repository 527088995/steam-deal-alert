import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/storage_service.dart';

/// 折扣提醒设置页（首页第四个入口）
class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  static const String _keyMinDiscount = 'alert_min_discount';
  int _minDiscount = 50;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!StorageService.instance.isInitialized) await StorageService.instance.init();
    final prefs = StorageService.instance.prefs;
    if (prefs == null) return;
    if (mounted) setState(() {
      _minDiscount = prefs.getInt(_keyMinDiscount) ?? 50;
    });
  }

  Future<void> _save(int value) async {
    final prefs = StorageService.instance.prefs;
    if (prefs != null) prefs.setInt(_keyMinDiscount, value);
    if (mounted) setState(() => _minDiscount = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('set_discount_alert')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            AppLocalizations.of(context).get('discount_alert_body'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              '$_minDiscount%',
              style: TextStyle(
                fontSize: 32,
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minDiscount.toDouble(),
            min: 10,
            max: 90,
            divisions: 8,
            label: '$_minDiscount%',
            onChanged: (v) => _save(v.round()),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              AppLocalizations.of(context).get('discount_alert_disclaimer'),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
