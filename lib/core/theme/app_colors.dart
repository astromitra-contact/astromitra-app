import 'package:flutter/material.dart';

/// Redesigned palette — a deep midnight-navy sky with warm gold accents,
/// matching the new AstroMitra visual direction: starfield backgrounds,
/// gold-bordered cards, and a single strong accent color used for CTAs,
/// icons, and highlighted numbers throughout the app.
class AppColors {
  AppColors._();

  // Base surfaces — solid black and dark charcoal surfaces.
  static const Color background = Color(0xFF000000);
  static const Color backgroundDeep = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceElevated = Color(0xFF161616);
  static const Color surfaceInput = Color(0xFF121212);

  // Borders — dark golden / charcoal with gold sheen.
  static const Color border = Color(0xFF262626);
  static const Color borderSoft = Color(0xFF1C1C1C);
  static const Color borderGold = Color(0xFFC59B27);

  // Typography — pure crisp white and silver.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFF888888);

  // Signature dark gold accents.
  static const Color gold = Color(0xFFC59B27);
  static const Color goldBright = Color(0xFFE5BE58);
  static const Color goldDeep = Color(0xFF8E6B18);
  static const Color onGold = Color(0xFF000000);

  // Kept for backward-compatible references across the codebase.
  static const Color brass = gold;
  static const Color brassBright = goldBright;
  static const Color violet = Color(0xFFC59B27);

  // Status colors.
  static const Color success = Color(0xFF4ADE80);
  static const Color successBg = Color(0xFF0F2316);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerBg = Color(0xFF261014);
  static const Color warning = Color(0xFFE5BE58);
  static const Color warningBg = Color(0xFF221A0C);

  // Solid flat single-color gradients (no gradient variations)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, gold],
  );

  static const LinearGradient brassGradient = goldGradient;

  static const RadialGradient glyphGradient = RadialGradient(
    colors: [gold, gold],
  );

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [surfaceElevated, surfaceElevated],
  );

  static const RadialGradient skyGlow = RadialGradient(
    colors: [background, background],
  );
}
