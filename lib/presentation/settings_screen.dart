import 'package:auto_route/auto_route.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:local_assistant/router/app_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
                  hfToken: defaultSettings.hfToken,
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
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _draftSettings.locale,
                  borderRadius: BorderRadius.circular(12),
                  alignment: AlignmentDirectional.centerEnd,
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(t.settings.systemLanguage),
                    ),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
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

            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            _buildSectionHeader(
              context,
              t.settings.aiModels,
              Icons.smart_toy_outlined,
            ),
            Card.filled(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.model_training),
                title: Text(t.settings.modelMenu.title),
                subtitle: Text(t.settings.modelMenu.subtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.router.push(const ModelMenuRoute());
                },
              ),
            ),

            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            _buildSectionHeader(
              context,
              t.settings.storageManagement,
              Icons.storage_outlined,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              leading: const Icon(Icons.cleaning_services),
              title: Text(t.settings.cleanUpStorage),
              subtitle: Text(t.settings.cleanUpStorageSubtitle),
              onTap: () async {
                try {
                  final manager = FlutterGemmaPlugin.instance.modelManager;
                  final orphanedFiles = await manager.getOrphanedFiles();
                  if (orphanedFiles.isEmpty) {
                    if (context.mounted) {
                      showInfoSnackBar(context, t.settings.noOrphanedFiles);
                    }
                    return;
                  }
                  final count = await manager.cleanupStorage();
                  if (context.mounted) {
                    showSuccessSnackBar(
                      context,
                      t.settings.freedUpStorage(count: count),
                    );
                  }
                } catch (e) {
                  appLogger.e("Storage cleanup failed.", error: e);
                  if (context.mounted) {
                    showErrorSnackBar(
                      context,
                      t.settings.cleanupFailed(error: e.toString()),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 16),
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

class DownloadModelDialog extends ConsumerStatefulWidget {
  const DownloadModelDialog({
    super.key,
    required this.model,
    required this.currentSettings,
    required this.onDownloaded,
  });

  final AppSettings currentSettings;
  final AvailableModel model;
  final VoidCallback onDownloaded;

  @override
  ConsumerState<DownloadModelDialog> createState() =>
      _DownloadModelDialogState();
}

class _DownloadModelDialogState extends ConsumerState<DownloadModelDialog> {
  String? _error;
  int? _progress;
  late TextEditingController _tokenController;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(
      text: widget.currentSettings.hfToken,
    );
  }

  Future<void> _checkConnectivityAndStart() async {
    final t = Translations.of(context);

    final freeBytes = await ref.read(freeStorageBytesProvider.future);
    const int fiveGbInBytes = 5 * 1024 * 1024 * 1024;

    if (freeBytes != -1 && freeBytes < fiveGbInBytes) {
      if (mounted) {
        showErrorSnackBar(context, t.errors.insufficientStorage);
        Navigator.pop(context);
      }
      return;
    }

    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() => _error = t.download.noInternet);
      return;
    }

    if (mounted && connectivityResult.contains(ConnectivityResult.mobile)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Text(t.download.mobileDataWarningTitle),
            ],
          ),
          content: Text(t.download.mobileDataWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.download.proceed),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    _startDownload();
  }

  Future<void> _startDownload() async {
    final t = Translations.of(context);
    if (widget.model.requiresAuth && _tokenController.text.trim().isEmpty) {
      setState(() => _error = t.download.hfTokenRequired);
      return;
    }

    setState(() {
      _progress = 0;
      _error = null;
    });

    WakelockPlus.enable();

    try {
      final fileType = widget.model.fileName.endsWith('.litertlm')
          ? ModelFileType.litertlm
          : ModelFileType.task;

      await FlutterGemma.installModel(
            modelType: widget.model.modelType,
            fileType: fileType,
          )
          .fromNetwork(
            widget.model.url,
            token: _tokenController.text.trim().isNotEmpty
                ? _tokenController.text.trim()
                : null,
          )
          .withProgress((progress) {
            if (mounted) setState(() => _progress = progress);
          })
          .install();

      if (mounted) {
        final container = ProviderScope.containerOf(context);
        final settingsNotifier = container.read(
          settingsControllerProvider.notifier,
        );
        await settingsNotifier.updateSettings(
          widget.currentSettings.copyWith(
            hfToken: _tokenController.text.trim(),
          ),
          reloadModel: false,
        );

        container.invalidate(isModelInstalledProvider(widget.model.id));
        widget.onDownloaded();

        if (mounted) {
          Navigator.pop(context);
          showSuccessSnackBar(context, t.download.downloadSuccess);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = t.download.downloadFailed(error: e.toString());
          _progress = null;
        });
        showErrorSnackBar(
          context,
          t.download.downloadFailed(error: e.toString()),
        );
      }
    } finally {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final progress = _progress;
    final theme = Theme.of(context);
    final hasError = _error != null;

    return AlertDialog(
      title: Text(t.download.title(name: widget.model.name)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.model.requiresAuth) ...[
              Text(
                t.download.requiresAuth,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: t.download.hfToken,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 20),
            if (progress != null) ...[
              SizedBox(
                height: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: progress == 100 ? 1.0 : progress / 100,
                  ),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) => LinearProgressIndicator(
                    value: value,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress.toDouble()),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) => Text(
                  progress == 100
                      ? t.download.processing
                      : t.download.downloading(
                          progress: value.toStringAsFixed(1),
                        ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (progress == null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.common.cancel),
          ),
          if (hasError)
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.common.cancel),
            )
          else
            FilledButton(
              onPressed: _checkConnectivityAndStart,
              child: Text(t.download.startDownload),
            ),
        ],
      ],
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
