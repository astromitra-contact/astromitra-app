import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/chat_models.dart';

/// Compact credit display. Every number here is read straight from a
/// [CreditStatus] the backend returned — nothing is computed client-side.
class CreditBadge extends StatelessWidget {
  final CreditStatus? status;
  final bool isLoading;
  final VoidCallback? onTap;

  const CreditBadge({super.key, required this.status, this.isLoading = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.brassBright),
            const SizedBox(width: 6),
            if (isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brassBright),
              )
            else
              Text(
                status != null ? '${status!.remainingCredits} Credits' : '\u2014',
                style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fuller card version, used on the Home screen.
class CreditSummaryCard extends StatelessWidget {
  final CreditStatus? status;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const CreditSummaryCard({
    super.key,
    required this.status,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: isLoading
            ? const SizedBox(
                height: 44,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.brass)),
              )
            : errorMessage != null
                ? Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(errorMessage!, style: AppTextStyles.bodySecondary)),
                      if (onRetry != null)
                        TextButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  )
                : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final s = status;
    if (s == null) {
      return const Text('Credits will appear once you ask your first question.', style: AppTextStyles.bodySecondary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your credits today', style: AppTextStyles.label),
            if (s.rewardClaimedToday)
              const _Pill(text: 'Bonus claimed', color: AppColors.success, bg: AppColors.successBg),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${s.remainingCredits}', style: AppTextStyles.displayMedium),
            const SizedBox(width: 6),
            const Text('credits remaining', style: AppTextStyles.bodySecondary),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: CreditStatus.maxNormalQuestions == 0
                ? 0
                : (s.normalQuestionsUsed / CreditStatus.maxNormalQuestions).clamp(0, 1).toDouble(),
            minHeight: 6,
            backgroundColor: AppColors.surfaceInput,
            valueColor: const AlwaysStoppedAnimation(AppColors.brass),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;

  const _Pill({required this.text, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
