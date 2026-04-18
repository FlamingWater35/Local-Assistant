import 'package:auto_route/auto_route.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:local_assistant/application/updater_provider.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../application/device_info_provider.dart';
import '../application/model_manager_provider.dart';
import '../application/settings_provider.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';
import '../domain/models.dart';

@RoutePage()
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late AppSettings _draftSettings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _draftSettings = ref.read(settingsControllerProvider);
    if (_draftSettings.maxTokens < 2048) {
      _draftSettings = _draftSettings.copyWith(maxTokens: 2048);
    }
  }

  void _showDownloadDialog(AvailableModel model) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DownloadModelDialog(
        model: model,
        currentSettings: _draftSettings,
        onDownloaded: () {
          setState(() {
            _draftSettings = _draftSettings.copyWith(selectedModel: model.id);
          });
        },
      ),
    ).then((_) => setState(() {}));
  }

  void _confirmDeleteModel(AvailableModel model) {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.settings.deleteModelTitle),
        content: Text(t.settings.deleteModelConfirm(name: model.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(modelDownloaderProvider.notifier)
                  .deleteModel(model);
              if (mounted) {
                showSuccessSnackBar(context, t.settings.modelDeleted);
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndLoad() async {
    final t = Translations.of(context);
    final isInstalled = await ref.read(
      isModelInstalledProvider(_draftSettings.selectedModel).future,
    );

    if (!mounted) return;

    if (!isInstalled) {
      showErrorSnackBar(context, t.settings.modelNotDownloaded);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(_draftSettings, reloadModel: true);

      if (!mounted) return;

      showSuccessSnackBar(context, t.settings.settingsApplied);
      context.router.back();
    } catch (e) {
      appLogger.e("Settings: Error saving settings", error: e);
      if (!mounted) return;
      showErrorSnackBar(
        context,
        t.settings.errorWithDetails(details: e.toString()),
      );
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

    bool isSafe = true;
    if (ramGb > 0) {
      if (maxTokens > 4096 && ramGb < 7.5) isSafe = false;
      if (maxTokens > 2048 && ramGb < 3.5) isSafe = false;
    }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        forceMaterialTransparency: true,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: kAvailableModels.map((model) {
                  final isInstalledAsync = ref.watch(
                    isModelInstalledProvider(model.id),
                  );
                  final isSelected = _draftSettings.selectedModel == model.id;

                  return Card.filled(
                    elevation: isSelected ? 2 : 0,
                    margin: const EdgeInsets.only(bottom: 8),
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
                      title: Text(
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
                      subtitle: isInstalledAsync.when(
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
                          ),
                        ),
                        loading: () => Text(t.settings.checkingStatus),
                        error: (_, _) => Text(t.settings.errorCheckingStatus),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isInstalledAsync.value == true && !isSelected)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              tooltip: t.settings.deleteModelTitle,
                              onPressed: () => _confirmDeleteModel(model),
                            ),
                          isInstalledAsync.value == true
                              ? (isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: theme.colorScheme.primary,
                                      )
                                    : const Icon(Icons.circle_outlined))
                              : IconButton(
                                  icon: const Icon(Icons.download_rounded),
                                  color: theme.colorScheme.primary,
                                  tooltip: t.settings.downloadModelTooltip,
                                  onPressed: () => _showDownloadDialog(model),
                                ),
                        ],
                      ),
                      onTap: isInstalledAsync.value == true
                          ? () => setState(
                              () => _draftSettings = _draftSettings.copyWith(
                                selectedModel: model.id,
                              ),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
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
                      Text("2048", style: theme.textTheme.labelMedium),
                      Expanded(
                        child: Slider(
                          value: _draftSettings.maxTokens.toDouble(),
                          min: 2048,
                          max: 8192,
                          divisions: 12,
                          label:
                              '${_draftSettings.maxTokens} ${t.settings.tokens}',
                          onChanged: (val) => setState(
                            () => _draftSettings = _draftSettings.copyWith(
                              maxTokens: val.toInt(),
                            ),
                          ),
                        ),
                      ),
                      Text("8192", style: theme.textTheme.labelMedium),
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
                          divisions: 20,
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
  void initState() {
    super.initState();
    _tokenController = TextEditingController(
      text: widget.currentSettings.hfToken,
    );
  }

  Future<void> _checkConnectivityAndStart() async {
    final t = Translations.of(context);
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
    appLogger.i("DownloadDialog: Starting download for ${widget.model.id}");
    if (widget.model.requiresAuth && _tokenController.text.trim().isEmpty) {
      appLogger.w("DownloadDialog: HF Token missing.");
      setState(() => _error = t.download.hfTokenRequired);
      return;
    }

    setState(() {
      _progress = 0;
      _error = null;
    });

    WakelockPlus.enable();

    try {
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(widget.model.url, token: _tokenController.text.trim())
          .withProgress((p) {
            if (mounted) setState(() => _progress = p);
          })
          .install();

      appLogger.i("DownloadDialog: Download complete. Saving token.");
      final settingsNotifier = ref.read(settingsControllerProvider.notifier);
      await settingsNotifier.updateSettings(
        widget.currentSettings.copyWith(hfToken: _tokenController.text.trim()),
        reloadModel: false,
      );

      ref.invalidate(isModelInstalledProvider(widget.model.id));
      widget.onDownloaded();

      if (mounted) {
        Navigator.pop(context);
        showSuccessSnackBar(context, t.download.downloadSuccess);
      }
    } catch (e) {
      appLogger.e("DownloadDialog: Download failed", error: e);
      if (mounted) {
        setState(() => _error = t.download.downloadFailed(error: e.toString()));
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
    return AlertDialog(
      title: Text(t.download.title(name: widget.model.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.model.requiresAuth) ...[
            Text(t.download.requiresAuth, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: t.download.hfToken,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: progress == null,
            ),
          ],
          const SizedBox(height: 20),
          if (progress != null) ...[
            LinearProgressIndicator(
              value: progress / 100,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Text(
              t.download.downloading(progress: progress),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (progress == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.common.cancel),
          ),
        if (progress == null)
          FilledButton(
            onPressed: _checkConnectivityAndStart,
            child: Text(t.download.startDownload),
          ),
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
