import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/kundli_provider.dart';
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
      appBar: AppBar(title: const Text('My Kundli')),
      body: SafeArea(
        child: kundli == null
            ? _EmptyKundliPrompt(hasStaleId: kundliProvider.hasActiveKundli)
            : KundliChartView(kundli: kundli),
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
              hasStaleId ? 'Chart not available' : 'No Kundli yet',
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasStaleId
                  ? "This Kundli's chart data isn't cached on this device. Create a new one to see it here."
                  : 'Generate your Vedic birth chart — Ascendant, planets, houses, and more.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Create Kundli',
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
