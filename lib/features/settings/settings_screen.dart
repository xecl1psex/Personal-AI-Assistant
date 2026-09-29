import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';
import '../../shared/models/provider_config.dart';
import '../../shared/widgets/accent_color_picker.dart';
import 'settings_provider.dart';
import 'widgets/add_provider_dialog.dart';
import 'widgets/provider_tile.dart';

/// Settings screen.
///
/// Sections:
///  * 🤖 Модели ИИ — list of configured AI providers (add / activate / delete).
///  * 🎨 Оформление — accent color picker + dark mode toggle.
///  * 🎙️ Голосовой ввод — placeholder.
///  * 💾 Данные — placeholder.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const <Widget>[
          _SectionHeader(icon: Icons.smart_toy_outlined, title: '🤖 Модели ИИ'),
          _AiProvidersSection(),
          Divider(height: 24),
          _SectionHeader(icon: Icons.palette_outlined, title: '🎨 Оформление'),
          _AppearanceSection(),
          Divider(height: 24),
          _SectionHeader(icon: Icons.mic_none, title: '🎙️ Голосовой ввод'),
          _PlaceholderTile(
            title: 'Голосовой ввод',
            subtitle: 'Скоро: распознавание речи прямо на устройстве',
            icon: Icons.mic_off,
          ),
          Divider(height: 24),
          _SectionHeader(icon: Icons.storage_outlined, title: '💾 Данные'),
          _PlaceholderTile(
            title: 'Управление данными',
            subtitle: 'Скоро: экспорт, импорт и очистка локальной базы',
            icon: Icons.download_for_offline_outlined,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Section header
// -----------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🤖 AI providers
// -----------------------------------------------------------------------------

class _AiProvidersSection extends StatelessWidget {
  const _AiProvidersSection();

  Future<void> _confirmDelete(
    BuildContext context,
    ProviderConfig config,
  ) async {
    final SettingsProvider settings = context.read<SettingsProvider>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Удалить модель?'),
        content: Text(
          '«${config.displayName}» (${config.modelName}) будет удалена, '
          'а её API-ключ стёрт из защищённого хранилища.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await settings.removeProvider(config.id);
    }
  }

  Future<void> _openAddDialog(BuildContext context) async {
    await AddProviderDialog.show(context);
  }

  /// Bottom sheet with actions for one provider: activate / edit / delete.
  void _showProviderActions(
    BuildContext context,
    SettingsProvider settings,
    ProviderConfig config,
  ) {
    final bool isActive = config.id == settings.activeProviderId;
    final ThemeData theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${config.displayName} · ${config.modelName}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.play_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Сделать активным'),
                enabled: !isActive,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  settings.setActiveProvider(config.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AddProviderDialog.edit(context, config);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                title: Text(
                  'Удалить',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(context, config);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds automatically whenever providers / active id change.
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final List<ProviderConfig> providers = settings.providers;

    if (!settings.loaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (providers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Модели ещё не добавлены. Добавьте первую, чтобы начать '
              'общаться с ассистентом.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('+ Добавить модель'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final ProviderConfig config in providers)
          Dismissible(
            key: ValueKey<String>(config.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            confirmDismiss: (_) async {
              await _confirmDelete(context, config);
              return false; // removal is done inside the dialog itself
            },
            child: ProviderTile(
              config: config,
              isActive: config.id == settings.activeProviderId,
              onTap: () => _showProviderActions(context, settings, config),
              onLongPress: () => _confirmDelete(context, config),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: OutlinedButton.icon(
              onPressed: () => _openAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('+ Добавить модель'),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 🎨 Appearance
// -----------------------------------------------------------------------------

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Акцентный цвет',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AccentColorPicker(),
        ),
        SwitchListTile(
          value: themeProvider.isDarkMode,
          onChanged: (_) => themeProvider.toggleDarkMode(),
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          ),
          title: const Text('Тёмная тема'),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Generic placeholder tile
// -----------------------------------------------------------------------------

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Chip(
        label: const Text('Скоро'),
        visualDensity: VisualDensity.compact,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
