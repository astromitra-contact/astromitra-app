import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/kundli_models.dart';
import 'chart/north_indian_chart.dart';
import 'chart/south_indian_chart.dart';
import 'primary_button.dart';

const Map<String, String> _planetAbbrev = {
  'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me', 'jupiter': 'Ju',
  'venus': 'Ve', 'saturn': 'Sa', 'rahu': 'Ra', 'ketu': 'Ke', 'uranus': 'Ur',
  'neptune': 'Ne', 'pluto': 'Pl',
};

String _abbreviate(PlanetInfo p) {
  final key = (p.key.isNotEmpty ? p.key : p.name).toLowerCase();
  final short = _planetAbbrev[key] ?? (p.name.isNotEmpty ? p.name.substring(0, p.name.length.clamp(0, 2)) : '?');
  return p.isRetrograde ? '${short}(R)' : short;
}

class KundliChartView extends StatefulWidget {
  final KundliData kundli;

  const KundliChartView({super.key, required this.kundli});

  @override
  State<KundliChartView> createState() => _KundliChartViewState();
}

class _KundliChartViewState extends State<KundliChartView> {
  int _tab = 0;
  bool _planetsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final kundli = widget.kundli;
    final details = kundli.birthDetails;

    final houseMap = <int, List<String>>{};
    final rashiMap = <String, List<String>>{};
    for (final p in kundli.planets) {
      if (p.houseNumber > 0) {
        houseMap.putIfAbsent(p.houseNumber, () => []).add(_abbreviate(p));
      }
      if (p.rashiEnglish.isNotEmpty) {
        rashiMap.putIfAbsent(p.rashiEnglish, () => []).add(_abbreviate(p));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        // North / South Indian tab switch.
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              Expanded(child: _TabButton(label: 'North Indian', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
              Expanded(child: _TabButton(label: 'South Indian', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: _tab == 0
              ? NorthIndianChart(housePlanets: houseMap)
              : SouthIndianChart(rashiPlanets: rashiMap, ascendantRashi: kundli.lagna?.rashiEnglish),
        ),

        if (kundli.timeAccuracy != null && !kundli.timeAccuracy!.isExact) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    kundli.timeAccuracy!.note,
                    style: const TextStyle(color: AppColors.warning, fontSize: 12.5, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (kundli.lagna != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gold.withValues(alpha: 0.18), AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ASCENDANT \u00b7 LAGNA', style: AppTextStyles.caption),
                const SizedBox(height: 8),
                Text(kundli.lagna!.rashi, style: AppTextStyles.displayMedium),
                const SizedBox(height: 4),
                Text(
                  '${kundli.lagna!.nakshatra} \u00b7 Pada ${kundli.lagna!.pada} \u00b7 ${kundli.lagna!.degreeInRashi.toStringAsFixed(2)}\u00b0',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 22),
        // Collapsible Planets Section Header
        InkWell(
          onTap: () => setState(() => _planetsExpanded = !_planetsExpanded),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.public_rounded, color: AppColors.goldBright, size: 20),
                    const SizedBox(width: 10),
                    const Text('Planetary Positions', style: AppTextStyles.heading),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${kundli.planets.length}',
                        style: const TextStyle(color: AppColors.goldBright, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Icon(
                  _planetsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_planetsExpanded) ...[
          const SizedBox(height: 10),
          ...kundli.planets.map((p) => _PlanetTile(planet: p)),
        ],

        const SizedBox(height: 22),
        // Line-by-line Birth Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_pin_rounded, color: AppColors.goldBright, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Birth Details',
                    style: TextStyle(
                      color: AppColors.goldBright,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Name',
                value: details.name.isEmpty ? '\u2014' : details.name,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.borderSoft),
              ),
              _DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date of Birth',
                value: details.dateOfBirth,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.borderSoft),
              ),
              _DetailRow(
                icon: Icons.access_time_rounded,
                label: 'Time of Birth',
                value: details.timeOfBirth ?? 'Not provided',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.borderSoft),
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Birth Place',
                value: kundli.location?.displayString ?? details.birthPlace,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Download Kundli',
          icon: Icons.download_rounded,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kundli PDF download is coming soon.')),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: AppTextStyles.bodySecondary.copyWith(fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.onGold : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PlanetTile extends StatelessWidget {
  final PlanetInfo planet;

  const _PlanetTile({required this.planet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Row(
              children: [
                Text(planet.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                if (planet.isRetrograde) ...[
                  const SizedBox(width: 4),
                  const Text('R', style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${planet.rashi} \u00b7 House ${planet.houseNumber}',
              style: AppTextStyles.bodySecondary,
            ),
          ),
          Text('${planet.nakshatra} P${planet.pada}', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
