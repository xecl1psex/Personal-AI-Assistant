import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/models/chat_message.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_screen.dart';
import '../settings/system_prompt_provider.dart';
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
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Список чатов',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
      drawer: const _ChatsDrawer(),
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
              final String systemPrompt =
                  context.read<SystemPromptProvider>().prompt;
              chat.sendMessage(text, context.read<SettingsProvider>(), systemPrompt);
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Chats drawer (multi-conversation list)
// -----------------------------------------------------------------------------

class _ChatsDrawer extends StatelessWidget {
  const _ChatsDrawer();

  Future<void> _confirmDelete(BuildContext context, ChatProvider chat,
      Map<String, dynamic> row) async {
    final int id = row['id'] as int;
    final String title = (row['title'] as String?) ?? 'Новый чат';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Удалить чат?'),
        content: Text('Чат «$title» и все его сообщения будут удалены.'),
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
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await chat.deleteChat(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Чаты',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Новый чат'),
                  onPressed: () async {
                    await context.read<ChatProvider>().createNewChat();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (BuildContext context, ChatProvider chat, _) {
                  final List<Map<String, dynamic>> chats = chat.chats;
                  if (chats.isEmpty) {
                    return Center(
                      child: Text(
                        'Пока нет чатов',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> row = chats[index];
                      final int id = row['id'] as int;
                      final String title =
                          (row['title'] as String?) ?? 'Новый чат';
                      final int updatedAt =
                          (row['updated_at'] as int?) ??
                              (row['created_at'] as int?) ??
                              DateTime.now().millisecondsSinceEpoch;
                      final bool isActive = chat.currentChatId == id;

                      return ListTile(
                        selected: isActive,
                        selectedTileColor:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        iconColor:
                            isActive ? theme.colorScheme.primary : null,
                        leading: Icon(
                          isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? theme.colorScheme.primary : null,
                          ),
                        ),
                        subtitle: Text(
                          formatChatDate(updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String value) {
                            switch (value) {
                              case 'delete':
                                _confirmDelete(context, chat, row);
                                break;
                              case 'rename':
                                _renameChat(context, chat, row);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext ctx) =>
                              const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'rename',
                              child: Text('Переименовать'),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Удалить'),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await chat.switchToChat(id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Настройки'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _renameChat(BuildContext context, ChatProvider chat,
      Map<String, dynamic> row) async {
    final int id = row['id'] as int;
    final TextEditingController controller =
        TextEditingController(text: (row['title'] as String?) ?? '');
    final String? newTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Переименовать чат'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Название чата'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final String value = controller.text.trim();
              if (value.isNotEmpty) Navigator.of(ctx).pop(value);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle != null && newTitle.isNotEmpty) {
      // Rename via DB through provider's db is not exposed; use delete+recreate
      // pattern is overkill — instead update title directly through provider.
      await chat.renameChat(id, newTitle);
    }
  }
}
