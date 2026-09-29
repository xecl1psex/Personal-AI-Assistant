import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/ai/ai_service.dart';
import '../../../services/ai/model_presets.dart';
import '../../../shared/models/provider_config.dart';
import '../settings_provider.dart';

/// Two-step dialog for adding an AI provider, or single-step form for
/// editing an existing one.
///
/// Add mode — Step 1: pick a [ModelPreset] from [ModelPresets.allPresets].
/// Step 2: fill in display name / model name / API key, optionally run a
/// connectivity test via [AiService.testConnection], then add the provider
/// through [SettingsProvider.addProvider].
///
/// Edit mode — pass [existing] to pre-fill all fields (baseUrl is editable).
/// The stored API key is loaded from secure storage and pre-filled in the
/// (obscured) key field; on save, the key is only sent to
/// [SettingsProvider.updateProvider] when the user actually changed it.
class AddProviderDialog extends StatefulWidget {
  const AddProviderDialog({super.key, this.existing});

  /// Non-null when the dialog edits an already-saved provider.
  final ProviderConfig? existing;

  bool get isEdit => existing != null;

  /// Convenience static opener (add mode). Returns true if saved.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const AddProviderDialog(),
    );
  }

  /// Convenience static opener (edit mode). Returns true if saved.
  static Future<bool?> edit(BuildContext context, ProviderConfig config) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AddProviderDialog(existing: config),
    );
  }

  @override
  State<AddProviderDialog> createState() => _AddProviderDialogState();
}

enum _DialogStep { pickPreset, configure }

enum _TestState { idle, testing, success, failure }

class _AddProviderDialogState extends State<AddProviderDialog> {
  final AiService _aiService = const AiService();

  late _DialogStep _step;
  ModelPreset? _selectedPreset;
  String _baseUrl = '';

  late final TextEditingController _nameController;
  late final TextEditingController _modelController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _keyController;

  bool _obscureKey = true;
  _TestState _testState = _TestState.idle;
  String? _testError;
  bool _saving = false;

  /// The API key as loaded from secure storage when editing an existing
  /// provider. Used to detect whether the user actually modified the field:
  /// if the current text equals this value, no new key is written on save.
  String _originalKey = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _modelController = TextEditingController();
    _baseUrlController = TextEditingController();
    _keyController = TextEditingController();

    final ProviderConfig? existing = widget.existing;
    if (existing != null) {
      // Edit mode: jump straight to the form, pre-filled from the config.
      _step = _DialogStep.configure;
      _selectedPreset = ModelPresets.findById(existing.presetId);
      _baseUrl = existing.baseUrl;
      _baseUrlController.text = existing.baseUrl;
      _nameController.text = existing.displayName;
      _modelController.text = existing.modelName;
      _loadExistingApiKey(existing.id);
    } else {
      _step = _DialogStep.pickPreset;
    }
  }

  /// Load the currently stored API key for [providerId] and pre-fill the
  /// obscured key field so the user can see (and edit) the existing value.
  Future<void> _loadExistingApiKey(String providerId) async {
    try {
      final SettingsProvider settings = context.read<SettingsProvider>();
      final String? key = await settings.getApiKey(providerId);
      if (!mounted) return;
      setState(() {
        _originalKey = key ?? '';
        _keyController.text = _originalKey;
      });
    } catch (_) {
      // Storage failure — leave the field empty; saving with an unchanged
      // (empty) field will not overwrite the stored key anyway.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _baseUrlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  bool get _isLocal =>
      _selectedPreset?.isLocal ??
      (_baseUrl.isNotEmpty &&
          (_baseUrl.contains('localhost') ||
              _baseUrl.contains('127.0.0.1') ||
              _baseUrl.contains('10.0.2.2')));

  bool get _isEdit => widget.isEdit;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _selectPreset(ModelPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _step = _DialogStep.configure;
      _testState = _TestState.idle;
      _testError = null;
      _baseUrl = preset.baseUrl;
      _baseUrlController.text = preset.baseUrl;
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

  String get _trimmedBaseUrl => _baseUrlController.text.trim();

  /// Builds a config from the current form values. In edit mode the original
  /// id/presetId are preserved.
  ProviderConfig _buildConfig() {
    if (_isEdit) {
      return widget.existing!.copyWith(
        displayName: _nameController.text.trim().isEmpty
            ? widget.existing!.displayName
            : _nameController.text.trim(),
        baseUrl: _trimmedBaseUrl.isEmpty ? widget.existing!.baseUrl : _trimmedBaseUrl,
        modelName: _modelController.text.trim().isEmpty
            ? widget.existing!.modelName
            : _modelController.text.trim(),
      );
    }
    final ModelPreset preset = _selectedPreset!;
    return ProviderConfig(
      id: 'provider_${DateTime.now().millisecondsSinceEpoch}',
      presetId: preset.id,
      displayName: _nameController.text.trim().isEmpty
          ? preset.name
          : _nameController.text.trim(),
      baseUrl: _trimmedBaseUrl.isEmpty ? preset.baseUrl : _trimmedBaseUrl,
      modelName: _modelController.text.trim().isEmpty
          ? preset.defaultModel
          : _modelController.text.trim(),
      supportsVision: preset.supportsVision,
      supportsFunctions: preset.supportsFunctions,
    );
  }

  String get _apiKey => _keyController.text.trim();

  /// In edit mode: true when the user actually changed the pre-filled key.
  /// When false, [SettingsProvider.updateProvider] is called with
  /// `newApiKey: null` so the stored key is never rewritten/overwritten.
  bool get _keyChanged => _apiKey.isNotEmpty && _apiKey != _originalKey;

  bool get _canSubmit {
    if (_saving) return false;
    if (_modelController.text.trim().isEmpty) return false;
    if (_trimmedBaseUrl.isEmpty) return false;
    // Add mode: remote providers require a key. Edit mode: the key field is
    // pre-filled from storage, and leaving it unchanged keeps the old key.
    if (!_isEdit && !_isLocal && _apiKey.isEmpty) return false;
    return true;
  }

  Future<void> _testConnection() async {
    if (!_isEdit && _selectedPreset == null) return;
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
    final String keyForTest = _apiKey.isEmpty ? 'ollama' : _apiKey;
    try {
      await _aiService.testConnection(config, keyForTest);
      if (!mounted) return;
      setState(() {
        _testState = _TestState.success;
        _testError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testState = _TestState.failure;
        _testError = _truncate(e.toString());
      });
    }
  }

  static String _truncate(String text, {int maxLength = 500}) {
    final String trimmed = text.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}…';
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);

    final SettingsProvider settings = context.read<SettingsProvider>();
    final ProviderConfig config = _buildConfig();

    if (_isEdit) {
      // Only send a new key when the user actually changed it compared to
      // the value loaded from secure storage — otherwise pass null so the
      // stored key is preserved untouched.
      await settings.updateProvider(
        config,
        newApiKey: _keyChanged ? _apiKey : null,
      );
    } else {
      // For local presets (Ollama) the key may be empty — addProvider still
      // awaits the secure-storage write before persisting the list.
      await settings.addProvider(config, _apiKey);
    }

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
        _isEdit
            ? 'Редактировать модель'
            : _step == _DialogStep.pickPreset
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
        if (_step == _DialogStep.configure && !_isEdit)
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
                : Text(_isEdit ? 'Сохранить' : 'Добавить'),
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
    final ModelPreset? preset = _selectedPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(_presetEmoji(preset?.id ?? widget.existing?.presetId ?? ''),
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _baseUrl,
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
          controller: _baseUrlController,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Base URL',
            border: const OutlineInputBorder(),
            isDense: true,
            helperText: _isEdit
                ? 'Например, https://api.openai.com/v1 или http://10.0.2.2:11434/v1'
                : null,
          ),
          onChanged: (String value) => setState(() => _baseUrl = value.trim()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keyController,
          obscureText: _obscureKey,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: _isLocal
                ? 'API-ключ (не обязателен)'
                : (_isEdit ? 'API-ключ' : 'API-ключ'),
            hintText: _isEdit ? 'Не меняйте, если ключ тот же' : null,
            helperText: _isEdit
                ? 'Ключ загружен из защищённого хранилища. '
                    'Измените только при необходимости — '
                    'без изменений старый ключ сохранится.'
                : null,
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
                '✅ Подключение работает',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      case _TestState.failure:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.error_outline,
                size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _testError ?? 'Ошибка подключения',
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
    }
  }
}
