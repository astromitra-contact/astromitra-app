import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/kundli_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/chat_banner_ad_widget.dart';
import '../widgets/kundli_chart_view.dart';
import '../widgets/primary_button.dart';
import 'onboarding/onboarding_flow_screen.dart';

/// The "Create Kundli" tab. Shows the active Kundli's chart (with the
/// North/South Indian toggle) when one exists on this device, or a
/// prompt to start the onboarding wizard when it doesn't. There is no
/// public `GET /api/kundli/:id` endpoint on the backend by design, so
/// this reads the chart captured locally at generation time rather than
/// making a network call.
class ViewKundliScreen extends StatelessWidget {
  const ViewKundliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kundliProvider = context.watch<KundliProvider>();
    final kundli = kundliProvider.activeKundliData;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. AD FIRST: At the very top of the screen
            const AppBannerAdWidget(),

            // 2. AFTER AD: The TopBar (like chat section)
            _buildTopBar(context),

            Expanded(
              child: kundli == null
                  ? _EmptyKundliPrompt(hasStaleId: kundliProvider.hasActiveKundli)
                  : KundliChartView(kundli: kundli),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'My Kundli',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyKundliPrompt extends StatelessWidget {
  final bool hasStaleId;

  const _EmptyKundliPrompt({required this.hasStaleId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(gradient: AppColors.glyphGradient, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.onGold, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              hasStaleId ? context.tr('chartNotAvailable') : context.tr('noKundliYet'),
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasStaleId
                  ? context.tr('staleKundliDesc')
                  : context.tr('noKundliDesc'),
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: context.tr('createKundli'),
              icon: Icons.auto_awesome_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
