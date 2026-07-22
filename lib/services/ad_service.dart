import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  /// Vérifie si le mode test AdMob est activé dans le fichier .env
  static bool get isTestMode {
    final mode = dotenv.env['ADMOB_TEST_MODE']?.trim().toLowerCase();
    return mode == null || mode == 'true' || mode == '1';
  }

  /// Initialise le SDK Mobile Ads (AdMob) sur les plateformes supportées (Android/iOS)
  static Future<void> initialize() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await MobileAds.instance.initialize();
    }
  }

  /// Récupère l'AdMob App ID en fonction du mode (Test ou Prod) et de la plateforme
  static String get appId {
    if (Platform.isAndroid) {
      return isTestMode
          ? (dotenv.env['ADMOB_TEST_ANDROID_APP_ID'] ?? 'ca-app-pub-3940256099942544~3347511713')
          : (dotenv.env['ADMOB_PROD_ANDROID_APP_ID'] ?? '');
    } else if (Platform.isIOS) {
      return isTestMode
          ? (dotenv.env['ADMOB_TEST_IOS_APP_ID'] ?? 'ca-app-pub-3940256099942544~1458002511')
          : (dotenv.env['ADMOB_PROD_IOS_APP_ID'] ?? '');
    }
    return '';
  }

  /// Récupère l'Ad Unit ID de la bannière en fonction du mode (Test ou Prod) et de la plateforme
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode
          ? (dotenv.env['ADMOB_TEST_ANDROID_BANNER_ID'] ?? 'ca-app-pub-3940256099942544/6300978111')
          : (dotenv.env['ADMOB_PROD_ANDROID_BANNER_ID'] ?? 'ca-app-pub-4700047368988620/6057410917');
    } else if (Platform.isIOS) {
      return isTestMode
          ? (dotenv.env['ADMOB_TEST_IOS_BANNER_ID'] ?? 'ca-app-pub-3940256099942544/2934735716')
          : (dotenv.env['ADMOB_PROD_IOS_BANNER_ID'] ?? '');
    }
    return '';
  }
}
