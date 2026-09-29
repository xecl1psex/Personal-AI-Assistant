import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/models/chat_message.dart';
import '../settings/settings_provider.dart';
import 'chat_provider.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';
import 'widgets/thinking_indicator.dart';

/// AI chat screen: conversation with the active model.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static const String routeName = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load / create the current chat after the first frame so that all
    // providers are available in the widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().init();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text(
          'Все сообщения текущего чата будут удалены безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ChatProvider>().clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<SettingsProvider>(
          builder: (BuildContext context, SettingsProvider settings, _) {
            return Text(settings.activeProvider?.displayName ?? 'Чат');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Очистить историю',
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (BuildContext context, ChatProvider chat, _) {
          final List<ChatMessage> messages = chat.messages;

          // Auto-scroll when new content appears.
          _scrollToBottom();

          return Column(
            children: [
              if (chat.errorMessage != null)
                MaterialBanner(
                  backgroundColor:
                      Theme.of(context).colorScheme.errorContainer,
                  content: Text(
                    chat.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: chat.dismissError,
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              Expanded(
                child: messages.isEmpty && !chat.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Привет! Чем помочь?',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: false,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length + (chat.isLoading ? 1 : 0),
                        itemBuilder: (BuildContext context, int index) {
                          if (index >= messages.length) {
                            return const ThinkingIndicator();
                          }
                          return MessageBubble(message: messages[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (BuildContext context, ChatProvider chat, _) {
          return ChatInput(
            enabled: !chat.isLoading,
            onSend: (String text) {
              chat.sendMessage(text, context.read<SettingsProvider>());
            },
          );
        },
      ),
    );
  }
}
