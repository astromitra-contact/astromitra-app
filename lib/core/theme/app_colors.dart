import 'package:flutter/material.dart';

/// Redesigned palette — a deep midnight-navy sky with warm gold accents,
/// matching the new AstroMitra visual direction: starfield backgrounds,
/// gold-bordered cards, and a single strong accent color used for CTAs,
/// icons, and highlighted numbers throughout the app.
class AppColors {
  AppColors._();

  // Base surfaces — layered navy, darkest at the very back.
  static const Color background = Color(0xFF090B1A);
  static const Color backgroundDeep = Color(0xFF05060F);
  static const Color surface = Color(0xFF12152B);
  static const Color surfaceElevated = Color(0xFF1A1E3A);
  static const Color surfaceInput = Color(0xFF101324);

  static const Color border = Color(0xFF2A2E52);
  static const Color borderSoft = Color(0xFF212545);
  static const Color borderGold = Color(0xFFB8863A);

  static const Color textPrimary = Color(0xFFF3F1FF);
  static const Color textSecondary = Color(0xFF9A9DC4);
  static const Color textMuted = Color(0xFF666B98);

  // Signature gold accent.
  static const Color gold = Color(0xFFE0A93A);
  static const Color goldBright = Color(0xFFF4CE72);
  static const Color goldDeep = Color(0xFFB07A1F);
  static const Color onGold = Color(0xFF1B1200);

  // Kept for backward-compatible references across the codebase.
  static const Color brass = gold;
  static const Color brassBright = goldBright;
  static const Color violet = Color(0xFF8D93FF);

  static const Color success = Color(0xFF6FCF97);
  static const Color successBg = Color(0xFF16241D);
  static const Color danger = Color(0xFFE8677A);
  static const Color dangerBg = Color(0xFF2A1620);
  static const Color warning = Color(0xFFE3B94A);
  static const Color warningBg = Color(0xFF2A2415);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldBright, gold],
  );

  // Backward-compatible alias.
  static const LinearGradient brassGradient = goldGradient;

  static const RadialGradient glyphGradient = RadialGradient(
    center: Alignment(-0.4, -0.4),
    colors: [goldBright, gold, goldDeep],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient bannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1440), Color(0xFF161230)],
  );

  static const RadialGradient skyGlow = RadialGradient(
    center: Alignment(0, -0.8),
    radius: 1.4,
    colors: [Color(0xFF1A1F45), background],
    stops: [0.0, 0.65],
  );
}
