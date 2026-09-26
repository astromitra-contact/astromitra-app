import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/chat_models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    final hasQuote = message.text.startsWith('> ') && message.text.contains('\n');
    String? quoteHeader;
    String? quoteBody;
    String mainText = message.text;

    if (hasQuote) {
      final firstLineEnd = message.text.indexOf('\n');
      final firstLine = message.text.substring(2, firstLineEnd).trim();
      mainText = message.text.substring(firstLineEnd + 1).trim();

      final colonIdx = firstLine.indexOf(':');
      if (colonIdx != -1) {
        quoteHeader = firstLine.substring(0, colonIdx).trim();
        quoteBody = firstLine.substring(colonIdx + 1).trim();
      } else {
        quoteHeader = isUser ? 'You' : 'AstroMitra';
        quoteBody = firstLine;
      }
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.brass
                    : (isSelected ? const Color(0xFF22201C) : AppColors.surfaceElevated),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isSelected
                    ? Border.all(color: AppColors.gold, width: 1.8)
                    : (isUser
                        ? null
                        : Border.all(color: AppColors.borderGold.withValues(alpha: 0.2))),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasQuote)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: isUser ? Colors.black54 : AppColors.gold,
                            width: 3.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            quoteHeader ?? '',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isUser ? Colors.black87 : AppColors.goldBright,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            quoteBody ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isUser
                                  ? Colors.black87.withValues(alpha: 0.75)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    mainText,
                    style: AppTextStyles.body.copyWith(
                      color: isUser ? AppColors.onGold : AppColors.textPrimary,
                      height: 1.36,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TypingIndicatorBubble extends StatelessWidget {
  const TypingIndicatorBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const SizedBox(
          width: 30,
          height: 14,
          child: _TypingDots(),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.2)) % 1.0;
            final opacity = (0.3 + 0.7 * (1 - (t - 0.5).abs() * 2)).clamp(0.3, 1.0).toDouble();
            return Opacity(
              opacity: opacity,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
              ),
            );
          }),
        );
      },
    );
  }
}
