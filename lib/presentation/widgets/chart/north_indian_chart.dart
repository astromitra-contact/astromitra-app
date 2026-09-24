import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The classic North Indian ("diamond") Kundli layout — house-fixed, with
/// House 1 (the Ascendant) always at the top and the rest numbered
/// clockwise. Construction: an outer square, both of its corner-to-corner
/// diagonals, and the diamond formed by connecting the midpoints of its
/// four sides. Together those lines divide the square into exactly the
/// twelve traditional house regions.
class NorthIndianChart extends StatelessWidget {
  /// House number (1-12) -> planet abbreviations occupying that house.
  final Map<int, List<String>> housePlanets;

  const NorthIndianChart({super.key, required this.housePlanets});

  // Centroids (as fractions of the square's width/height) for each house,
  // derived from the geometry described above.
  static const Map<int, Offset> _centroids = {
    1: Offset(0.50, 0.26),
    2: Offset(0.75, 0.10),
    3: Offset(0.90, 0.26),
    4: Offset(0.74, 0.50),
    5: Offset(0.90, 0.74),
    6: Offset(0.75, 0.90),
    7: Offset(0.50, 0.74),
    8: Offset(0.25, 0.90),
    9: Offset(0.10, 0.74),
    10: Offset(0.26, 0.50),
    11: Offset(0.10, 0.26),
    12: Offset(0.25, 0.10),
  };

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth;
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _NorthIndianLinesPainter())),
              for (final entry in _centroids.entries)
                Positioned(
                  left: entry.value.dx * side - 26,
                  top: entry.value.dy * side - 16,
                  width: 52,
                  height: 32,
                  child: _HouseLabel(
                    houseNumber: entry.key,
                    planets: housePlanets[entry.key] ?? const [],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HouseLabel extends StatelessWidget {
  final int houseNumber;
  final List<String> planets;

  const _HouseLabel({required this.houseNumber, required this.planets});

  @override
  Widget build(BuildContext context) {
    final isAscendant = houseNumber == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            if (isAscendant)
              const Text('Asc', style: TextStyle(color: AppColors.goldBright, fontSize: 11, fontWeight: FontWeight.w800)),
            for (final p in planets)
              Text(
                p,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ],
    );
  }
}

class _NorthIndianLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final tl = Offset(0, 0);
    final tr = Offset(w, 0);
    final br = Offset(w, h);
    final bl = Offset(0, h);
    final t = Offset(w / 2, 0);
    final r = Offset(w, h / 2);
    final b = Offset(w / 2, h);
    final l = Offset(0, h / 2);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), line);
    canvas.drawLine(tl, br, line);
    canvas.drawLine(tr, bl, line);
    canvas.drawLine(t, l, line);
    canvas.drawLine(t, r, line);
    canvas.drawLine(b, l, line);
    canvas.drawLine(b, r, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
