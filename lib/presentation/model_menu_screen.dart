import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/application/model_manager_provider.dart';
import 'package:local_assistant/application/settings_provider.dart';
import 'package:local_assistant/core/snackbar_helper.dart';
import 'package:local_assistant/domain/models.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';
import 'package:local_assistant/presentation/settings_screen.dart';

@RoutePage()
class ModelMenuScreen extends ConsumerStatefulWidget {
  const ModelMenuScreen({super.key});

  @override
  ConsumerState<ModelMenuScreen> createState() => _ModelMenuScreenState();
}

class _ModelMenuScreenState extends ConsumerState<ModelMenuScreen> {
  late AppSettings _draftSettings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _draftSettings = ref.read(settingsControllerProvider);
  }

  void _updateSelectedModel(AvailableModel model) {
    setState(() {
      _draftSettings = _draftSettings.copyWith(selectedModel: model.id);
      if (_draftSettings.maxTokens > model.maxContextSize) {
        _draftSettings = _draftSettings.copyWith(
          maxTokens: model.maxContextSize,
        );
      }
    });
  }

  Future<void> _saveSettings() async {
    final t = Translations.of(context);
    setState(() => _isSaving = true);

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(_draftSettings, reloadModel: true);
      if (mounted) {
        showSuccessSnackBar(context, t.settings.settingsApplied);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          t.settings.errorWithDetails(details: e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

  void _showDownloadDialog(AvailableModel model) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DownloadModelDialog(
        model: model,
        currentSettings: _draftSettings,
        onDownloaded: () {
          _updateSelectedModel(model);
          ref.invalidate(isModelInstalledProvider(model.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final selectedModelDef = kAvailableModels.firstWhere(
      (m) => m.id == _draftSettings.selectedModel,
      orElse: () => kAvailableModels.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.modelMenu.title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader(
            context,
            t.settings.modelMenu.selectModel,
            Icons.smart_toy_outlined,
          ),
          ...kAvailableModels.map((model) {
            final isInstalledAsync = ref.watch(
              isModelInstalledProvider(model.id),
            );
            final isSelected = _draftSettings.selectedModel == model.id;

            return Card.filled(
              elevation: isSelected ? 2 : 0,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      model.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (model.isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.common.recommended.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onTertiaryContainer,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
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
                    const SizedBox(height: 4),
                    isInstalledAsync.when(
                      data: (installed) => Text(
                        installed
                            ? t.settings.readyToUse
                            : t.settings.notDownloaded,
                        style: TextStyle(
                          color: installed
                              ? (isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.green.shade600)
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: installed
                              ? FontWeight.w500
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      loading: () => Text(
                        t.settings.checkingStatus,
                        style: const TextStyle(fontSize: 12),
                      ),
                      error: (_, _) => Text(
                        t.settings.errorCheckingStatus,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                trailing: isInstalledAsync.value == true
                    ? (isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.check_circle_outline,
                                color: theme.colorScheme.outline,
                              ),
                              onPressed: () => _updateSelectedModel(model),
                            ))
                    : IconButton(
                        icon: const Icon(Icons.download_rounded),
                        color: theme.colorScheme.primary,
                        tooltip: t.settings.downloadModelTooltip,
                        onPressed: () => _showDownloadDialog(model),
                      ),
                onTap: isInstalledAsync.value == true
                    ? () => _updateSelectedModel(model)
                    : null,
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 16),

          _buildSectionHeader(
            context,
            t.settings.modelMenu.modelOptions,
            Icons.tune_outlined,
          ),

          if (selectedModelDef.supportsThinking)
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  t.settings.modelMenu.backendDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.settings.applyChanges),
          ),
        ),
      ),
    );
  }
}
