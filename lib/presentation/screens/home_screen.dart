import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/chat_models.dart';
import '../providers/credit_provider.dart';
import '../providers/kundli_provider.dart';
import '../widgets/brand_emblem.dart';
import '../widgets/star_field_background.dart';
import 'astro_chat_screen.dart';
import 'onboarding/onboarding_flow_screen.dart';
import 'view_kundli_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCredits());
  }

  Future<void> _refreshCredits() async {
    final kundliId = context.read<KundliProvider>().activeKundliId;
    if (kundliId == null) return;
    await context.read<CreditProvider>().refresh(kundliId);
  }

  @override
  Widget build(BuildContext context) {
    final kundliProvider = context.watch<KundliProvider>();
    final creditProvider = context.watch<CreditProvider>();
    final name = kundliProvider.activeKundliData?.birthDetails.name;

    return Scaffold(
      body: StarFieldBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: BrandEmblem(size: 36),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                          children: [
                            TextSpan(text: 'Astro', style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(text: 'Mitra', style: TextStyle(color: AppColors.goldBright)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: name != null && name.isNotEmpty ? name : 'Guest User',
                    triggerMode: TooltipTriggerMode.tap,
                    preferBelow: true,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: AppColors.glyphGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, size: 16, color: AppColors.onGold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _WelcomeBanner(
                onExplore: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ViewKundliScreen()),
                ),
              ),
              const SizedBox(height: 22),
              const Text('What would you like to do?', style: AppTextStyles.heading),
              const SizedBox(height: 14),
              _HomeActionTile(
                icon: Icons.grid_view_rounded,
                title: 'Create Kundli',
                subtitle: 'Generate your detailed birth chart',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => kundliProvider.hasActiveKundli
                        ? const ViewKundliScreen()
                        : const OnboardingFlowScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _HomeActionTile(
                icon: Icons.chat_bubble_rounded,
                title: 'Chat with Astromitra',
                subtitle: 'Ask anything about your life and future',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AstroChatScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _DailyCreditsCard(
                status: creditProvider.status,
                isLoading: creditProvider.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCreditsCard extends StatelessWidget {
  final CreditStatus? status;
  final bool isLoading;

  const _DailyCreditsCard({required this.status, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final remaining = status?.remainingCredits;
    const total = 50;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Credits', style: AppTextStyles.label),
                const SizedBox(height: 10),
                if (isLoading)
                  const SizedBox(
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${remaining ?? total}', style: AppTextStyles.displayLarge),
                      const SizedBox(width: 4),
                      const Text('/ $total', style: AppTextStyles.bodySecondary),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: AppColors.goldBright),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final VoidCallback onExplore;

  const _WelcomeBanner({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.bannerGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Align with the stars,\nIlluminate your path.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: onExplore,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Explore Now'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const BrandEmblem(size: 76),
        ],
      ),
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: AppColors.goldBright, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}



