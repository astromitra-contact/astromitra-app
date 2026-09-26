import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/horoscope_models.dart';
import '../providers/horoscope_provider.dart';
import '../providers/kundli_provider.dart';
import '../widgets/star_field_background.dart';

class DailyHoroscopeScreen extends StatefulWidget {
  const DailyHoroscopeScreen({super.key});

  @override
  State<DailyHoroscopeScreen> createState() => _DailyHoroscopeScreenState();
}

class _DailyHoroscopeScreenState extends State<DailyHoroscopeScreen> {
  final ScrollController _signsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kundliProvider = context.read<KundliProvider>();
      final kundliId = kundliProvider.activeKundliId;
      final planets = kundliProvider.activeKundliData?.planets ?? [];
      String? moonRashi;
      for (final p in planets) {
        if (p.key == 'moon' && p.rashiEnglish.isNotEmpty) {
          moonRashi = p.rashiEnglish;
          break;
        }
      }

      final horoscopeProvider = context.read<HoroscopeProvider>();
      horoscopeProvider.initialize(kundliId: kundliId, moonRashi: moonRashi).then((_) {
        _scrollToSelectedSign(horoscopeProvider.selectedSignIndex);
      });
    });
  }

  void _scrollToSelectedSign(int index) {
    if (!_signsScrollController.hasClients) return;
    const itemWidth = 84.0;
    final targetOffset = (index * itemWidth) - 40;
    _signsScrollController.animateTo(
      targetOffset.clamp(0.0, _signsScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _signsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HoroscopeProvider>();
    final horoscope = provider.horoscope;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StarFieldBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, provider),
              const SizedBox(height: 6),
              _buildSignsCarousel(provider),
              const SizedBox(height: 6),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.goldBright,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: () => provider.loadHoroscope(),
                  child: _buildBody(provider, horoscope),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, HoroscopeProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                    children: [
                      TextSpan(text: 'Daily ', style: TextStyle(color: AppColors.textPrimary)),
                      TextSpan(text: 'Horoscope', style: TextStyle(color: AppColors.goldBright)),
                    ],
                  ),
                ),
                Text(
                  'Today • ${provider.displayDateHeader}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignsCarousel(HoroscopeProvider provider) {
    const signsList = HoroscopeProvider.defaultSigns;
    return SizedBox(
      height: 74,
      child: ListView.separated(
        controller: _signsScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: signsList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sign = signsList[index];
          final isSelected = provider.selectedSignIndex == index;

          return GestureDetector(
            onTap: () {
              provider.selectSignIndex(index);
              _scrollToSelectedSign(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.goldBright : AppColors.border,
                  width: isSelected ? 1.6 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sign['symbol']!,
                    style: TextStyle(
                      fontSize: 18,
                      color: isSelected ? AppColors.goldBright : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sign['english']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.goldBright : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    sign['rashi']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isSelected ? AppColors.textSecondary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(HoroscopeProvider provider, DailyHoroscope? horoscope) {
    if (provider.isLoading && horoscope == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Aligning cosmic energies...', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    if (provider.state == HoroscopeState.error && horoscope == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.goldBright, size: 48),
              const SizedBox(height: 14),
              const Text('Could not fetch Horoscope', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.loadHoroscope(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.onGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (horoscope == null) return const SizedBox.shrink();

    final isUserOwnRashi = provider.userMoonRashi != null &&
        (provider.userMoonRashi!.toLowerCase() == horoscope.sign.toLowerCase() ||
         provider.userMoonRashi!.toLowerCase() == horoscope.rashi.toLowerCase());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (isUserOwnRashi && horoscope.isPersonalized && horoscope.userName != null)
          _buildPersonalizedHeaderCard(horoscope),
        _buildSignHeaderCard(horoscope),
        const SizedBox(height: 14),
        _buildLuckyMatrix(horoscope),
        const SizedBox(height: 14),
        _buildCosmicOverviewCard(horoscope),
        const SizedBox(height: 14),
        _buildAspectCard(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFF472B6),
          title: 'Love & Relationships',
          content: horoscope.love,
          score: horoscope.scores.love,
        ),
        const SizedBox(height: 12),
        _buildAspectCard(
          icon: Icons.work_rounded,
          iconColor: const Color(0xFF60A5FA),
          title: 'Career & Ambition',
          content: horoscope.career,
          score: horoscope.scores.career,
        ),
        const SizedBox(height: 12),
        _buildAspectCard(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF34D399),
          title: 'Money & Finances',
          content: horoscope.finance,
          score: horoscope.scores.finance,
        ),
        const SizedBox(height: 12),
        _buildAspectCard(
          icon: Icons.spa_rounded,
          iconColor: const Color(0xFFA78BFA),
          title: 'Health & Vitality',
          content: horoscope.health,
          score: horoscope.scores.health,
        ),
        const SizedBox(height: 14),
        _buildRemedyCard(horoscope),
        const SizedBox(height: 14),
        _buildTransitInfoCard(horoscope),
      ],
    );
  }

  Widget _buildPersonalizedHeaderCard(DailyHoroscope horoscope) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: AppColors.goldBright, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalized for ${horoscope.userName}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldBright,
                  ),
                ),
                Text(
                  'Janma Rashi (Moon): ${horoscope.userMoonRashi ?? horoscope.sign}${horoscope.userLagna != null ? " • Lagna: ${horoscope.userLagna}" : ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignHeaderCard(DailyHoroscope horoscope) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.glyphGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    horoscope.symbol,
                    style: const TextStyle(fontSize: 28, color: AppColors.onGold, height: 1),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${horoscope.sign} (${horoscope.rashi})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${horoscope.element} Element • Lord: ${horoscope.rashiLord}',
                      style: const TextStyle(fontSize: 12, color: AppColors.goldBright, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      horoscope.dates,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${horoscope.scores.overall}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldBright,
                      ),
                    ),
                    const Text(
                      'Cosmic Flow',
                      style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.goldBright),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    horoscope.theme,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyMatrix(DailyHoroscope horoscope) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cosmic Alignment Indicators', style: AppTextStyles.label),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMatrixTile(
                icon: Icons.numbers_rounded,
                label: 'Lucky Number',
                value: '${horoscope.luckyNumber}',
              ),
              _buildMatrixTile(
                icon: Icons.palette_rounded,
                label: 'Lucky Color',
                value: horoscope.luckyColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMatrixTile(
                icon: Icons.schedule_rounded,
                label: 'Shubh Muhurat',
                value: horoscope.luckyTime,
              ),
              _buildMatrixTile(
                icon: Icons.language_rounded,
                label: 'Ruling Planet',
                value: horoscope.rashiLord,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.goldBright, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCosmicOverviewCard(DailyHoroscope horoscope) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: AppColors.goldBright, size: 20),
              SizedBox(width: 10),
              Text('Day Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            horoscope.overview,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required int score,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 4,
              backgroundColor: AppColors.borderSoft,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemedyCard(DailyHoroscope horoscope) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.15),
            AppColors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_rounded, color: AppColors.goldBright, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cosmic Advice for Today',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.goldBright),
                ),
                const SizedBox(height: 4),
                Text(
                  horoscope.cosmicTip,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitInfoCard(DailyHoroscope horoscope) {
    final t = horoscope.transitDetails;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Planetary Transit Snapshot', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Text(
            t.transitSummary,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildTransitBadge('Moon: ${t.moonSign}'),
              _buildTransitBadge('Nakshatra: ${t.moonNakshatra}'),
              _buildTransitBadge('Tithi: ${t.tithi}'),
              _buildTransitBadge('Day Ruler: ${t.dayLord}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransitBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
      ),
    );
  }
}
