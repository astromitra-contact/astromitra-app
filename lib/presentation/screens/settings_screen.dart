import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/credit_provider.dart';
import '../providers/kundli_provider.dart';
import '../widgets/credit_badge.dart';
import 'onboarding/onboarding_flow_screen.dart';
import 'view_kundli_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kundliProvider = context.watch<KundliProvider>();
    final details = kundliProvider.activeKundliData?.birthDetails;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(gradient: AppColors.glyphGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: AppColors.onGold, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details != null && details.name.isNotEmpty ? details.name : 'Guest',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const _SectionLabel('Your Kundli'),
            _SettingsTile(
              icon: Icons.auto_awesome_outlined,
              label: 'My Kundli',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViewKundliScreen())),
            ),
            _SettingsTile(
              icon: Icons.edit_outlined,
              label: 'Edit Birth Details',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => OnboardingFlowScreen(initialDetails: details),
              )),
            ),
            _SettingsTile(
              icon: Icons.bolt_outlined,
              label: 'Daily Credits',
              onTap: () => _showCreditsSheet(context),
            ),


            const SizedBox(height: 8),
            const _SectionLabel('About'),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _openUrl(context, 'https://astromitra-policy.nextrendx.in/privacy-policy.html'),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () => _openUrl(context, 'https://astromitra-policy.nextrendx.in/terms-and-conditions.html'),
            ),
            _SettingsTile(
              icon: Icons.share_outlined,
              label: 'Share App',
              onTap: () => _shareApp(context),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: () => _confirmDelete(context),
                child: const Text('Delete Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    const shareText =
        '🌟 AstroMitra — Vedic Kundli & AI Astrology 🌟\n\n'
        'Get instant insights into your Janam Kundli, Daily Horoscope, Doshas, and chat directly with AstroMitra AI!\n\n'
        '📲 Download now from Google Play Store:\n'
        'https://play.google.com/store/apps/details?id=com.astromitra.app';

    try {
      final byteData = await rootBundle.load('assets/astro-icon.png');
      final tempDir = await getTemporaryDirectory();
      final iconFile = File('${tempDir.path}/astromitra_icon.png');
      await iconFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush: true,
      );

      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          files: [XFile(iconFile.path, mimeType: 'image/png')],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    }
  }



  void _showCreditsSheet(BuildContext context) {
    final creditProvider = context.read<CreditProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: CreditSummaryCard(
          status: creditProvider.status,
          isLoading: creditProvider.isLoading,
          errorMessage: creditProvider.errorMessage,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete account and Kundli data?'),
        content: const Text(
          'This removes your Kundli, chat history, and credit reference from this device permanently. '
          'This cannot be undone from within the app.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<KundliProvider>().deleteAllLocalData();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
      (route) => false,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Text(text, style: AppTextStyles.caption),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: AppColors.gold, size: 21),
          title: Text(label, style: AppTextStyles.body),
          onTap: onTap,
        ),
      ),
    );
  }
}
