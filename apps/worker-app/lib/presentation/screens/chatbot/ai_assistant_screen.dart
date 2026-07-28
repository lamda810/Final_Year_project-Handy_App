import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../injection_container.dart';
import '../../blocs/chatbot/chatbot_bloc.dart';
import '../../blocs/chatbot/chatbot_event.dart';
import '../../blocs/chatbot/chatbot_state.dart';

/// AI assistant for workers — answers questions about jobs, earnings,
/// documents, and how to use the app. Scoped server-side to Handy-Go topics.
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  static const List<String> _quickPrompts = [
    'How do I start a job?',
    'How do withdrawals work?',
    'Why is my document rejected?',
    'How is trust score calculated?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatbotBloc>(
      create: (_) => sl<ChatbotBloc>(),
      // Builder gives us a context below BlocProvider, so the Scaffold
      // (including its AppBar) can look up ChatbotBloc via context.read.
      // Passing the outer build(context) straight into Scaffold would put
      // the AppBar's context above the provider, where the bloc isn't
      // registered yet — that's what threw the "Could not find the
      // correct Provider<ChatbotBloc>" error from the refresh button.
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              Expanded(
                child: BlocConsumer<ChatbotBloc, ChatbotState>(
                  listener: (context, state) {
                    if (state is ChatbotResponseReceived || state is ChatbotLoading) {
                      _scrollToBottom();
                    }
                  },
                  builder: (context, state) {
                    if (state is ChatbotInitial) {
                      return _buildEmptyState(context);
                    }

                    List<Map<String, dynamic>> messages = [];
                    if (state is ChatbotResponseReceived) {
                      messages = state.messages;
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: messages.length + (state is ChatbotLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return _buildTypingIndicator(context);
                        }
                        return _buildMessageBubble(context, messages[index]);
                      },
                    );
                  },
                ),
              ),
              _buildQuickPrompts(context),
              _buildInputArea(context),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Handy Assistant',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                'AI-powered • Worker support',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Start a new conversation',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            context.read<ChatbotBloc>().add(const ResetChatbot());
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ask about accepting jobs, the start/complete OTP flow, '
              'earnings, withdrawals, or your documents.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: _quickPrompts.map((prompt) {
                return _PromptChip(label: prompt, onTap: () => _sendText(context, prompt));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts(BuildContext context) {
    return BlocBuilder<ChatbotBloc, ChatbotState>(
      builder: (context, state) {
        if (state is! ChatbotResponseReceived || state.messages.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.only(left: AppSpacing.md, top: AppSpacing.sm),
            scrollDirection: Axis.horizontal,
            children: _quickPrompts.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _PromptChip(label: prompt, onTap: () => _sendText(context, prompt)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> msg) {
    final isUser = msg['isUser'] as bool;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser ? null : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusLG),
                  topRight: const Radius.circular(AppSpacing.radiusLG),
                  bottomLeft: Radius.circular(isUser ? AppSpacing.radiusLG : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppSpacing.radiusLG),
                ),
              ),
              child: Text(
                msg['text'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.sm + 28),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLG),
                topRight: Radius.circular(AppSpacing.radiusLG),
                bottomRight: Radius.circular(AppSpacing.radiusLG),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ask about jobs, earnings, documents...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            BlocBuilder<ChatbotBloc, ChatbotState>(
              builder: (context, state) {
                final isLoading = state is ChatbotLoading;
                return Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: isLoading ? null : () => _sendMessage(context),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendText(BuildContext context, String text) {
    _messageController.text = text;
    _sendMessage(context);
  }

  // Takes context explicitly rather than using the State's own `context`
  // (the outer build(context), above the screen-local BlocProvider) —
  // every call site below passes the context from inside Builder/
  // BlocBuilder, which is where ChatbotBloc is actually registered.
  void _sendMessage(BuildContext context) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatbotBloc>().add(SendChatMessage(message: text));
    _messageController.clear();
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = (_controller.value - (i * 0.2)) % 1.0;
              final scale = t < 0.5 ? (0.6 + t) : (1.6 - t);
              return Opacity(
                opacity: scale.clamp(0.3, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
