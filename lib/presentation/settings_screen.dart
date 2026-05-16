import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:local_assistant/router/app_router.dart';

import '../application/device_info_provider.dart';
import '../application/model_manager_provider.dart';
import '../application/settings_provider.dart';
import '../application/updater_provider.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';
import '../domain/models.dart';
import '../i18n/generated/translations.g.dart';

@RoutePage()
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late String _activeConfigId;
  late List<SettingConfiguration> _configurations;
  late AppSettings _draftSettings;
  bool _isLoading = false;
  late TextEditingController _systemPromptController;

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _draftSettings = ref.read(settingsControllerProvider);
    _activeConfigId = ref
        .read(settingsControllerProvider.notifier)
        .getActiveConfigurationId();
    _configurations = ref
        .read(settingsControllerProvider.notifier)
        .getConfigurations();

    final selectedModelDef = kAvailableModels.firstWhere(
      (m) => m.id == _draftSettings.selectedModel,
      orElse: () => kAvailableModels.first,
    );

    int validMaxTokens = _draftSettings.maxTokens.clamp(
      512,
      selectedModelDef.maxContextSize,
    );
    if (_draftSettings.maxTokens != validMaxTokens) {
      _draftSettings = _draftSettings.copyWith(maxTokens: validMaxTokens);
    }

    _systemPromptController = TextEditingController(
      text: _draftSettings.systemPrompt,
    );
  }

  void _refreshConfigurations() {
    setState(() {
      _configurations = ref
          .read(settingsControllerProvider.notifier)
          .getConfigurations();
      _activeConfigId = ref
          .read(settingsControllerProvider.notifier)
          .getActiveConfigurationId();
    });
  }

  void _confirmReset() {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.settings.resetDefaults),
        content: Text(t.settings.resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final defaultSettings = AppSettings();
              setState(() {
                _draftSettings = _draftSettings.copyWith(
                  temperature: defaultSettings.temperature,
                  maxTokens: defaultSettings.maxTokens,
                  systemPrompt: defaultSettings.systemPrompt,
                  enableGlobalMemory: defaultSettings.enableGlobalMemory,
                  enableThinking: defaultSettings.enableThinking,
                  selectedBackend: defaultSettings.selectedBackend,
                );
                _systemPromptController.text = _draftSettings.systemPrompt;
              });
              showInfoSnackBar(context, t.settings.resetSuccess);
            },
            child: Text(t.settings.resetDefaults),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndLoad() async {
    final t = Translations.of(context);

    final previousSettings = ref.read(settingsControllerProvider);

    _draftSettings = _draftSettings.copyWith(
      systemPrompt: _systemPromptController.text,
    );

    final isInstalled = await ref.read(
      isModelInstalledProvider(_draftSettings.selectedModel).future,
    );

    if (!mounted) return;

    if (!isInstalled) {
      showErrorSnackBar(context, t.settings.modelNotDownloaded);
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(_draftSettings, reloadModel: true);

      if (!mounted) return;

      showSuccessSnackBar(context, t.settings.settingsApplied);
      context.router.back();
    } catch (e) {
      appLogger.e("Settings: Error saving settings", error: e);
      if (mounted) {
        setState(() {
          _draftSettings = previousSettings;
          _systemPromptController.text = previousSettings.systemPrompt;
        });
        showErrorSnackBar(
          context,
          t.settings.errorWithDetails(details: e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddConfigurationDialog() {
    final t = Translations.of(context);
    final nameController = TextEditingController();
    bool copyCurrent = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t.settings.configurations.addTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: t.settings.configurations.nameLabel,
                  hintText: t.settings.configurations.nameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.settings.configurations.copySettings),
                value: copyCurrent,
                onChanged: (val) => setDialogState(() => copyCurrent = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                await ref
                    .read(settingsControllerProvider.notifier)
                    .addConfiguration(name, copyCurrent: copyCurrent);
                _refreshConfigurations();
              },
              child: Text(t.settings.configurations.add),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameConfigurationDialog(SettingConfiguration config) {
    final t = Translations.of(context);
    final nameController = TextEditingController(text: config.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.settings.configurations.renameTitle),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.settings.configurations.nameLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(settingsControllerProvider.notifier)
                  .renameConfiguration(config.id, name);
              _refreshConfigurations();
            },
            child: Text(t.settings.configurations.rename),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConfiguration(SettingConfiguration config) {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.settings.configurations.delete),
        content: Text(
          t.settings.configurations.deleteConfirm(name: config.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(settingsControllerProvider.notifier)
                  .deleteConfiguration(config.id);
              if (mounted) {
                if (!success) {
                  showErrorSnackBar(
                    context,
                    t.settings.configurations.cannotDeleteLast,
                  );
                } else {
                  _draftSettings = ref.read(settingsControllerProvider);
                  _systemPromptController.text = _draftSettings.systemPrompt;
                  _refreshConfigurations();
                }
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  void _switchConfiguration(String configId) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .switchConfiguration(configId);
    setState(() {
      _draftSettings = ref.read(settingsControllerProvider);
      _systemPromptController.text = _draftSettings.systemPrompt;
    });
    _refreshConfigurations();
  }

  void _showModelSelector() {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    for (final model in kAvailableModels) {
      ref.invalidate(isModelInstalledProvider(model.id));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final downloadedModels = kAvailableModels.where((m) {
            return ref.watch(isModelInstalledProvider(m.id)).value == true;
          }).toList();

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    t.settings.modelMenu.selectModel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (downloadedModels.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      t.settings.modelManagement.noModelsInstalled,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ...downloadedModels.map((model) {
                  final isSelected = _draftSettings.selectedModel == model.id;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    title: Text(
                      model.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: _buildModelChips(model, theme),
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _draftSettings = _draftSettings.copyWith(
                          selectedModel: model.id,
                        );
                        if (_draftSettings.maxTokens > model.maxContextSize) {
                          _draftSettings = _draftSettings.copyWith(
                            maxTokens: model.maxContextSize,
                          );
                        }
                      });
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: Text(t.settings.modelManagement.title),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.router.push(const ModelManagementRoute());
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModelChips(AvailableModel model, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        children: [
          if (model.supportsImages)
            _buildChip(
              Icons.image,
              t.settings.modelMenu.supportsImages,
              theme.colorScheme.tertiary,
            ),
          if (model.supportsAudio)
            _buildChip(
              Icons.audiotrack,
              t.settings.modelMenu.supportsAudio,
              theme.colorScheme.secondary,
            ),
          if (model.supportsThinking)
            _buildChip(
              Icons.psychology,
              t.settings.modelMenu.supportsThinking,
              theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemDivider(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(indent: 24)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.settings.systemSettings,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: Divider(endIndent: 24)),
        ],
      ),
    );
  }

  Widget _buildRamIndicator(BuildContext context, double ramGb, int maxTokens) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    final bool isSafe = AppConstants.isMemorySafe(ramGb, maxTokens);

    final safeColor = theme.brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSafe
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSafe ? safeColor : theme.colorScheme.error,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                ramGb > 0
                    ? t.settings.ramIndicator.detected(
                        ram: ramGb.toStringAsFixed(1),
                      )
                    : t.settings.ramIndicator.unknown,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isSafe
                ? t.settings.ramIndicator.safe
                : t.settings.ramIndicator.warning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSafe ? safeColor : theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSelector(
    BuildContext context,
    ThemeData theme,
    SettingConfiguration activeConfig,
  ) {
    final t = Translations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    t.settings.configurations.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: theme.colorScheme.primary,
                    tooltip: t.settings.configurations.add,
                    onPressed: _showAddConfigurationDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _activeConfigId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    icon: Icon(
                      Icons.unfold_more,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    items: _configurations.map((config) {
                      final isActive = config.id == _activeConfigId;
                      return DropdownMenuItem<String>(
                        value: config.id,
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                config.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null && value != _activeConfigId) {
                        _switchConfiguration(value);
                      }
                    },
                  ),
                ),
              ),
              if (_configurations.length > 1 || _activeConfigId != 'default')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(t.settings.configurations.rename),
                        onPressed: () =>
                            _showRenameConfigurationDialog(activeConfig),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (_configurations.length > 1)
                        TextButton.icon(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            t.common.delete,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          onPressed: () =>
                              _confirmDeleteConfiguration(activeConfig),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context,
    ThemeData theme,
    AvailableModel selectedModelDef,
  ) {
    final t = Translations.of(context);
    final isInstalled = ref.watch(
      isModelInstalledProvider(_draftSettings.selectedModel),
    );

    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isInstalled.value == true
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : theme.colorScheme.errorContainer.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showModelSelector,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedModelDef.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isInstalled.when(
                      data: (installed) => Text(
                        installed
                            ? t.settings.readyToUse
                            : t.settings.notDownloaded,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: installed
                              ? Colors.green.shade600
                              : theme.colorScheme.error,
                        ),
                      ),
                      loading: () => Text(
                        t.settings.checkingStatus,
                        style: theme.textTheme.bodySmall,
                      ),
                      error: (_, _) => Text(
                        t.settings.errorCheckingStatus,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    final ramAsync = ref.watch(deviceRamGbProvider);
    final double ramGb = ramAsync.value ?? 0.0;

    final selectedModelDef = kAvailableModels.firstWhere(
      (m) => m.id == _draftSettings.selectedModel,
      orElse: () => kAvailableModels.first,
    );
    final maxTokensForModel = selectedModelDef.maxContextSize.toDouble();
    const double minTokens = 512.0;

    final activeConfig = _configurations.firstWhere(
      (c) => c.id == _activeConfigId,
      orElse: () => _configurations.isNotEmpty
          ? _configurations.first
          : const SettingConfiguration(id: 'default', name: 'Default'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.settings.resetDefaults,
            onPressed: _confirmReset,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildConfigurationSelector(context, theme, activeConfig),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Model, context, and behavior settings are saved per configuration',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            _buildSectionHeader(
              context,
              t.settings.aiModels,
              Icons.smart_toy_outlined,
            ),
            _buildModelCard(context, theme, selectedModelDef),

            const SizedBox(height: 8),

            if (selectedModelDef.supportsThinking)
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                secondary: const Icon(Icons.psychology_outlined),
                title: Text(t.settings.modelMenu.enableThinking),
                subtitle: Text(t.settings.modelMenu.enableThinkingDescription),
                value: _draftSettings.enableThinking,
                onChanged: (val) => setState(
                  () => _draftSettings = _draftSettings.copyWith(
                    enableThinking: val,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.settings.modelMenu.backend,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.settings.modelMenu.backendDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<PreferredBackend>(
                    segments: const [
                      ButtonSegment<PreferredBackend>(
                        value: PreferredBackend.cpu,
                        label: Text('CPU'),
                        icon: Icon(Icons.memory, size: 16),
                      ),
                      ButtonSegment<PreferredBackend>(
                        value: PreferredBackend.gpu,
                        label: Text('GPU'),
                        icon: Icon(Icons.graphic_eq, size: 16),
                      ),
                      ButtonSegment<PreferredBackend>(
                        value: PreferredBackend.npu,
                        label: Text('NPU'),
                        icon: Icon(Icons.graphic_eq, size: 16),
                      ),
                    ],
                    selected: {_draftSettings.selectedBackend},
                    onSelectionChanged: (Set<PreferredBackend> selection) {
                      setState(() {
                        _draftSettings = _draftSettings.copyWith(
                          selectedBackend: selection.first,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            _buildSectionHeader(
              context,
              t.settings.inferenceAndMemory,
              Icons.memory_outlined,
            ),

            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              secondary: const Icon(Icons.auto_awesome_outlined),
              title: Text(t.settings.enableMemoryTitle),
              subtitle: Text(t.settings.enableMemorySubtitle),
              value: _draftSettings.enableGlobalMemory,
              onChanged: (val) => setState(
                () => _draftSettings = _draftSettings.copyWith(
                  enableGlobalMemory: val,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.settings.totalContextWindow,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.settings.contextWindowDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text("512", style: theme.textTheme.labelMedium),
                      Expanded(
                        child: Slider(
                          value: _draftSettings.maxTokens.toDouble().clamp(
                            minTokens,
                            maxTokensForModel,
                          ),
                          min: minTokens,
                          max: maxTokensForModel,
                          divisions:
                              ((maxTokensForModel - minTokens) ~/ 256) > 0
                              ? ((maxTokensForModel - minTokens) ~/ 256)
                              : 1,
                          label:
                              '${_draftSettings.maxTokens} ${t.settings.tokens}',
                          onChanged: (val) => setState(
                            () => _draftSettings = _draftSettings.copyWith(
                              maxTokens: val.toInt(),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "${maxTokensForModel.toInt()}",
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      '${_draftSettings.maxTokens} ${t.settings.tokens}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  _buildRamIndicator(context, ramGb, _draftSettings.maxTokens),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            _buildSectionHeader(
              context,
              t.settings.behavior,
              Icons.psychology_outlined,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.settings.systemInstructions,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.settings.systemInstructionsDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _systemPromptController,
                    maxLines: 5,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: t.settings.systemInstructionsHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.settings.temperature,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.settings.temperatureDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text("0.0", style: theme.textTheme.labelMedium),
                      Expanded(
                        child: Slider(
                          value: _draftSettings.temperature,
                          min: 0.0,
                          max: 1.2,
                          divisions: 24,
                          label: _draftSettings.temperature.toStringAsFixed(2),
                          onChanged: (val) => setState(
                            () => _draftSettings = _draftSettings.copyWith(
                              temperature: val,
                            ),
                          ),
                        ),
                      ),
                      Text("1.2", style: theme.textTheme.labelMedium),
                    ],
                  ),
                  Center(
                    child: Text(
                      _draftSettings.temperature.toStringAsFixed(2),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildSystemDivider(context),

            _buildSectionHeader(
              context,
              t.settings.general,
              Icons.tune_outlined,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 0,
              ),
              leading: const Icon(Icons.language_outlined),
              title: Text(t.settings.language),
              trailing: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _draftSettings.locale,
                    borderRadius: BorderRadius.circular(12),
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(t.settings.systemLanguage),
                      ),
                      const DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                      const DropdownMenuItem(
                        value: 'de',
                        child: Text('Deutsch'),
                      ),
                      const DropdownMenuItem(
                        value: 'fr',
                        child: Text('Français'),
                      ),
                      const DropdownMenuItem(value: 'fi', child: Text('Suomi')),
                      const DropdownMenuItem(value: 'zh', child: Text('中文')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(
                          () => _draftSettings = _draftSettings.copyWith(
                            locale: val,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            _buildSectionHeader(
              context,
              t.settings.modelManagement.title,
              Icons.download_outlined,
            ),
            Card.filled(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(t.settings.modelManagement.title),
                subtitle: Text(t.settings.modelManagement.subtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.router.push(const ModelManagementRoute());
                },
              ),
            ),

            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            _buildSectionHeader(
              context,
              t.settings.appUpdate,
              Icons.system_update_outlined,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _UpdaterCard(),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoading
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            )
          : FloatingActionButton.extended(
              onPressed: _saveAndLoad,
              icon: const Icon(Icons.check),
              label: Text(t.settings.applyChanges),
            ),
    );
  }
}

class _UpdaterCard extends ConsumerWidget {
  const _UpdaterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final updateState = ref.watch(updaterControllerProvider);
    final updaterNotifier = ref.read(updaterControllerProvider.notifier);
    final theme = Theme.of(context);

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: switch (updateState) {
          UpdateInitial() => ListTile(
            leading: const Icon(Icons.update),
            title: Text(t.settings.checkForUpdates),
            onTap: updaterNotifier.checkForUpdate,
          ),
          UpdateChecking() => const ListTile(
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Checking for updates...'),
          ),
          UpdateNotAvailable() => ListTile(
            leading: Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
            ),
            title: Text(t.settings.appUpToDate),
            subtitle: Text(t.settings.latestVersion),
            onTap: updaterNotifier.checkForUpdate,
          ),
          UpdateAvailable(info: final info) => Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.download_for_offline_outlined,
                  color: theme.colorScheme.secondary,
                ),
                title: Text(t.settings.updateAvailable(version: info.version)),
                subtitle: Text(t.settings.tapToDownload),
                onTap: updaterNotifier.downloadUpdate,
              ),
              if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        t.settings.releaseNotes,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.all(12.0),
                      children: [GptMarkdown(info.releaseNotes!)],
                    ),
                  ),
                ),
            ],
          ),
          UpdateDownloading(progress: final progress) => ListTile(
            title: Text(t.settings.downloadingUpdate),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.settings.percentComplete(
                      percent: (progress * 100).toStringAsFixed(0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          UpdateError(message: final message) => ListTile(
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: Text(t.settings.updateCheckFailed),
            subtitle: Text(message),
            onTap: updaterNotifier.checkForUpdate,
          ),
        },
      ),
    );
  }
}
