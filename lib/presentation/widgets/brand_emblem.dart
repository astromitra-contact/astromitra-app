import 'package:flutter/material.dart';

/// The AstroMitra brand icon — loaded from the bundled asset.
/// Drop-in replacement for the old painted emblem; every existing
/// `BrandEmblem(size: x)` call will now show the real logo image.
class BrandEmblem extends StatelessWidget {
  final double size;

  const BrandEmblem({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/astro-icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
