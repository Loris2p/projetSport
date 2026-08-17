import 'dart:io';
import 'package:flutter/foundation.dart';
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

  static const String _envTestAndroidInterstitialId = String.fromEnvironment('ADMOB_TEST_ANDROID_INTERSTITIAL_ID');
  static const String _envProdAndroidInterstitialId = String.fromEnvironment('ADMOB_PROD_ANDROID_INTERSTITIAL_ID');
  static const String _envTestIosInterstitialId = String.fromEnvironment('ADMOB_TEST_IOS_INTERSTITIAL_ID');
  static const String _envProdIosInterstitialId = String.fromEnvironment('ADMOB_PROD_IOS_INTERSTITIAL_ID');

  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoading = false;

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
        'admob_prod_android_interstitial_id': '',
        'admob_prod_ios_app_id': '',
        'admob_prod_ios_banner_id': '',
        'admob_prod_ios_interstitial_id': '',
      });
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint("Info Firebase Remote Config : $e");
    }

    // Précharge proactivement une publicité interstitielle
    loadInterstitialAd();
  }

  /// Vérifie si le mode test AdMob est activé (Remote Config > --dart-define > défaut true)
  static bool get isTestMode {
    final remoteVal = _getRemoteConfigString('admob_test_mode');
    if (remoteVal != null) {
      return remoteVal.toLowerCase() == 'true' || remoteVal == '1';
    }

    const fromEnv = bool.hasEnvironment('ADMOB_TEST_MODE')
        ? bool.fromEnvironment('ADMOB_TEST_MODE')
        : null;
    if (fromEnv != null) return fromEnv;

    return true;
  }

  /// Récupère l'AdMob App ID (sécurisé via Remote Config / env / test)
  static String get appId {
    if (Platform.isAndroid) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_android_app_id') ??
            (_envTestAndroidAppId.isNotEmpty
                ? _envTestAndroidAppId
                : 'ca-app-pub-3940256099942544~3347511713');
      } else {
        return _getRemoteConfigString('admob_prod_android_app_id') ??
            (_envProdAndroidAppId.isNotEmpty ? _envProdAndroidAppId : '');
      }
    } else if (Platform.isIOS) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_ios_app_id') ??
            (_envTestIosAppId.isNotEmpty
                ? _envTestIosAppId
                : 'ca-app-pub-3940256099942544~1458002511');
      } else {
        return _getRemoteConfigString('admob_prod_ios_app_id') ??
            (_envProdIosAppId.isNotEmpty ? _envProdIosAppId : '');
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
                : 'ca-app-pub-3940256099942544/6300978111');
      } else {
        return _getRemoteConfigString('admob_prod_android_banner_id') ??
            (_envProdAndroidBannerId.isNotEmpty ? _envProdAndroidBannerId : '');
      }
    } else if (Platform.isIOS) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_ios_banner_id') ??
            (_envTestIosBannerId.isNotEmpty
                ? _envTestIosBannerId
                : 'ca-app-pub-3940256099942544/2934735716');
      } else {
        return _getRemoteConfigString('admob_prod_ios_banner_id') ??
            (_envProdIosBannerId.isNotEmpty ? _envProdIosBannerId : '');
      }
    }
    return '';
  }

  /// Récupère l'Ad Unit ID de l'interstitiel (sécurisé via Remote Config / env / test)
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_android_interstitial_id') ??
            (_envTestAndroidInterstitialId.isNotEmpty
                ? _envTestAndroidInterstitialId
                : 'ca-app-pub-3940256099942544/1033173712');
      } else {
        return _getRemoteConfigString('admob_prod_android_interstitial_id') ??
            (_envProdAndroidInterstitialId.isNotEmpty ? _envProdAndroidInterstitialId : '');
      }
    } else if (Platform.isIOS) {
      if (isTestMode) {
        return _getRemoteConfigString('admob_test_ios_interstitial_id') ??
            (_envTestIosInterstitialId.isNotEmpty
                ? _envTestIosInterstitialId
                : 'ca-app-pub-3940256099942544/4411468910');
      } else {
        return _getRemoteConfigString('admob_prod_ios_interstitial_id') ??
            (_envProdIosInterstitialId.isNotEmpty ? _envProdIosInterstitialId : '');
      }
    }
    return '';
  }

  /// Précharge une publicité interstitielle en arrière-plan
  static void loadInterstitialAd() {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (_isInterstitialLoading || _interstitialAd != null) return;

    final unitId = interstitialAdUnitId;
    if (unitId.isEmpty) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint("AdMob Interstitial chargé avec succès.");
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          debugPrint("Échec du chargement AdMob Interstitial: $error");
        },
      ),
    );
  }

  /// Affiche l'interstitiel s'il est prêt et appelle `onComplete` à la fermeture ou en cas de repli
  static void showInterstitialAd({required VoidCallback onComplete}) {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      onComplete();
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint("Aucun Interstitial disponible, passage direct.");
      loadInterstitialAd();
      onComplete();
      return;
    }

    bool hasCompleted = false;
    void safeComplete() {
      if (!hasCompleted) {
        hasCompleted = true;
        onComplete();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        safeComplete();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint("Échec de l'affichage AdMob Interstitial: $error");
        ad.dispose();
        _interstitialAd = null;
        safeComplete();
        loadInterstitialAd();
      },
    );

    try {
      ad.show();
    } catch (e) {
      debugPrint("Erreur lors de l'appel à show() sur l'interstitiel: $e");
      safeComplete();
      loadInterstitialAd();
    }
  }

  static String? _getRemoteConfigString(String key) {
    try {
      final value = FirebaseRemoteConfig.instance.getString(key).trim();
      return value.isNotEmpty ? value : null;
    } catch (_) {
      return null;
    }
  }
}
