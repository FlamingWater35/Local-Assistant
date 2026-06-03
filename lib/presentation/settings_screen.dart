import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/router/app_router.dart';
import 'package:uuid/uuid.dart';

import '../application/model_manager_provider.dart';
import '../application/settings_provider.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';
import '../domain/models.dart';
import '../i18n/generated/translations.g.dart';
import 'settings/widgets/configuration_selector.dart';
import 'settings/widgets/model_card.dart';
import 'settings/widgets/model_feature_chip.dart';
import 'settings/widgets/ram_indicator.dart';
import 'settings/widgets/settings_section_header.dart';
import 'settings/widgets/updater_card.dart';

// The centralized control panel allowing configuration of models, system limits, and UI parameters
@RoutePage()
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  int? _sliderMaxTokens;
  double? _sliderTemperature;
  late TextEditingController _systemPromptController;
  final FocusNode _systemPromptFocus = FocusNode();
  late TabController _tabController;

  @override
  void dispose() {
    _tabController.dispose();
    _systemPromptController.dispose();
    _systemPromptFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final initialSettings = ref.read(settingsControllerProvider);

    _systemPromptController = TextEditingController(
      text: initialSettings.systemPrompt,
    );

    _systemPromptFocus.addListener(() {
      if (!_systemPromptFocus.hasFocus) {
        final current = ref.read(settingsControllerProvider);
        if (_systemPromptController.text != current.systemPrompt) {
          _updateSetting(
            current.copyWith(systemPrompt: _systemPromptController.text),
          );
        }
      }
    });
  }

  // Propagates changed values to the configuration provider
  void _updateSetting(AppSettings newSettings, {bool reloadModel = false}) {
    try {
      ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(newSettings, reloadModel: reloadModel);
    } catch (e, st) {
      appLogger.e(
        "Failed to update dynamic setting value",
        error: e,
        stackTrace: st,
      );
      showErrorSnackBar(context, t.errors.failedToApplySettings);
    }
  }

  // Resets settings to factory defaults after double-confirmation
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
              try {
                final defaultSettings = AppSettings();
                final current = ref.read(settingsControllerProvider);
                _updateSetting(
                  current.copyWith(
                    temperature: defaultSettings.temperature,
                    maxTokens: defaultSettings.maxTokens,
                    systemPrompt: defaultSettings.systemPrompt,
                    enableGlobalMemory: defaultSettings.enableGlobalMemory,
                    enableThinking: defaultSettings.enableThinking,
                    selectedBackend: defaultSettings.selectedBackend,
                  ),
                );
                _systemPromptController.text = defaultSettings.systemPrompt;
                showInfoSnackBar(context, t.settings.resetSuccess);
              } catch (e, st) {
                appLogger.e("Settings reset failed", error: e, stackTrace: st);
                showErrorSnackBar(context, t.errors.resetFailed);
              }
            },
            child: Text(t.settings.resetDefaults),
          ),
        ],
      ),
    );
  }

  // Prompts the file selector to load and apply a custom configurations schema JSON
  Future<void> _importConfig() async {
    final t = Translations.of(context);
    const params = OpenFileDialogParams(fileExtensionsFilter: ['json']);
    try {
      final filePath = await FlutterFileDialog.pickFile(params: params);
      if (filePath != null) {
        final file = File(filePath);
        final jsonStr = await file.readAsString();
        final map = jsonDecode(jsonStr);
        final config = SettingConfiguration.fromJson(
          map,
        ).copyWith(id: const Uuid().v4());

        await ref
            .read(settingsControllerProvider.notifier)
            .addImportedConfiguration(config);

        if (mounted) {
          showSuccessSnackBar(context, t.settings.configurations.importSuccess);
        }
      }
    } catch (e, st) {
      appLogger.e("Config import failed", error: e, stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context, t.settings.configurations.importError);
      }
    }
  }

  // Opens input dialog for setting profile parameters and initiates a new configurations instance
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
                try {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .addConfiguration(name, copyCurrent: copyCurrent);
                } catch (e, st) {
                  appLogger.e(
                    "Failed to add configuration Profile",
                    error: e,
                    stackTrace: st,
                  );
                  if (mounted) {
                    showErrorSnackBar(context, t.errors.failedToCreateProfile);
                  }
                }
              },
              child: Text(t.settings.configurations.add),
            ),
          ],
        ),
      ),
    );
  }

  // Opens dialog for renaming active configuration
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
              try {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .renameConfiguration(config.id, name);
              } catch (e, st) {
                appLogger.e(
                  "Failed to rename profile context",
                  error: e,
                  stackTrace: st,
                );
                if (mounted) {
                  showErrorSnackBar(context, t.errors.failedToRenameProfile);
                }
              }
            },
            child: Text(t.settings.configurations.rename),
          ),
        ],
      ),
    );
  }

  // Deletes settings configuration safely, with safety fallback checks
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
              try {
                final success = await ref
                    .read(settingsControllerProvider.notifier)
                    .deleteConfiguration(config.id);
                if (mounted && !success) {
                  showErrorSnackBar(
                    context,
                    t.settings.configurations.cannotDeleteLast,
                  );
                }
              } catch (e, st) {
                appLogger.e(
                  "Failed to delete configuration context",
                  error: e,
                  stackTrace: st,
                );
                if (mounted) {
                  showErrorSnackBar(context, t.errors.failedToDeleteProfile);
                }
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  // Clones an existing profile template
  void _duplicateConfiguration(SettingConfiguration config) async {
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .duplicateConfiguration(config);
    } catch (e, st) {
      appLogger.e(
        "Failed to duplicate configurations profile",
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        showErrorSnackBar(context, t.errors.duplicateProfileFailed);
      }
    }
  }

  // Toggles the read-only flag on specific profiles to prevent accidental mutations
  void _toggleReadOnly(SettingConfiguration config, bool isReadOnly) async {
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .toggleReadOnly(config.id, isReadOnly);
    } catch (e, st) {
      appLogger.e(
        "Failed to change read-only status",
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        showErrorSnackBar(context, t.errors.toggleReadOnlyFailed);
      }
    }
  }

  // Switches profiles and refreshes UI form states securely
  void _switchConfiguration(String configId) async {
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .switchConfiguration(configId);
      if (mounted) {
        _systemPromptController.text = ref
            .read(settingsControllerProvider)
            .systemPrompt;
      }
    } catch (e, st) {
      appLogger.e(
        "Failed to apply requested configurations profile switch",
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        showErrorSnackBar(context, t.errors.switchProfileFailed);
      }
    }
  }

  // Opens a modal for picking and setting an active downloaded LLM model context
  void _showModelSelector() {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final currentSettings = ref.read(settingsControllerProvider);

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
                  final isSelected = currentSettings.selectedModel == model.id;
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
                      var next = currentSettings.copyWith(
                        selectedModel: model.id,
                      );
                      if (next.maxTokens > model.maxContextSize) {
                        next = next.copyWith(maxTokens: model.maxContextSize);
                      }
                      _updateSetting(next, reloadModel: true);
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
    final t = Translations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        children: [
          if (model.supportsImages)
            ModelFeatureChip(
              icon: Icons.image,
              label: t.settings.modelMenu.supportsImages,
              color: theme.colorScheme.tertiary,
            ),
          if (model.supportsAudio)
            ModelFeatureChip(
              icon: Icons.audiotrack,
              label: t.settings.modelMenu.supportsAudio,
              color: theme.colorScheme.secondary,
            ),
          if (model.supportsThinking)
            ModelFeatureChip(
              icon: Icons.psychology,
              label: t.settings.modelMenu.supportsThinking,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildLivePreview(AppSettings currentSettings) {
    final theme = Theme.of(context);
    String previewText =
        "Paris is the capital of France, known for its art and culture.";
    if (currentSettings.temperature < 0.3) {
      previewText = "The capital of France is Paris.";
    } else if (currentSettings.temperature >= 0.7) {
      previewText =
          "Ah, Paris! The luminous capital of France, a city where art, history, and romance intertwine...";
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                Translations.of(context).settings.livePreview,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              previewText,
              key: ValueKey(previewText),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationsTab() {
    final configurations = ref
        .watch(settingsControllerProvider.notifier)
        .getConfigurations();
    final activeConfigId = ref
        .watch(settingsControllerProvider.notifier)
        .getActiveConfigurationId();

    return ConfigurationSelector(
      activeConfigId: activeConfigId,
      configurations: configurations,
      onSwitch: _switchConfiguration,
      onAdd: _showAddConfigurationDialog,
      onRename: _showRenameConfigurationDialog,
      onDelete: _confirmDeleteConfiguration,
      onDuplicate: _duplicateConfiguration,
      onToggleReadOnly: _toggleReadOnly,
      onImport: _importConfig,
    );
  }

  Widget _buildSystemTab(AppSettings currentSettings) {
    final t = Translations.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSectionHeader(
          title: t.settings.modelManagement.title,
          icon: Icons.download_outlined,
        ),
        Card.filled(
          clipBehavior: Clip.antiAlias,
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
        SettingsSectionHeader(
          title: t.settings.general,
          icon: Icons.tune_outlined,
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
                value: currentSettings.locale,
                borderRadius: BorderRadius.circular(12),
                alignment: AlignmentDirectional.centerEnd,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(t.settings.systemLanguage),
                  ),
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                  const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                  const DropdownMenuItem(value: 'fr', child: Text('Français')),
                  const DropdownMenuItem(value: 'fi', child: Text('Suomi')),
                  const DropdownMenuItem(value: 'zh', child: Text('中文')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _updateSetting(currentSettings.copyWith(locale: val));
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(indent: 16, endIndent: 16),
        const SizedBox(height: 8),
        SettingsSectionHeader(
          title: t.settings.appUpdate,
          icon: Icons.system_update_outlined,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: UpdaterCard(),
        ),
      ],
    );
  }

  Widget _buildInferenceTab(AppSettings currentSettings) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final selectedModelDef = kAvailableModels.firstWhere(
      (m) => m.id == currentSettings.selectedModel,
      orElse: () => kAvailableModels.first,
    );
    final maxTokensForModel = selectedModelDef.maxContextSize.toDouble();
    const double minTokens = 512.0;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSectionHeader(
          title: t.settings.aiModels,
          icon: Icons.smart_toy_outlined,
        ),
        ModelCard(
          selectedModelDef: selectedModelDef,
          onTap: _showModelSelector,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: t.settings.modelMenu.backendDescription,
                child: Text(
                  t.settings.modelMenu.backend,
                  style: theme.textTheme.titleMedium,
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
                selected: {currentSettings.selectedBackend},
                onSelectionChanged: (Set<PreferredBackend> selection) {
                  _updateSetting(
                    currentSettings.copyWith(selectedBackend: selection.first),
                    reloadModel: true,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(indent: 16, endIndent: 16),
        const SizedBox(height: 8),
        SettingsSectionHeader(
          title: t.settings.inferenceAndMemory,
          icon: Icons.memory_outlined,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: t.settings.contextWindowDescription,
                child: Text(
                  t.settings.totalContextWindow,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text("512", style: theme.textTheme.labelMedium),
                  Expanded(
                    child: Slider(
                      value: (_sliderMaxTokens ?? currentSettings.maxTokens)
                          .toDouble()
                          .clamp(minTokens, maxTokensForModel),
                      min: minTokens,
                      max: maxTokensForModel,
                      divisions: ((maxTokensForModel - minTokens) ~/ 256) > 0
                          ? ((maxTokensForModel - minTokens) ~/ 256)
                          : 1,
                      label:
                          '${_sliderMaxTokens ?? currentSettings.maxTokens} ${t.settings.tokens}',
                      onChanged: (val) =>
                          setState(() => _sliderMaxTokens = val.toInt()),
                      onChangeEnd: (val) {
                        _updateSetting(
                          currentSettings.copyWith(maxTokens: val.toInt()),
                          reloadModel: true,
                        );
                        setState(() => _sliderMaxTokens = null);
                      },
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
                  '${_sliderMaxTokens ?? currentSettings.maxTokens} ${t.settings.tokens}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              RamIndicator(
                maxTokens: _sliderMaxTokens ?? currentSettings.maxTokens,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          title: Text(t.settings.advancedMemoryOptions),
          leading: const Icon(Icons.auto_awesome_outlined),
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              title: Text(t.settings.enableMemoryTitle),
              subtitle: Text(t.settings.enableMemorySubtitle),
              value: currentSettings.enableGlobalMemory,
              onChanged: (val) {
                _updateSetting(
                  currentSettings.copyWith(enableGlobalMemory: val),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBehaviorTab(AppSettings currentSettings) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final selectedModelDef = kAvailableModels.firstWhere(
      (m) => m.id == currentSettings.selectedModel,
      orElse: () => kAvailableModels.first,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSectionHeader(
          title: t.settings.behavior,
          icon: Icons.psychology_outlined,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: t.settings.temperatureDescription,
                child: Text(
                  t.settings.temperature,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text("0.0", style: theme.textTheme.labelMedium),
                  Expanded(
                    child: Slider(
                      value: _sliderTemperature ?? currentSettings.temperature,
                      min: 0.0,
                      max: 1.2,
                      divisions: 24,
                      label: (_sliderTemperature ?? currentSettings.temperature)
                          .toStringAsFixed(2),
                      onChanged: (val) =>
                          setState(() => _sliderTemperature = val),
                      onChangeEnd: (val) {
                        _updateSetting(
                          currentSettings.copyWith(temperature: val),
                        );
                        setState(() => _sliderTemperature = null);
                      },
                    ),
                  ),
                  Text("1.2", style: theme.textTheme.labelMedium),
                ],
              ),
              Center(
                child: Text(
                  (_sliderTemperature ?? currentSettings.temperature)
                      .toStringAsFixed(2),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              _buildLivePreview(currentSettings),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (selectedModelDef.supportsThinking)
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            secondary: const Icon(Icons.psychology_outlined),
            title: Text(t.settings.modelMenu.enableThinking),
            subtitle: Text(t.settings.modelMenu.enableThinkingDescription),
            value: currentSettings.enableThinking,
            onChanged: (val) {
              _updateSetting(
                currentSettings.copyWith(enableThinking: val),
                reloadModel: true,
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: t.settings.systemInstructionsDescription,
                child: Text(
                  t.settings.systemInstructions,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _systemPromptController,
                focusNode: _systemPromptFocus,
                maxLines: 5,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: t.settings.systemInstructionsHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (val) {
                  if (val != currentSettings.systemPrompt) {
                    _updateSetting(currentSettings.copyWith(systemPrompt: val));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        forceMaterialTransparency: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: t.settings.tabs.configs),
            Tab(text: t.settings.tabs.system),
            Tab(text: t.settings.tabs.inference),
            Tab(text: t.settings.tabs.behavior),
          ],
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildConfigurationsTab(),
            _buildSystemTab(ref.watch(settingsControllerProvider)),
            _buildInferenceTab(ref.watch(settingsControllerProvider)),
            _buildBehaviorTab(ref.watch(settingsControllerProvider)),
          ],
        ),
      ),
    );
  }
}
