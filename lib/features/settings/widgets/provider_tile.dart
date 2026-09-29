import 'package:flutter/material.dart';

import '../../../services/ai/model_presets.dart';
import '../../../shared/models/provider_config.dart';

/// A single AI provider row inside the Settings list.
///
/// Shows a preset emoji/icon, bold [ProviderConfig.displayName], small gray
/// [ProviderConfig.modelName] and a check-mark when this provider is active.
class ProviderTile extends StatelessWidget {
  const ProviderTile({
    super.key,
    required this.config,
    required this.isActive,
    this.onTap,
    this.onLongPress,
  });

  final ProviderConfig config;

  /// Whether this is the currently active provider (check-mark + tint).
  final bool isActive;

  /// Tap callback — usually switches the active provider.
  final VoidCallback? onTap;

  /// Long-press callback — usually opens the delete confirmation.
  final VoidCallback? onLongPress;

  /// Emoji badge for each known preset (fallback: robot face).
  static String presetEmoji(String presetId) {
    switch (presetId) {
      case 'gemini':
        return '✨';
      case 'openai':
        return '🧠';
      case 'claude':
        return '🟠';
      case 'deepseek':
        return '🐋';
      case 'groq':
        return '⚡';
      case 'openrouter':
        return '🌐';
      case 'ollama':
        return '🦙';
      default:
        return '🤖';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ModelPreset? preset = ModelPresets.findById(config.presetId);
    final bool needsKey = preset == null || preset.needsApiKey;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        radius: 22,
        child: Text(
          presetEmoji(config.presetId),
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              config.displayName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!needsKey) ...<Widget>[
            const SizedBox(width: 6),
            Tooltip(
              message: 'Локальный провайдер',
              child: Icon(
                Icons.wifi_off,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        config.modelName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isActive
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Icon(
              Icons.radio_button_unchecked,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(90),
            ),
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withAlpha(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
