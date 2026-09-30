import 'package:flutter/material.dart';

import '../../../services/ai/provider_families.dart';
import '../../../shared/models/provider_config.dart';

/// A single AI provider row inside the Settings list.
///
/// Shows the family icon (resolved via [ProviderFamilies.findById] from
/// [ProviderConfig.familyId]), bold [ProviderConfig.displayName], small gray
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

  /// Tap callback — usually opens the provider actions bottom sheet.
  final VoidCallback? onTap;

  /// Long-press callback — usually opens the delete confirmation.
  final VoidCallback? onLongPress;

  /// Resolve the family for a config (falls back to legacy presetId).
  static ProviderFamily? familyOf(ProviderConfig config) {
    final String id =
        config.familyId.isNotEmpty ? config.familyId : config.presetId;
    return ProviderFamilies.findById(id);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ProviderFamily? family = familyOf(config);
    final bool requiresKey = family?.requiresApiKey ?? true;

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
          family?.icon ?? '🤖',
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
          if (!requiresKey) ...<Widget>[
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
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
