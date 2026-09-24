import 'package:flutter/material.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Ads SDK once, at startup, so both the Astro Chat
  // banner and the rewarded-ad flow can load without a first-use delay.
  // A failure here (e.g. no network at launch) is intentionally
  // non-fatal — ad widgets handle their own load failures gracefully
  // (see ChatBannerAdWidget / AdService.showRewardedAd) and the rest of
  // the app does not depend on ads to function.
  await AdService.instance.initialize();

  runApp(const AstroMitraApp());
}
