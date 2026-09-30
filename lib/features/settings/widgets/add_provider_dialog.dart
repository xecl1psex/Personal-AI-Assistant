import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/ai/ai_service.dart';
import '../../../services/ai/provider_families.dart';
import '../../../shared/models/provider_config.dart';
import '../settings_provider.dart';

/// Two-step dialog for adding an AI provider "family" (one family = one API
/// key + a list of models), or editing an already-added one.
///
/// Add mode — Step 1: pick a [ProviderFamily] from [ProviderFamilies.all].
/// Step 2: enter the API key (if the family requires it), pick a model from
/// the family's [ModelOption] list (recommended model pre-selected), run an
/// optional connectivity test, then save via [SettingsProvider.addProvider].
///
/// Edit mode — pass [existing]: the form opens at step 2 with all fields
/// pre-filled; the stored API key is loaded from secure storage and shown in
/// the obscured field. On save the key is only rewritten when the user
/// actually changed it.
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

enum _DialogStep { pickFamily, configure }

enum _TestState { idle, testing, success, failure }

class _AddProviderDialogState extends State<AddProviderDialog> {
  final AiService _aiService = const AiService();

  late _DialogStep _step;
  ProviderFamily? _selectedFamily;

  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _keyController;
  late final TextEditingController _customModelController;

  String _selectedModelId = '';

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
    _baseUrlController = TextEditingController();
    _keyController = TextEditingController();

    final ProviderConfig? existing = widget.existing;
    if (existing != null) {
      // Edit mode: jump straight to the form, pre-filled from the config.
      _step = _DialogStep.configure;
      _selectedFamily = ProviderFamilies.findById(
        existing.familyId.isNotEmpty ? existing.familyId : existing.presetId,
      );
      _baseUrlController.text = existing.baseUrl;
      _nameController.text = existing.displayName;
      _selectedModelId = existing.modelName;
      _loadExistingApiKey(existing.id);
    } else {
      _step = _DialogStep.pickFamily;
    }
    _customModelController = TextEditingController(text: _selectedModelId);
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
    _baseUrlController.dispose();
    _keyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.isEdit;

  bool get _requiresApiKey => _selectedFamily?.requiresApiKey ?? true;

  /// True when the selected model id is not among the family's known models
  /// (legacy config or custom name) — then show a free-text field instead.
  bool get _modelIsCustom {
    final ProviderFamily? f = _selectedFamily;
    if (f == null) return true;
    return !f.models.any((ModelOption m) => m.id == _selectedModelId);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _selectFamily(ProviderFamily family) {
    setState(() {
      _selectedFamily = family;
      _step = _DialogStep.configure;
      _testState = _TestState.idle;
      _testError = null;
      _baseUrlController.text = family.baseUrl;
      _nameController.text = family.name;
      _selectedModelId = family.defaultModel.id;
      _customModelController.text = _selectedModelId;
    });
  }

  void _backToFamilies() {
    setState(() {
      _step = _DialogStep.pickFamily;
      _selectedFamily = null;
      _testState = _TestState.idle;
      _testError = null;
    });
  }

  String get _trimmedBaseUrl => _baseUrlController.text.trim();

  String get _apiKey => _keyController.text.trim();

  /// In edit mode: true when the user actually changed the pre-filled key.
  /// When false, [SettingsProvider.updateProvider] is called with
  /// `newApiKey: null` so the stored key is never rewritten/overwritten.
  bool get _keyChanged => _apiKey.isNotEmpty && _apiKey != _originalKey;

  /// Current effective model id (radio selection or custom text).
  String get _effectiveModelId {
    if (_modelIsCustom) return _customModelController.text.trim();
    return _selectedModelId;
  }

  /// Builds a config from the current form values. In edit mode the original
  /// id/familyId are preserved.
  ProviderConfig _buildConfig() {
    if (_isEdit) {
      return widget.existing!.copyWith(
        displayName: _nameController.text.trim().isEmpty
            ? widget.existing!.displayName
            : _nameController.text.trim(),
        baseUrl: _trimmedBaseUrl.isEmpty
            ? widget.existing!.baseUrl
            : _trimmedBaseUrl,
        modelName: _effectiveModelId,
      );
    }
    final ProviderFamily family = _selectedFamily!;
    return ProviderConfig(
      id: 'provider_${DateTime.now().millisecondsSinceEpoch}',
      presetId: family.id,
      familyId: family.id,
      displayName: _nameController.text.trim().isEmpty
          ? family.name
          : _nameController.text.trim(),
      baseUrl: _trimmedBaseUrl.isEmpty ? family.baseUrl : _trimmedBaseUrl,
      modelName: _effectiveModelId,
      supportsVision: family.supportsVision,
      supportsFunctions: family.supportsFunctions,
    );
  }

  bool get _canSubmit {
    if (_saving) return false;
    if (_selectedFamily == null && !_isEdit) return false;
    if (_effectiveModelId.isEmpty) return false;
    if (_trimmedBaseUrl.isEmpty) return false;
    // Add mode: families that require a key must have one. Edit mode: the
    // key field is pre-filled from storage; leaving it unchanged keeps it.
    if (!_isEdit && _requiresApiKey && _apiKey.isEmpty) return false;
    return true;
  }

  Future<void> _testConnection() async {
    if (_selectedFamily == null && !_isEdit) return;
    if (_requiresApiKey && _apiKey.isEmpty) {
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
      // For local families (Ollama) the key may be empty — addProvider still
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
            ? 'Редактировать провайдер'
            : _step == _DialogStep.pickFamily
                ? 'Добавить модель ИИ'
                : _selectedFamily?.name ?? 'Настройка провайдера',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _step == _DialogStep.pickFamily
            ? _buildFamilyList()
            : SingleChildScrollView(child: _buildForm()),
      ),
      actions: <Widget>[
        if (_step == _DialogStep.configure && !_isEdit)
          TextButton(
            onPressed: _saving ? null : _backToFamilies,
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

  // Step 1 — family picker -----------------------------------------------------

  Widget _buildFamilyList() {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: 340,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: ProviderFamilies.all.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final ProviderFamily family = ProviderFamilies.all[index];
          return ListTile(
            dense: true,
            leading: Text(family.icon, style: const TextStyle(fontSize: 22)),
            title: Text(family.name),
            subtitle: Text(
              family.baseUrl,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${family.models.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => _selectFamily(family),
          );
        },
      ),
    );
  }

  // Step 2 — configuration form ------------------------------------------------

  Widget _buildForm() {
    final ThemeData theme = Theme.of(context);
    final ProviderFamily? family = _selectedFamily;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (family != null) ...<Widget>[
          Row(
            children: <Widget>[
              Text(family.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  family.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Отображаемое имя',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        // Model selection ------------------------------------------------------
        if (family != null && !_modelIsCustom)
          _buildModelPicker(theme, family)
        else
          TextField(
            controller: _customModelController,
            autocorrect: false,
            enableSuggestions: false,
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
            helperText: (_isEdit || (family?.isLocal ?? false))
                ? 'Для Android-эмулятора используйте 10.0.2.2 вместо localhost'
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (_requiresApiKey)
          TextField(
            controller: _keyController,
            obscureText: _obscureKey,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'API-ключ',
              hintText: _isEdit ? 'Не меняйте, если ключ тот же' : null,
              helperText: _isEdit
                  ? 'Ключ загружен из защищённого хранилища. '
                      'Измените только при необходимости — '
                      'без изменений старый ключ сохранится.'
                  : (family != null
                      ? 'Получить ключ: ${family.docsUrl}'
                      : null),
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
          )
        else ...<Widget>[
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
                  'Локальный Ollama: API-ключ не требуется. Убедитесь, что '
                  'ollama serve запущен и модель установлена '
                  '(ollama pull llama3.2).',
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

  Widget _buildModelPicker(ThemeData theme, ProviderFamily family) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Модель',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        ...family.models.map((ModelOption model) {
          final bool recommendedBadge = model.recommended;
          return RadioListTile<String>(
            value: model.id,
            groupValue: _selectedModelId,
            dense: true,
            visualDensity: VisualDensity.compact,
            onChanged: (String? value) {
              if (value != null) setState(() => _selectedModelId = value);
            },
            title: Row(
              children: <Widget>[
                Flexible(child: Text(model.name)),
                if (recommendedBadge) ...<Widget>[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
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
          );
        }),
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
            Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
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
