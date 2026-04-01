import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../providers/chat_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/user_provider.dart';

class AiStylistChatScreen extends StatefulWidget {
  const AiStylistChatScreen({super.key});

  @override
  State<AiStylistChatScreen> createState() => _AiStylistChatScreenState();
}

class _AiStylistChatScreenState extends State<AiStylistChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load chat history on screen open
    final userId = context.read<UserProvider>().userId;
    context.read<ChatProvider>().loadHistory(userId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final userId = context.read<UserProvider>().userId;
    final rec = context.read<RecommendationProvider>().recommendation;
    Map<String, dynamic>? chatContext;
    if (rec != null && rec.outfits.isNotEmpty) {
      final top = rec.outfits.first;
      chatContext = {
        'occasion': rec.occasion,
        'mood': rec.mood,
        'explanation': top.explanation,
        'scores': top.scores,
        'items': top.items
            .map((i) => {
                  'id': i.id,
                  'name': i.name,
                  'category': i.category,
                  'color': i.color,
                  'formality': i.formality,
                })
            .toList(),
      };
    }
    await context
        .read<ChatProvider>()
        .sendMessage(userId, text.trim(), context: chatContext);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;
    final loading = chatProvider.loading;
    final suggestions = chatProvider.suggestions;

    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(title: const Text('Your AI Stylist')),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: messages.isEmpty
                  ? _emptyState(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.screenPadding,
                      itemCount: messages.length + (loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && loading) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text('Stylist is thinking…',
                                    style: AppTypography.body(context)),
                              ],
                            ),
                          );
                        }
                        final msg = messages[index];
                        return _MessageBubble(
                          text: msg.message,
                          isAi: msg.role == 'assistant',
                        );
                      },
                    ),
            ),

            // Suggestion chips
            if (suggestions.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: suggestions
                      .map((s) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.xs),
                            child: ActionChip(
                              label:
                                  Text(s, style: const TextStyle(fontSize: 13)),
                              onPressed: () => _send(s),
                              backgroundColor: AppColors.bgSecondary,
                            ),
                          ))
                      .toList(),
                ),
              ),

            // Input bar
            Container(
              color: AppColors.bgSecondary,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask anything about your outfit…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentLavender.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 32, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Your AI Stylist', style: AppTypography.subheading(context)),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Ask me about your outfit, request changes, or get style advice.',
              style: AppTypography.body(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isAi;

  const _MessageBubble({required this.text, required this.isAi});

  @override
  Widget build(BuildContext context) {
    final bg = isAi
        ? AppColors.bgSecondary
        : AppColors.accentLavender.withOpacity(0.35);
    final align = isAi ? Alignment.centerLeft : Alignment.centerRight;
    final radius = BorderRadius.circular(18);
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
        ),
        child: Text(text, style: AppTypography.body(context)),
      ),
    );
  }
}
