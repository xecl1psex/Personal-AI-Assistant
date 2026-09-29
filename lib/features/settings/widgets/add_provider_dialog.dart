import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/ai/ai_service.dart';
import '../../../services/ai/model_presets.dart';
import '../../../shared/models/provider_config.dart';
import '../settings_provider.dart';

/// Two-step dialog for adding an AI provider.
///
/// Step 1 — pick a [ModelPreset] from [ModelPresets.allPresets].
/// Step 2 — fill in display name / model name / API key, optionally run a
/// connectivity test via [AiService.testConnection], then add the provider
/// through [SettingsProvider.addProvider].
class AddProviderDialog extends StatefulWidget {
  const AddProviderDialog({super.key});

  /// Convenience static opener. Returns true if a provider was added.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const AddProviderDialog(),
    );
  }

  @override
  State<AddProviderDialog> createState() => _AddProviderDialogState();
}

enum _DialogStep { pickPreset, configure }

enum _TestState { idle, testing, success, failure }

class _AddProviderDialogState extends State<AddProviderDialog> {
  final AiService _aiService = const AiService();

  _DialogStep _step = _DialogStep.pickPreset;
  ModelPreset? _selectedPreset;

  late final TextEditingController _nameController;
  late final TextEditingController _modelController;
  late final TextEditingController _keyController;

  bool _obscureKey = true;
  _TestState _testState = _TestState.idle;
  String? _testError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _modelController = TextEditingController();
    _keyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  bool get _isLocal => _selectedPreset?.isLocal ?? false;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _selectPreset(ModelPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _step = _DialogStep.configure;
      _testState = _TestState.idle;
      _testError = null;
      _nameController.text = preset.name;
      _modelController.text = preset.defaultModel;
    });
  }

  void _backToPresets() {
    setState(() {
      _step = _DialogStep.pickPreset;
      _selectedPreset = null;
      _testState = _TestState.idle;
      _testError = null;
    });
  }

  /// Builds a temporary config from the current form values.
  ProviderConfig _buildConfig() {
    final ModelPreset preset = _selectedPreset!;
    return ProviderConfig(
      id: 'provider_${DateTime.now().millisecondsSinceEpoch}',
      presetId: preset.id,
      displayName: _nameController.text.trim().isEmpty
          ? preset.name
          : _nameController.text.trim(),
      baseUrl: preset.baseUrl,
      modelName: _modelController.text.trim().isEmpty
          ? preset.defaultModel
          : _modelController.text.trim(),
      supportsVision: preset.supportsVision,
      supportsFunctions: preset.supportsFunctions,
    );
  }

  String get _apiKey => _keyController.text.trim();

  bool get _canSubmit {
    if (_saving) return false;
    if (_modelController.text.trim().isEmpty) return false;
    if (!_isLocal && _apiKey.isEmpty) return false;
    return true;
  }

  Future<void> _testConnection() async {
    if (_selectedPreset == null) return;
    if (!_isLocal && _apiKey.isEmpty) {
      setState(() {
        _testState = _TestState.failure;
        _testError = 'Введите API-ключ';
      });
      return;
    }

    setState(() {
      _testState = _TestState.testing;
      _testError = null;
    });

    final ProviderConfig config = _buildConfig();
    // Local endpoints (Ollama) don't need a real key — send a placeholder.
    final bool ok =
        await _aiService.testConnection(config, _isLocal ? 'ollama' : _apiKey);

    if (!mounted) return;
    setState(() {
      _testState = ok ? _TestState.success : _TestState.failure;
      _testError = ok ? null : 'Не удалось подключиться. Проверьте ключ, URL и модель.';
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit || _selectedPreset == null) return;
    setState(() => _saving = true);

    final SettingsProvider settings = context.read<SettingsProvider>();
    final ProviderConfig config = _buildConfig();
    // For local presets (Ollama) the key may be empty — it is still stored
    // so that getApiKey() returns a consistent value.
    await settings.addProvider(config, _apiKey);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _step == _DialogStep.pickPreset
            ? 'Добавить модель ИИ'
            : 'Настройка провайдера',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _step == _DialogStep.pickPreset
            ? _buildPresetList()
            : SingleChildScrollView(child: _buildForm()),
      ),
      actions: <Widget>[
        if (_step == _DialogStep.configure)
          TextButton(
            onPressed: _saving ? null : _backToPresets,
            child: const Text('Назад'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        if (_step == _DialogStep.configure)
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Добавить'),
          ),
      ],
    );
  }

  Widget _buildPresetList() {
    return SizedBox(
      width: 340,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: ModelPresets.allPresets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final ModelPreset preset = ModelPresets.allPresets[index];
          return ListTile(
            dense: true,
            leading: Text(
              _presetEmoji(preset.id),
              style: const TextStyle(fontSize: 22),
            ),
            title: Text(preset.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(preset.baseUrl),
                Text('Модель по умолчанию: ${preset.defaultModel}'),
              ],
            ),
            onTap: () => _selectPreset(preset),
          );
        },
      ),
    );
  }

  static String _presetEmoji(String presetId) {
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

  Widget _buildForm() {
    final ThemeData theme = Theme.of(context);
    final ModelPreset preset = _selectedPreset!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(_presetEmoji(preset.id),
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                preset.baseUrl,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Отображаемое имя',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          decoration: const InputDecoration(
            labelText: 'Название модели',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keyController,
          obscureText: _obscureKey,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: _isLocal ? 'API-ключ (не обязателен)' : 'API-ключ',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureKey ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_isLocal) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Локальный Ollama: ключ не требуется, но в Android-эмуляторе '
                  'адрес localhost указывает на сам эмулятор. Используйте IP '
                  'хост-машины (например, 10.0.2.2:11434).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            OutlinedButton.icon(
              onPressed:
                  _testState == _TestState.testing ? null : _testConnection,
              icon: _testState == _TestState.testing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check, size: 18),
              label: const Text('Проверить подключение'),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildTestStatus(theme)),
          ],
        ),
      ],
    );
  }

  Widget _buildTestStatus(ThemeData theme) {
    switch (_testState) {
      case _TestState.idle:
        return const SizedBox.shrink();
      case _TestState.testing:
        return Text(
          'Проверяю…',
          style: theme.textTheme.bodySmall,
        );
      case _TestState.success:
        return Row(
          children: <Widget>[
            Icon(Icons.check_circle,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Подключение успешно',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      case _TestState.failure:
        return Row(
          children: <Widget>[
            Icon(Icons.error_outline,
                size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _testError ?? 'Ошибка подключения',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
    }
  }
}
