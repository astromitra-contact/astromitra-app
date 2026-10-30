import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/chat_models.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/chat_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/kundli_provider.dart';
import '../widgets/chat_banner_ad_widget.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/credit_badge.dart';
import '../widgets/state_views.dart';

class AstroChatScreen extends StatefulWidget {
  const AstroChatScreen({super.key});

  @override
  State<AstroChatScreen> createState() => _AstroChatScreenState();
}

class _AstroChatScreenState extends State<AstroChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  ChatMessage? _selectedMessage;
  ChatMessage? _replyingToMessage;

  void _onMessageLongPress(ChatMessage msg) {
    setState(() => _selectedMessage = msg);
  }

  void _clearSelection() {
    setState(() => _selectedMessage = null);
  }

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

  Future<void> _handleSend({String? promptText}) async {
    final kundliId = context.read<KundliProvider>().activeKundliId;
    final creditProvider = context.read<CreditProvider>();
    final canAsk = creditProvider.status?.canAskNow ?? true;

    if (!canAsk) {
      _textController.clear();
      _inputFocusNode.unfocus();
      FocusScope.of(context).unfocus();
      _showOutOfCreditsDialog();
      return;
    }

    final rawQuestion = (promptText ?? _textController.text).trim();
    if (kundliId == null || rawQuestion.isEmpty) return;

    String question = rawQuestion;
    if (_replyingToMessage != null) {
      final replyingText = _replyingToMessage!.text.replaceAll('\n', ' ');
      final snippet = replyingText.length > 80 ? '${replyingText.substring(0, 80)}...' : replyingText;
      final who = _replyingToMessage!.role == ChatRole.user ? 'You' : 'AstroMitra';
      question = '> $who: $snippet\n$rawQuestion';
      setState(() {
        _replyingToMessage = null;
      });
    }

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
        _textController.clear();
      _inputFocusNode.unfocus();
      FocusScope.of(context).unfocus();
      _showOutOfCreditsDialog();
      } else if (chatProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chatProvider.errorMessage!)));
      }
    }
  }

  void _showOutOfCreditsDialog() {
    _textController.clear();
    _inputFocusNode.unfocus();
    FocusScope.of(context).unfocus();
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
                          'Watch 2 short video ads to earn +20 extra credits!',
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
                label: const Text('Watch 2 Ads (+20 Credits)', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleClaimReward() async {
    _textController.clear();
    _inputFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    final kundliId = context.read<KundliProvider>().activeKundliId;
    if (kundliId == null) return;

    final creditProvider = context.read<CreditProvider>();
    if (creditProvider.isClaimingReward) return;
    /*

    ScaffoldMessenger.of(context).hideCurrentSnackBar();



    ScaffoldMessenger.of(context).hideCurrentSnackBar();


        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),

          ],
        ),
        behavior: SnackBarBehavior.floating,

      ),
    );

    */
    final outcome = await creditProvider.claimDailyReward(kundliId);
    /*


        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (completed == 1) {
      
      
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),

                ],
              ),
              behavior: SnackBarBehavior.floating,

            ),
          );
        } else if (completed == 2) {
      
      
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),

                ],
              ),
              behavior: SnackBarBehavior.floating,

            ),
          );
        }
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();


    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    */
    if (!mounted) return;

    final message = switch (outcome) {
      RewardClaimOutcome.success => 'Success! +20 extra credits added to your account.',
      RewardClaimOutcome.adNotCompleted => creditProvider.completedAds == 1
          ? 'Completed 1 of 2 ads. Watch both full ads to earn +20 credits.'
          : 'Please watch both full ads to earn +20 bonus credits.',
      RewardClaimOutcome.alreadyClaimed => 'You\'ve already claimed today\'s bonus.',
      RewardClaimOutcome.notEligibleYet => 'The bonus unlocks after your daily credits are used up.',
      RewardClaimOutcome.error => creditProvider.errorMessage ?? 'Could not claim bonus right now.',
    };


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: outcome == RewardClaimOutcome.success ? AppColors.success : null,
      ),
    );

    _textController.clear();
    _inputFocusNode.unfocus();
    FocusScope.of(context).unfocus();

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
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kundliProvider = context.watch<KundliProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final creditProvider = context.watch<CreditProvider>();

    final kundliId = kundliProvider.activeKundliId;

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

    return PopScope(
      canPop: _selectedMessage == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedMessage != null) _clearSelection();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 1. AD FIRST: Positioned at the very top of the screen
              const ChatBannerAdWidget(),

              // 2. AFTER AD: The AppBar header row
              _selectedMessage != null
                  ? _buildSelectionHeader(context)
                  : _buildNormalHeader(context, creditProvider),

              Expanded(child: _buildMessageList(chatProvider)),


            if (_replyingToMessage != null)
              _ReplyPreviewBanner(
                message: _replyingToMessage!,
                onCancel: () => setState(() => _replyingToMessage = null),
              ),

            ChatInputBar(
              controller: _textController,
              focusNode: _inputFocusNode,
              onSend: _handleSend,
              isSending: chatProvider.isSending,
              enabled: true,
            ),
          ],
        ),
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

          _handleSend(promptText: text);
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
        final msg = chatProvider.messages[index];
        final isSelected = _selectedMessage == msg;
        return ChatBubble(
          message: msg,
          isSelected: isSelected,
          onLongPress: () => _onMessageLongPress(msg),
          onTap: () {
            if (_selectedMessage == null) {
              _onMessageLongPress(msg);
            } else if (isSelected) {
              _clearSelection();
            } else {
              _onMessageLongPress(msg);
            }
          },
        );
      },
    );
  }

  Widget _buildNormalHeader(BuildContext context, CreditProvider creditProvider) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/astro-icon.png', width: 36, height: 36, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AstroMitra',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Online', style: TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
          ),
          Center(
            child: CreditBadge(
              status: creditProvider.status,
              isLoading: creditProvider.isLoading,
              onTap: _showOutOfCreditsDialog,
            ),
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
    );
  }

  Widget _buildSelectionHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            tooltip: 'Cancel',
            onPressed: _clearSelection,
          ),
          const SizedBox(width: 8),
          const Text('1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          IconButton(
            tooltip: 'Reply',
            icon: const Icon(Icons.reply_rounded, color: AppColors.textPrimary),
            onPressed: () {
              final msg = _selectedMessage!;
              setState(() {
                _replyingToMessage = msg;
              });
              _clearSelection();
              _inputFocusNode.requestFocus();
            },
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _selectedMessage!.text));
              _clearSelection();
          
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('Copied to clipboard'),
                    ],
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
          
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            onPressed: () {
              final msg = _selectedMessage!;
              _clearSelection();
              context.read<ChatProvider>().deleteMessage(msg);
          
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 16),
                      SizedBox(width: 8),
                      Text('Message deleted'),
                    ],
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
          
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/astro-icon.png', width: 90, height: 90, fit: BoxFit.contain),
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

/// Compact live countdown to midnight — used inside the out-of-credits dialog.
class _MidnightCountdown extends StatefulWidget {
  @override
  State<_MidnightCountdown> createState() => _MidnightCountdownState();
}

class _MidnightCountdownState extends State<_MidnightCountdown> {
  late Timer _timer;
  late Duration _remaining;

  Duration _calc() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1).difference(now);
  }

  @override
  void initState() {
    super.initState();
    _remaining = _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = _calc());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$h:$m:$s',
      style: const TextStyle(
        color: AppColors.goldBright,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ReplyPreviewBanner extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onCancel;

  const _ReplyPreviewBanner({
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final senderName = isUser ? 'You' : 'AstroMitra';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        border: Border(
          top: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.35)),
          left: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.35)),
          right: BorderSide(color: AppColors.borderGold.withValues(alpha: 0.35)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    color: AppColors.goldBright,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.text.replaceAll('\n', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Cancel reply',
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
