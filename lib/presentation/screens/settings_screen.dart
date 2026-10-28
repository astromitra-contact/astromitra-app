import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/credit_provider.dart';
import '../providers/kundli_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/credit_badge.dart';
import 'onboarding/onboarding_flow_screen.dart';
import 'view_kundli_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kundliProvider = context.watch<KundliProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final details = kundliProvider.activeKundliData?.birthDetails;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
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
                          details != null && details.name.isNotEmpty
                              ? details.name
                              : context.tr('guestUser'),
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            _SectionLabel(context.tr('yourKundli')),
            _SettingsTile(
              icon: Icons.auto_awesome_outlined,
              label: context.tr('myKundli'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViewKundliScreen())),
            ),
            _SettingsTile(
              icon: Icons.edit_outlined,
              label: context.tr('editBirthDetails'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => OnboardingFlowScreen(initialDetails: details),
              )),
            ),
            _SettingsTile(
              icon: Icons.bolt_outlined,
              label: context.tr('dailyCredits'),
              onTap: () => _showCreditsSheet(context),
            ),

            const SizedBox(height: 8),
            _SectionLabel(context.tr('appLanguage')),
            _SettingsTile(
              icon: Icons.language_rounded,
              label: context.tr('appLanguage'),
              trailingText: languageProvider.currentLanguage.nativeName,
              onTap: () => _showLanguageSheet(context),
            ),

            const SizedBox(height: 8),
            _SectionLabel(context.tr('about')),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: context.tr('privacyPolicy'),
              onTap: () => _openUrl(context, 'https://astromitra-policy.nextrendx.in/privacy-policy.html'),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: context.tr('termsConditions'),
              onTap: () => _openUrl(context, 'https://astromitra-policy.nextrendx.in/terms-and-conditions.html'),
            ),
            _SettingsTile(
              icon: Icons.share_outlined,
              label: context.tr('shareApp'),
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
                child: Text(context.tr('deleteAccount')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (scrollContext, scrollController) {
            final langProv = bottomSheetContext.watch<LanguageProvider>();
            final current = langProv.currentLanguage;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.gold, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        bottomSheetContext.tr('selectAppLanguage'),
                        style: AppTextStyles.heading,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderSoft),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: AppLanguage.values.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final lang = AppLanguage.values[index];
                      final isSelected = lang == current;

                      return Material(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.12)
                            : AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppColors.gold : AppColors.borderSoft,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.gold : AppColors.textMuted,
                                width: 2,
                              ),
                              color: isSelected ? AppColors.gold : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 15, color: AppColors.onGold)
                                : null,
                          ),
                          title: Text(
                            lang.nativeName,
                            style: TextStyle(
                              color: isSelected ? AppColors.goldBright : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            lang.name,
                            style: TextStyle(
                              color: isSelected ? AppColors.gold : AppColors.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                          trailing: isSelected
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: AppColors.goldBright,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            langProv.setLanguage(lang);
                            Navigator.of(bottomSheetContext).pop();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
        'https://play.google.com/store/apps/details?id=com.astromitra.kundli';

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
        title: Text(context.tr('deleteConfirmTitle')),
        content: Text(
          context.tr('deleteConfirmDesc'),
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('delete'), style: const TextStyle(color: AppColors.danger)),
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
  final String? trailingText;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailingText,
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
          trailing: trailingText != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailingText!,
                      style: const TextStyle(
                        color: AppColors.goldBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                  ],
                )
              : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          onTap: onTap,
        ),
      ),
    );
  }
}
