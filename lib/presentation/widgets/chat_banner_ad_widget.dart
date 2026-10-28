import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/ad_service.dart';

/// Banner ad for the bottom of Astro Chat, below the input bar. Shows
/// nothing at all until the ad has actually loaded (no placeholder box
/// reserving space and no error UI) — a failed/loading ad must never
/// visually compete with or crowd the input area.
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
      onFailed: (_) {
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

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
