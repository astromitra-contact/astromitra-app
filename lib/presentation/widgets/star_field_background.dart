import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Faint star scatter, used behind the landing/splash screens — the same
/// visual language as the admin panel's `.sky-texture` (deliberately
/// consistent branding across this app's surfaces), kept subtle so it
/// never competes with actual content.
class StarFieldBackground extends StatelessWidget {
  final Widget child;

  const StarFieldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.8),
                radius: 1.4,
                colors: [Color(0xFF1C2050), AppColors.background],
                stops: [0.0, 0.65],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _StarFieldPainter())),
        child,
      ],
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // fixed seed — stable, non-flickering scatter
    final paintGold = Paint()..color = AppColors.brass.withValues(alpha: 0.5);
    final paintWhite = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final paintViolet = Paint()..color = AppColors.violet.withValues(alpha: 0.4);

    for (var i = 0; i < 70; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height * 0.75;
      final radius = 0.6 + random.nextDouble() * 1.2;
      final paint = i % 9 == 0 ? paintGold : (i % 13 == 0 ? paintViolet : paintWhite);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The chart-wheel motif (concentric rings + 12 spokes), used once on the
/// landing screen as the "one bold visual idea" — mirrors the admin
/// panel's login screen for a consistent brand across both surfaces.
class ChartWheelDecoration extends StatelessWidget {
  final double size;

  const ChartWheelDecoration({super.key, this.size = 340});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ChartWheelPainter()),
    );
  }
}

class _ChartWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final fraction in [0.32, 0.55, 0.78, 1.0]) {
      ringPaint.color = AppColors.brass.withValues(alpha: 0.28 * (1.1 - fraction * 0.5));
      canvas.drawCircle(center, maxRadius * fraction, ringPaint);
    }

    final spokePaint = Paint()
      ..color = AppColors.violet.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    final tickPaint = Paint()..color = AppColors.brass.withValues(alpha: 0.55);

    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final end = Offset(
        center.dx + cos(angle) * maxRadius,
        center.dy + sin(angle) * maxRadius,
      );
      canvas.drawLine(center, end, spokePaint);
      canvas.drawCircle(end, 2.2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
