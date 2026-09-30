import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/ai/provider_families.dart';
import '../../shared/models/provider_config.dart';
import '../../shared/widgets/accent_color_picker.dart';
import 'settings_provider.dart';
import 'system_prompt_provider.dart';
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
          _SectionHeader(
              icon: Icons.psychology_outlined, title: '🧠 Системный промпт'),
          _SystemPromptSection(),
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

  /// Bottom sheet with actions for one provider: activate / switch model /
  /// edit / delete.
  void _showProviderActions(
    BuildContext context,
    SettingsProvider settings,
    ProviderConfig config,
  ) {
    final bool isActive = config.id == settings.activeProviderId;
    final ThemeData theme = Theme.of(context);
    // Family models (resolved via familyId, legacy fallback to presetId).
    final String familyId =
        config.familyId.isNotEmpty ? config.familyId : config.presetId;
    final ProviderFamily? family = ProviderFamilies.findById(familyId);

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
              if (family != null && family.models.length > 1)
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Сменить модель'),
                  subtitle: Text(family.name),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showModelPicker(context, settings, config, family);
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
                leading: Icon(Icons.delete_outline,
                    color: theme.colorScheme.error),
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

  /// Model switcher inside the provider's family — changes only modelName.
  void _showModelPicker(
    BuildContext context,
    SettingsProvider settings,
    ProviderConfig config,
    ProviderFamily family,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${family.icon} ${family.name} — выбор модели',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final ModelOption model in family.models)
                      RadioListTile<String>(
                        value: model.id,
                        groupValue: config.modelName,
                        onChanged: (String? value) {
                          Navigator.of(sheetContext).pop();
                          if (value != null) {
                            settings.updateModel(config.id, value);
                          }
                        },
                        title: Row(
                          children: <Widget>[
                            Flexible(child: Text(model.name)),
                            if (model.recommended) ...<Widget>[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'рекомендуем',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: model.description == null
                            ? null
                            : Text(
                                model.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
// System prompt section
// -----------------------------------------------------------------------------

class _SystemPromptSection extends StatelessWidget {
  const _SystemPromptSection();

  Future<void> _showEditDialog(BuildContext context) async {
    final SystemPromptProvider provider =
        context.read<SystemPromptProvider>();
    final TextEditingController controller =
        TextEditingController(text: provider.prompt);

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Системный промпт'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            maxLines: 10,
            minLines: 5,
            decoration: const InputDecoration(
              hintText: 'Опиши, как ассистент должен себя вести',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.reset();
              Navigator.of(ctx).pop();
            },
            child: const Text('Сбросить'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              provider.setPrompt(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Consumer<SystemPromptProvider>(
      builder: (BuildContext context, SystemPromptProvider sp, _) {
        final bool isDefault = sp.prompt == SystemPromptProvider.defaultPrompt;
        final String subtitle = isDefault
            ? 'По умолчанию'
            : (sp.prompt.length <= 60
                ? sp.prompt
                : '${sp.prompt.substring(0, 60)}…');
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(Icons.psychology_outlined,
              color: theme.colorScheme.primary),
          title: const Text('Системный промпт'),
          subtitle: Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _showEditDialog(context),
        );
      },
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
