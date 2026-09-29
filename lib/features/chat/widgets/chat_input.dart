import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Chat message input: multiline text field + send button.
///
/// * Enter sends the message, Shift+Enter inserts a newline (handled via a
///   [Shortcuts]-override around the field).
/// * The send button is disabled while [enabled] is false or the text is
///   empty; the field clears itself after a successful send.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    required this.enabled,
  });

  /// Called with the trimmed message text when the user submits.
  final void Function(String text) onSend;

  /// False while the assistant is replying (blocks sending).
  final bool enabled;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final bool has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool canSend = widget.enabled && _hasText;

    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Shortcuts(
                  // Enter = send, Shift+Enter = newline.
                  shortcuts: <LogicalKeySet, Intent>{
                    LogicalKeySet(LogicalKeyboardKey.enter):
                        const SendIntent(),
                    LogicalKeySet(LogicalKeyboardKey.numpadEnter):
                        const SendIntent(),
                  },
                  child: Actions(
                    actions: <Type, Action<Intent>>{
                      SendIntent: CallbackAction<SendIntent>(
                        onInvoke: (SendIntent intent) {
                          _send();
                          return null;
                        },
                      ),
                    },
                    child: TextField(
                      controller: _controller,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Напишите сообщение…',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend ? _send : null,
                icon: const Icon(Icons.send_rounded),
                tooltip: 'Отправить',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal intent used to map Enter to "send".
class SendIntent extends Intent {
  const SendIntent();
}
