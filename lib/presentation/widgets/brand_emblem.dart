import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The gold "radiant compass" mark used on the splash screen and as a
/// small motif elsewhere. Painted rather than an image asset so it stays
/// crisp at any size and needs no bundled artwork.
class BrandEmblem extends StatelessWidget {
  final double size;

  const BrandEmblem({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EmblemPainter()),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..color = AppColors.gold.withValues(alpha: 0.85);
    canvas.drawCircle(center, r * 0.98, ring);
    canvas.drawCircle(center, r * 0.74, ring..color = AppColors.gold.withValues(alpha: 0.55));

    // Zodiac tick marks around the outer ring.
    for (var i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi;
      final inner = Offset(center.dx + cos(angle) * r * 0.86, center.dy + sin(angle) * r * 0.86);
      final outer = Offset(center.dx + cos(angle) * r * 0.94, center.dy + sin(angle) * r * 0.94);
      canvas.drawLine(inner, outer, Paint()..color = AppColors.gold.withValues(alpha: 0.5)..strokeWidth = 1.2);
    }

    // Radiant sunburst spikes.
    final spikePaint = Paint()..color = AppColors.goldBright;
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final long = i.isEven;
      final len = long ? r * 0.62 : r * 0.4;
      final tip = Offset(center.dx + cos(angle) * len, center.dy + sin(angle) * len);
      final baseWidth = long ? r * 0.09 : r * 0.06;
      final perp = angle + pi / 2;
      final b1 = Offset(center.dx + cos(perp) * baseWidth, center.dy + sin(perp) * baseWidth);
      final b2 = Offset(center.dx - cos(perp) * baseWidth, center.dy - sin(perp) * baseWidth);
      final path = Path()
        ..moveTo(b1.dx, b1.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(b2.dx, b2.dy)
        ..close();
      canvas.drawPath(path, spikePaint..color = AppColors.gold.withValues(alpha: long ? 0.95 : 0.6));
    }

    canvas.drawCircle(center, r * 0.16, Paint()..color = AppColors.goldBright);
    canvas.drawCircle(center, r * 0.16, ring..color = AppColors.background..strokeWidth = size.width * 0.02);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
