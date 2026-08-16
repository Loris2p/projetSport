import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AdService {
  static const String _envTestAndroidAppId = String.fromEnvironment('ADMOB_TEST_ANDROID_APP_ID');
  static const String _envProdAndroidAppId = String.fromEnvironment('ADMOB_PROD_ANDROID_APP_ID');
  static const String _envTestIosAppId = String.fromEnvironment('ADMOB_TEST_IOS_APP_ID');
  static const String _envProdIosAppId = String.fromEnvironment('ADMOB_PROD_IOS_APP_ID');

  static const String _envTestAndroidBannerId = String.fromEnvironment('ADMOB_TEST_ANDROID_BANNER_ID');
  static const String _envProdAndroidBannerId = String.fromEnvironment('ADMOB_PROD_ANDROID_BANNER_ID');
  static const String _envTestIosBannerId = String.fromEnvironment('ADMOB_TEST_IOS_BANNER_ID');
  static const String _envProdIosBannerId = String.fromEnvironment('ADMOB_PROD_IOS_BANNER_ID');

  /// Initialise le SDK Mobile Ads (AdMob) et synchronise Firebase Remote Config
  static Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await MobileAds.instance.initialize();
    }

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults(const {
        'admob_test_mode': true,
        'admob_prod_android_app_id': '',
        'admob_prod_android_banner_id': '',
        'admob_prod_ios_app_id': '',
        'admob_prod_ios_banner_id': '',
      });
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint("Info Firebase Remote Config : $e");
    }
  }

  /// Vérifie si le mode test AdMob est activé (Remote Config > --dart-define > .env > défaut true)
  static bool get isTestMode {
    final remoteVal = _getRemoteConfigString('admob_test_mode');
    if (remoteVal != null) {
      return remoteVal.toLowerCase() == 'true' || remoteVal == '1';
    }

    const fromEnv = bool.hasEnvironment('ADMOB_TEST_MODE')
        ? bool.fromEnvironment('ADMOB_TEST_MODE')
        : null;
    if (fromEnv != null) return fromEnv;

    final dotEnvMode = _getDotEnv('ADMOB_TEST_MODE')?.trim().toLowerCase();
    return dotEnvMode == null || dotEnvMode == 'true' || dotEnvMode == '1';
  }

  /// Récupère l'AdMob App ID (sécurisé via Remote Config / env / test)
  static String get appId {
    if (Platform.isAndroid) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_android_app_id') ??
            (_envTestAndroidAppId.isNotEmpty
                ? _envTestAndroidAppId
                : (_getDotEnv('ADMOB_TEST_ANDROID_APP_ID') ?? 'ca-app-pub-3940256099942544~3347511713'));
      } else {
        return _getRemoteConfigString('admob_prod_android_app_id') ??
            (_envProdAndroidAppId.isNotEmpty
                ? _envProdAndroidAppId
                : (_getDotEnv('ADMOB_PROD_ANDROID_APP_ID') ?? ''));
      }
    } else if (Platform.isIOS) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_ios_app_id') ??
            (_envTestIosAppId.isNotEmpty
                ? _envTestIosAppId
                : (_getDotEnv('ADMOB_TEST_IOS_APP_ID') ?? 'ca-app-pub-3940256099942544~1458002511'));
      } else {
        return _getRemoteConfigString('admob_prod_ios_app_id') ??
            (_envProdIosAppId.isNotEmpty
                ? _envProdIosAppId
                : (_getDotEnv('ADMOB_PROD_IOS_APP_ID') ?? ''));
      }
    }
    return '';
  }

  /// Récupère l'Ad Unit ID de la bannière (sécurisé via Remote Config / env / test)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_android_banner_id') ??
            (_envTestAndroidBannerId.isNotEmpty
                ? _envTestAndroidBannerId
                : (_getDotEnv('ADMOB_TEST_ANDROID_BANNER_ID') ?? 'ca-app-pub-3940256099942544/6300978111'));
      } else {
        return _getRemoteConfigString('admob_prod_android_banner_id') ??
            (_envProdAndroidBannerId.isNotEmpty
                ? _envProdAndroidBannerId
                : (_getDotEnv('ADMOB_PROD_ANDROID_BANNER_ID') ?? ''));
      }
    } else if (Platform.isIOS) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_ios_banner_id') ??
            (_envTestIosBannerId.isNotEmpty
                ? _envTestIosBannerId
                : (_getDotEnv('ADMOB_TEST_IOS_BANNER_ID') ?? 'ca-app-pub-3940256099942544/2934735716'));
      } else {
        return _getRemoteConfigString('admob_prod_ios_banner_id') ??
            (_envProdIosBannerId.isNotEmpty
                ? _envProdIosBannerId
                : (_getDotEnv('ADMOB_PROD_IOS_BANNER_ID') ?? ''));
      }
    }
    return '';
  }

  static String? _getRemoteConfigString(String key) {
    try {
      final value = FirebaseRemoteConfig.instance.getString(key).trim();
      return value.isNotEmpty ? value : null;
    } catch (_) {
      return null;
    }
  }

  static String? _getDotEnv(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }
}
