import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_generated_de.dart';
import 'app_localizations_generated_en.dart';
import 'app_localizations_generated_es.dart';
import 'app_localizations_generated_fr.dart';
import 'app_localizations_generated_ja.dart';
import 'app_localizations_generated_ko.dart';
import 'app_localizations_generated_ru.dart';
import 'app_localizations_generated_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizationsGenerated
/// returned by `AppLocalizationsGenerated.of(context)`.
///
/// Applications need to include `AppLocalizationsGenerated.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations_generated.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizationsGenerated.localizationsDelegates,
///   supportedLocales: AppLocalizationsGenerated.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizationsGenerated.supportedLocales
/// property.
abstract class AppLocalizationsGenerated {
  AppLocalizationsGenerated(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizationsGenerated? of(BuildContext context) {
    return Localizations.of<AppLocalizationsGenerated>(
        context, AppLocalizationsGenerated);
  }

  static const LocalizationsDelegate<AppLocalizationsGenerated> delegate =
      _AppLocalizationsGeneratedDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Steam Deals'**
  String get appTitle;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribe;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restore;

  /// No description provided for @proFeature.
  ///
  /// In en, this message translates to:
  /// **'Unlock All Features'**
  String get proFeature;

  /// No description provided for @subscription_title.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get subscription_title;

  /// No description provided for @free_label.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free_label;

  /// No description provided for @pro_label.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro_label;

  /// No description provided for @feature_queries.
  ///
  /// In en, this message translates to:
  /// **'Deal lookups per day'**
  String get feature_queries;

  /// No description provided for @feature_ads.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get feature_ads;

  /// No description provided for @feature_price_alert.
  ///
  /// In en, this message translates to:
  /// **'Price drop alerts'**
  String get feature_price_alert;

  /// No description provided for @free_queries_value.
  ///
  /// In en, this message translates to:
  /// **'3 per day'**
  String get free_queries_value;

  /// No description provided for @free_ads_value.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get free_ads_value;

  /// No description provided for @free_alert_value.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get free_alert_value;

  /// No description provided for @pro_queries_value.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get pro_queries_value;

  /// No description provided for @pro_ads_value.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get pro_ads_value;

  /// No description provided for @pro_alert_value.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get pro_alert_value;

  /// No description provided for @badge_off.
  ///
  /// In en, this message translates to:
  /// **'30% OFF'**
  String get badge_off;

  /// No description provided for @limited_offer.
  ///
  /// In en, this message translates to:
  /// **'Limited time offer'**
  String get limited_offer;

  /// No description provided for @trust_copy.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. Secure payment via Google Play.'**
  String get trust_copy;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @share_message.
  ///
  /// In en, this message translates to:
  /// **'Check out Steam deals!'**
  String get share_message;
}

class _AppLocalizationsGeneratedDelegate
    extends LocalizationsDelegate<AppLocalizationsGenerated> {
  const _AppLocalizationsGeneratedDelegate();

  @override
  Future<AppLocalizationsGenerated> load(Locale locale) {
    return SynchronousFuture<AppLocalizationsGenerated>(
        lookupAppLocalizationsGenerated(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'ja',
        'ko',
        'ru',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsGeneratedDelegate old) => false;
}

AppLocalizationsGenerated lookupAppLocalizationsGenerated(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsGeneratedDe();
    case 'en':
      return AppLocalizationsGeneratedEn();
    case 'es':
      return AppLocalizationsGeneratedEs();
    case 'fr':
      return AppLocalizationsGeneratedFr();
    case 'ja':
      return AppLocalizationsGeneratedJa();
    case 'ko':
      return AppLocalizationsGeneratedKo();
    case 'ru':
      return AppLocalizationsGeneratedRu();
    case 'zh':
      return AppLocalizationsGeneratedZh();
  }

  throw FlutterError(
      'AppLocalizationsGenerated.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
