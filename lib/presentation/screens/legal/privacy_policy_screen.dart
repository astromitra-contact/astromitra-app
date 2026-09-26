import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'legal_scaffold.dart';

/// Original placeholder copy — written for this app, not copied from any
/// other product's policy. IMPORTANT: this is a starting template, not a
/// finished legal document. Before a real Play Store release, have this
/// reviewed/finalized by a lawyer, and confirm it accurately reflects
/// what your actual backend deployment does (data retention, region,
/// which AI providers are enabled, your real contact details, etc).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreenScaffold(
      title: 'Privacy Policy',
      children: [
        _DraftNotice(),
        LegalParagraph('Last updated: [add date before publishing]'),
        LegalHeading('What we collect'),
        LegalParagraph(
          'When you create a Kundli, you provide your name, date of birth, time of birth (optional), '
          'and birth place. This information is sent to the AstroMitra backend to calculate your birth '
          'chart and is stored there, referenced by a unique Kundli ID. That Kundli ID is stored securely '
          'on your device and is the only thing this app uses to identify your data going forward — there '
          'is no separate account, login, email, or phone number collected.',
        ),
        LegalParagraph(
          'If you use Astro Chat, the question you type is sent to the backend along with your Kundli ID. '
          'The backend uses your birth chart and current planetary positions to build a prompt, which is '
          'sent to a third-party AI provider (such as Google Gemini or Groq) to generate an answer. Your '
          'question and the AI\'s answer are not stored by this app beyond your device\'s local chat '
          'history, which you can clear at any time from Settings.',
        ),
        LegalHeading('Advertising'),
        LegalParagraph(
          'This app shows ads via Google AdMob: a banner ad in Astro Chat, and an optional rewarded video '
          'ad you can choose to watch for bonus credits. AdMob may collect device and advertising '
          'identifiers to serve and measure ads, per Google\'s own policies. You can review Google\'s '
          'practices at https://policies.google.com/technologies/ads.',
        ),
        LegalHeading('What we don\'t do'),
        LegalParagraph(
          'This app does not have a login system, does not collect your email or phone number, and does '
          'not sell your personal data. Your Kundli ID is not linked to any advertising identifier by this '
          'app.',
        ),
        LegalHeading('Your choices'),
        LegalParagraph(
          'You can delete your Kundli and all locally-stored data at any time via Settings \u2192 Delete '
          'Account / Kundli. This removes the Kundli ID and cached data from your device. [Add here '
          'whether/how a person can also request deletion of the corresponding record on the backend, '
          'based on your actual data retention practice.]',
        ),
        LegalHeading('Contact'),
        LegalParagraph('[Add your support email or contact method before publishing.]'),
      ],
    );
  }
}

class _DraftNotice extends StatelessWidget {
  const _DraftNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
      child: const Text(
        'Draft template — have this reviewed by a lawyer and filled in with your real details before '
        'publishing to the Play Store.',
        style: TextStyle(color: AppColors.warning, fontSize: 12, height: 1.4),
      ),
    );
  }
}
