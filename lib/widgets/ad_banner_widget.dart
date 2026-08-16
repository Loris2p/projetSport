import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/auth_provider.dart';
import '../services/ad_service.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _debugStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadAd();
  }

  void _checkAndLoadAd() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null || user.showAds != true) {
      if (_bannerAd != null) {
        _bannerAd?.dispose();
        _bannerAd = null;
      }
      if (_isLoaded || _debugStatus != "Publicités désactivées pour ce profil (showAds: false)") {
        setState(() {
          _isLoaded = false;
          _isLoading = false;
          _debugStatus = "Publicités désactivées pour ce profil (showAds: false)";
        });
      }
      return;
    }

    // Si la pub n'est pas encore chargée et n'est pas en cours de chargement
    if (_bannerAd == null && !_isLoading) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        _debugStatus = "Plateforme non mobile (${Platform.operatingSystem}) : AdMob indisponible";
      });
      return;
    }

    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId.isEmpty) {
      setState(() {
        _debugStatus = "Ad Unit ID non renseigné";
      });
      return;
    }

    _isLoading = true;
    _debugStatus = "Chargement de la bannière AdMob...";

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
              _debugStatus = "Bannière AdMob chargée avec succès";
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint("Échec du chargement de la bannière AdMob: $err");
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _isLoading = false;
              _bannerAd = null;
              _debugStatus = "Erreur AdMob ${err.code}: ${err.message}";
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isTest = AdService.isTestMode;

    // Si les publicités sont désactivées pour l'utilisateur
    if (user == null || user.showAds != true) {
      if (isTest) {
        return _buildDebugContainer(
          icon: Icons.visibility_off,
          color: const Color(0xfff59e0b),
          message: "Mode Test : Pubs désactivées (showAds = false)",
        );
      }
      return const SizedBox.shrink();
    }

    // Sur plateformes non supportées par AdMob (Web / Desktop)
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (isTest) {
        return _buildDebugContainer(
          icon: Icons.developer_mode,
          color: const Color(0xff3b82f6),
          message: "Mode Test AdMob (Simulé sur ${Platform.operatingSystem})",
        );
      }
      return const SizedBox.shrink();
    }

    // Affichage de la vraie bannière AdMob une fois chargée
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // En mode test, si l'annonce n'est pas encore prête ou a échoué
    if (isTest) {
      return _buildDebugContainer(
        icon: _isLoading ? Icons.hourglass_top : Icons.info_outline,
        color: _isLoading ? const Color(0xff6366f1) : const Color(0xffef4444),
        message: _debugStatus ?? "Chargement bannière AdMob...",
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDebugContainer({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
