import 'package:auto_route/auto_route.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:local_assistant/application/updater_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text(
          'Are you sure you want to delete ${model.name}? You will have to download it again to use it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
                showSuccessSnackBar(context, 'Model deleted successfully');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndLoad() async {
    final isInstalled = await ref.read(
      isModelInstalledProvider(_draftSettings.selectedModel).future,
    );

    if (!mounted) return;

    if (!isInstalled) {
      showErrorSnackBar(context, 'Selected model is not downloaded!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(_draftSettings, reloadModel: true);

      if (!mounted) return;

      showSuccessSnackBar(context, 'Settings applied successfully');
      context.router.back();
    } catch (e) {
      appLogger.e("Settings: Error saving settings", error: e);
      if (!mounted) return;
      showErrorSnackBar(context, 'Error: $e');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        forceMaterialTransparency: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildSectionHeader(context, 'AI Models', Icons.smart_toy_outlined),
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
                          installed ? "Ready to use" : "Not downloaded",
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
                        loading: () => const Text("Checking status..."),
                        error: (_, _) => const Text("Error checking status"),
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
                              tooltip: 'Delete Model',
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
                                  tooltip: 'Download Model',
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
              'Inference & Memory',
              Icons.memory_outlined,
            ),

            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              title: const Text("Enable Memory Across Chats"),
              subtitle: const Text(
                "Allows the AI to silently reference facts from your other recent conversations.",
              ),
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
                    "Total Context Window",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Hardware memory for Input + Output. Smart Truncation will automatically prune older messages when the limit is reached.",
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
                          label: '${_draftSettings.maxTokens} Tokens',
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
                      '${_draftSettings.maxTokens} Tokens',
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

            _buildSectionHeader(context, 'Behavior', Icons.psychology_outlined),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Temperature", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    "Controls creativity. Lower is more focused, higher is more random.",
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
                          max: 1.0,
                          divisions: 20,
                          label: _draftSettings.temperature.toStringAsFixed(2),
                          onChanged: (val) => setState(
                            () => _draftSettings = _draftSettings.copyWith(
                              temperature: val,
                            ),
                          ),
                        ),
                      ),
                      Text("1.0", style: theme.textTheme.labelMedium),
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
              'App Update',
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
              label: const Text('Apply Changes'),
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
    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() => _error = "No internet connection detected.");
      return;
    }

    if (mounted && connectivityResult.contains(ConnectivityResult.mobile)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Large File Warning'),
            ],
          ),
          content: const Text(
            'You are connected via Mobile Data. This model is a large file (approx 1-2GB) and downloading it may consume significant data or incur additional charges. Proceed anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    _startDownload();
  }

  Future<void> _startDownload() async {
    appLogger.i("DownloadDialog: Starting download for ${widget.model.id}");
    if (widget.model.requiresAuth && _tokenController.text.trim().isEmpty) {
      appLogger.w("DownloadDialog: HF Token missing.");
      setState(() => _error = "HuggingFace Token required.");
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
        showSuccessSnackBar(context, 'Model downloaded successfully!');
      }
    } catch (e) {
      appLogger.e("DownloadDialog: Download failed", error: e);
      if (mounted) {
        setState(() => _error = e.toString());
        showErrorSnackBar(context, 'Download failed: $e');
      }
    } finally {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Download ${widget.model.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.model.requiresAuth) ...[
            const Text(
              "This model requires HuggingFace access.",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'HuggingFace Token',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: _progress == null,
            ),
          ],
          const SizedBox(height: 20),
          if (_progress != null) ...[
            LinearProgressIndicator(
              value: _progress! / 100,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Text(
              'Downloading... $_progress%',
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
        if (_progress == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        if (_progress == null)
          FilledButton(
            onPressed: _checkConnectivityAndStart,
            child: const Text('Start Download'),
          ),
      ],
    );
  }
}

class _UpdaterCard extends ConsumerWidget {
  const _UpdaterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            title: const Text('Check for updates'),
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
            title: const Text('App is up to date'),
            subtitle: const Text('You are using the latest version'),
            onTap: updaterNotifier.checkForUpdate,
          ),
          UpdateAvailable(info: final info) => Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.download_for_offline_outlined,
                  color: theme.colorScheme.secondary,
                ),
                title: Text('Update available: v${info.version}'),
                subtitle: const Text('Tap to download and install'),
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
                      title: const Text(
                        'Release Notes',
                        style: TextStyle(
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
            title: const Text('Downloading update...'),
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
                  Text("${(progress * 100).toStringAsFixed(0)}% complete"),
                ],
              ),
            ),
          ),
          UpdateError(message: final message) => ListTile(
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: const Text('Update check failed'),
            subtitle: Text(message),
            onTap: updaterNotifier.checkForUpdate,
          ),
        },
      ),
    );
  }
}
