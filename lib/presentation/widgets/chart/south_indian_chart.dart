import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The South Indian Kundli layout — rashi-fixed (each of the 12 outer
/// cells always belongs to the same zodiac sign, drawn clockwise starting
/// from Pisces at top-left), with the center 2x2 block reserved for a
/// small summary. Planets are placed by the sign (rashi) they occupy,
/// not by house number.
class SouthIndianChart extends StatelessWidget {
  /// English rashi name -> planet abbreviations occupying that sign.
  final Map<String, List<String>> rashiPlanets;
  final String? ascendantRashi;
  final String? centerLabel;

  const SouthIndianChart({
    super.key,
    required this.rashiPlanets,
    this.ascendantRashi,
    this.centerLabel,
  });

  // Row/col grid position (0-3, 0-3) for each of the 12 signs, clockwise
  // from Pisces at the top-left corner.
  static const List<String> _order = [
    'Pisces', 'Aries', 'Taurus', 'Gemini', // row 0
    'Cancer', // row1 col3
    'Leo', // row2 col3
    'Virgo', 'Libra', 'Scorpio', 'Sagittarius', // row 3 (right to left)
    'Capricorn', // row2 col0
    'Aquarius', // row1 col0
  ];

  static const Map<String, List<int>> _pos = {
    'Pisces': [0, 0],
    'Aries': [0, 1],
    'Taurus': [0, 2],
    'Gemini': [0, 3],
    'Cancer': [1, 3],
    'Leo': [2, 3],
    'Virgo': [3, 3],
    'Libra': [3, 2],
    'Scorpio': [3, 1],
    'Sagittarius': [3, 0],
    'Capricorn': [2, 0],
    'Aquarius': [1, 0],
  };

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / 4;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            ),
            child: Stack(
              children: [
                for (var row = 0; row < 4; row++)
                  for (var col = 0; col < 4; col++)
                    if (!(row > 0 && row < 3 && col > 0 && col < 3))
                      Positioned(
                        left: col * cell,
                        top: row * cell,
                        width: cell,
                        height: cell,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.6),
                          ),
                        ),
                      ),
                for (final sign in _order) _buildCell(sign, cell),
                Positioned(
                  left: cell,
                  top: cell,
                  width: cell * 2,
                  height: cell * 2,
                  child: Center(
                    child: Text(
                      centerLabel ?? 'AstroMitra',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: cell * 0.16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCell(String sign, double cell) {
    final pos = _pos[sign]!;
    final planets = rashiPlanets[sign] ?? const [];
    final isAscendant = sign == ascendantRashi;

    return Positioned(
      left: pos[1] * cell,
      top: pos[0] * cell,
      width: cell,
      height: cell,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 3,
            runSpacing: 1,
            children: [
              if (isAscendant)
                const Text('Asc', style: TextStyle(color: AppColors.goldBright, fontSize: 10.5, fontWeight: FontWeight.w800)),
              for (final p in planets)
                Text(
                  p,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
