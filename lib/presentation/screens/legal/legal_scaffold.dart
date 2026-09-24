import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

class LegalScreenScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const LegalScreenScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: children,
        ),
      ),
    );
  }
}

class LegalHeading extends StatelessWidget {
  final String text;
  const LegalHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(text, style: AppTextStyles.heading),
    );
  }
}

class LegalParagraph extends StatelessWidget {
  final String text;
  const LegalParagraph(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: AppTextStyles.bodySecondary),
    );
  }
}
