import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/ad_service.dart';
import '../../core/theme/app_colors.dart';

/// Reusable Banner Ad widget positioned below the top AppBar.
typedef AppBannerAdWidget = ChatBannerAdWidget;

class ChatBannerAdWidget extends StatefulWidget {
  const ChatBannerAdWidget({super.key});

  @override
  State<ChatBannerAdWidget> createState() => _ChatBannerAdWidgetState();
}

class _ChatBannerAdWidgetState extends State<ChatBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = AdService.instance.createChatBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: (error) {
        debugPrint('ChatBannerAdWidget load failed: $error');
        if (mounted) setState(() => _loaded = false);
      },
    );
    if (ad == null) return;
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 0.8),
        ),
      ),
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
