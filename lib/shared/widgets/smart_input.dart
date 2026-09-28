import 'package:flutter/material.dart';

/// Smart natural-language input bar used by Chat / Finance / Tasks screens.
///
/// * [TextField] for free-form text ("потратил 500 на кофе вчера");
/// * microphone button — placeholder for voice input
///   (real speech-to-text will be added later, no external deps yet);
/// * send button — fires [onSubmit] with the trimmed text.
class SmartInput extends StatefulWidget {
  const SmartInput({
    super.key,
    this.onSubmit,
    this.onMicTap,
    this.hintText = 'Напиши или скажи...',
    this.autofocus = false,
    this.enabled = true,
  });

  /// Called with non-empty trimmed text when the user submits.
  final ValueChanged<String>? onSubmit;

  /// Called when the mic button is tapped. If null, a snackbar stub is shown.
  final VoidCallback? onMicTap;

  final String hintText;
  final bool autofocus;

  /// Disables the whole bar (e.g. while the AI is answering).
  final bool enabled;

  @override
  State<SmartInput> createState() => _SmartInputState();
}

class _SmartInputState extends State<SmartInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text);
    _controller.clear();
    _focusNode.unfocus();
  }

  void _onMicTap() {
    if (widget.onMicTap != null) {
      widget.onMicTap!.call();
      return;
    }

    // TODO: реализация — подключить speech_to_text / record.
    setState(() => _isListening = !_isListening);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isListening
              ? 'Слушаю… (распознавание речи появится позже)'
              : 'Запись остановлена',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom > 0 ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withAlpha(60))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          // ------------------------------------------------------------------
          // Text field
          // ------------------------------------------------------------------
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: widget.hintText,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------------------
          // Microphone
          // ------------------------------------------------------------------
          IconButton(
            onPressed: widget.enabled ? _onMicTap : null,
            tooltip: _isListening ? 'Остановить запись' : 'Голосовой ввод',
            style: IconButton.styleFrom(
              backgroundColor:
                  _isListening ? scheme.primaryContainer : Colors.transparent,
              foregroundColor: _isListening
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),

          const SizedBox(width: 4),

          // ------------------------------------------------------------------
          // Send
          // ------------------------------------------------------------------
          IconButton(
            onPressed: widget.enabled ? _submit : null,
            tooltip: 'Отправить',
            style: IconButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
