import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/chat_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/kundli_provider.dart';
import '../widgets/chat_banner_ad_widget.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/credit_badge.dart';
import '../widgets/primary_button.dart';
import '../widgets/state_views.dart';

class AstroChatScreen extends StatefulWidget {
  const AstroChatScreen({super.key});

  @override
  State<AstroChatScreen> createState() => _AstroChatScreenState();
}

class _AstroChatScreenState extends State<AstroChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final kundliId = context.read<KundliProvider>().activeKundliId;
    if (kundliId == null) return;
    context.read<ChatProvider>().addListener(_onChatUpdated);
    await context.read<ChatProvider>().loadForKundli(kundliId);
    if (!mounted) return;
    await context.read<CreditProvider>().refresh(kundliId);
    _scrollToBottom(animate: false);
  }

  void _onChatUpdated() {
    _scrollToBottom(animate: true);
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _handleSend() async {
    final kundliId = context.read<KundliProvider>().activeKundliId;
    final creditProvider = context.read<CreditProvider>();
    final canAsk = creditProvider.status?.canAskNow ?? true;

    if (!canAsk) {
      _showOutOfCreditsDialog();
      return;
    }

    final question = _textController.text.trim();
    if (kundliId == null || question.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    final chatProvider = context.read<ChatProvider>();
    final success = await chatProvider.sendQuestion(kundliId, question);
    _scrollToBottom();

    if (!mounted) return;

    if (success) {
      // Ask/reward-claim actions change server-side credit state — always
      // re-fetch the authoritative status rather than guessing locally.
      await context.read<CreditProvider>().refresh(kundliId);
    } else {
      if (chatProvider.questionLimitReached) {
        _showOutOfCreditsDialog();
      } else if (chatProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chatProvider.errorMessage!)));
      }
    }
  }

  void _showOutOfCreditsDialog() {
    final creditProvider = context.read<CreditProvider>();
    final isClaimed = creditProvider.status?.rewardClaimedToday ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4), width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: AppColors.glyphGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.onGold, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Get More Credits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You have used all of your daily credits.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 14),
              if (!isClaimed) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.video_collection_rounded, color: AppColors.goldBright, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Watch a short video ad to earn +20 extra credits!',
                          style: TextStyle(
                            color: AppColors.goldBright,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'You have already claimed today\'s bonus reward. Credits will reset tomorrow!',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            if (!isClaimed)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.onGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _handleClaimReward();
                },
                icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                label: const Text('Watch Ad (+20 Credits)', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleClaimReward() async {
    final kundliId = context.read<KundliProvider>().activeKundliId;
    if (kundliId == null) return;

    final creditProvider = context.read<CreditProvider>();
    final outcome = await creditProvider.claimDailyReward(kundliId);
    if (!mounted) return;

    final message = switch (outcome) {
      RewardClaimOutcome.success => 'Success! +20 extra credits added to your account.',
      RewardClaimOutcome.adNotCompleted => 'Watch the full ad to earn +20 bonus credits.',
      RewardClaimOutcome.alreadyClaimed => 'You\'ve already claimed today\'s bonus.',
      RewardClaimOutcome.notEligibleYet => 'The bonus unlocks after your daily credits are used up.',
      RewardClaimOutcome.error => creditProvider.errorMessage ?? 'Could not claim bonus right now.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: outcome == RewardClaimOutcome.success ? AppColors.success : null,
      ),
    );

    if (outcome == RewardClaimOutcome.success) {
      context.read<ChatProvider>().clearError();
      await creditProvider.refresh(kundliId);
    }
  }

  Future<void> _confirmClearChat() async {
    final kundliId = context.read<KundliProvider>().activeKundliId;
    if (kundliId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        title: const Text('Clear chat history?'),
        content: const Text(
          'This will clear all messages in this conversation and start fresh.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ChatProvider>().clearHistory(kundliId);
    }
  }

  @override
  void dispose() {
    try {
      context.read<ChatProvider>().removeListener(_onChatUpdated);
    } catch (_) {}
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kundliProvider = context.watch<KundliProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final creditProvider = context.watch<CreditProvider>();

    final kundliId = kundliProvider.activeKundliId;
    // Keyboard-open detection drives both the Scaffold's natural resize
    // (default behavior) AND whether the banner ad is shown at all — the
    // ad must never be present while the keyboard could push it into/over
    // the input area, per spec.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    if (kundliId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Astro Chat')),
        body: const SafeArea(
          child: EmptyStateView(
            icon: Icons.auto_awesome_outlined,
            title: 'No Kundli yet',
            message: 'Create a Kundli first so Astro Chat has a chart to answer from.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(gradient: AppColors.glyphGradient, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.onGold, size: 15),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AstroMitra',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Online', style: TextStyle(fontSize: 11, color: AppColors.success)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: CreditBadge(status: creditProvider.status, isLoading: creditProvider.isLoading),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
            color: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderSoft),
            ),
            elevation: 8,
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClearChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text(
                      'Clear Chat',
                      style: TextStyle(color: AppColors.danger, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      // Default resizeToAvoidBottomInset (true) shrinks the body when the
      // keyboard opens, which is what naturally keeps the input bar
      // sitting right above the keyboard rather than being hidden behind
      // it — combined with hiding the banner ad below, nothing ends up
      // clipped or covered in either state.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList(chatProvider)),

            if (chatProvider.questionLimitReached)
              _RewardPromptBanner(
                isClaiming: creditProvider.isClaimingReward,
                rewardEligible: creditProvider.status?.rewardEligible ?? true,
                rewardClaimedToday: creditProvider.status?.rewardClaimedToday ?? false,
                onWatchAd: _handleClaimReward,
              ),

            ChatInputBar(
              controller: _textController,
              onSend: _handleSend,
              isSending: chatProvider.isSending,
              enabled: true,
            ),

            // Hidden entirely while the keyboard is open — see class doc.
            if (!keyboardOpen)
              const Padding(
                padding: EdgeInsets.only(bottom: 6, top: 2),
                child: Center(child: ChatBannerAdWidget()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatProvider chatProvider) {
    if (chatProvider.isLoadingHistory) {
      return const LoadingView();
    }

    if (chatProvider.messages.isEmpty) {
      return _ChatWelcomeView(
        onPromptSelected: (text) {
          _textController.text = text;
          _handleSend();
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      itemCount: chatProvider.messages.length + (chatProvider.isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatProvider.messages.length) {
          return const TypingIndicatorBubble();
        }
        return ChatBubble(message: chatProvider.messages[index]);
      },
    );
  }
}

class _RewardPromptBanner extends StatelessWidget {
  final bool isClaiming;
  final bool rewardEligible;
  final bool rewardClaimedToday;
  final VoidCallback onWatchAd;

  const _RewardPromptBanner({
    required this.isClaiming,
    required this.rewardEligible,
    required this.rewardClaimedToday,
    required this.onWatchAd,
  });

  @override
  Widget build(BuildContext context) {
    if (rewardClaimedToday) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(14)),
        child: const Text(
          'You\'ve used all of today\'s questions, including the bonus round. More questions unlock tomorrow.',
          style: AppTextStyles.bodySecondary,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.play_circle_outline_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Today\'s free questions are used up',
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Watch a short ad to earn +20 credits and 2 more questions today.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Watch ad for bonus credits',
            icon: Icons.play_arrow_rounded,
            isLoading: isClaiming,
            onPressed: onWatchAd,
          ),
        ],
      ),
    );
  }
}

class _ChatWelcomeView extends StatelessWidget {
  final ValueChanged<String> onPromptSelected;

  const _ChatWelcomeView({required this.onPromptSelected});

  static const _prompts = [
    ('Career Guidance', 'What does my chart say about my career?'),
    ('Love Life', 'What does my chart say about my love life?'),
    ('Future Prediction', 'What can I expect in the near future?'),
    ('Health Insights', 'What does my chart say about my health?'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(gradient: AppColors.glyphGradient, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.onGold, size: 34),
          ),
          const SizedBox(height: 18),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: "I'm ", style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(text: 'Astromitra', style: TextStyle(color: AppColors.goldBright)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Your AI Astrologer', style: AppTextStyles.bodySecondary),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: const Text(
              "Namaste! \u{1F64F}\nI'm here to guide you with insights about your life, future, "
              'relationships, career, health and more.\n\n'
              "Ask me anything, and I'll help you with accurate astrological guidance.",
              style: AppTextStyles.bodySecondary,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              for (final prompt in _prompts)
                _PromptChip(label: prompt.$1, onTap: () => onPromptSelected(prompt.$2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
