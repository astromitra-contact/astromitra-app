import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/kundli_provider.dart';
import '../widgets/brand_emblem.dart';
import '../widgets/star_field_background.dart';
import 'main_shell.dart';
import 'onboarding/onboarding_flow_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final kundliProvider = context.read<KundliProvider>();
    await kundliProvider.bootstrap();
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => kundliProvider.hasActiveKundli ? const MainShell() : const OnboardingFlowScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StarFieldBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                const BrandEmblem(size: 140),
                const SizedBox(height: 28),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    children: [
                      TextSpan(text: 'Astro', style: TextStyle(color: AppColors.textPrimary)),
                      TextSpan(text: 'Mitra', style: TextStyle(color: AppColors.goldBright)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Vedic Astrology, Kundli & Horoscope',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15, letterSpacing: 0.3),
                  ),
                ),
                const Spacer(flex: 2),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
