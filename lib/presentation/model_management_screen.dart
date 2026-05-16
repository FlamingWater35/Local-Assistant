import 'package:auto_route/auto_route.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../application/device_info_provider.dart';
import '../application/model_manager_provider.dart';
import '../application/settings_provider.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';
import '../domain/models.dart';
import '../i18n/generated/translations.g.dart';

@RoutePage()
class ModelManagementScreen extends ConsumerStatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  ConsumerState<ModelManagementScreen> createState() =>
      _ModelManagementScreenState();
}

class _ModelManagementScreenState extends ConsumerState<ModelManagementScreen> {
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

  Widget _buildHfTokenSection(BuildContext context, ThemeData theme) {
    final t = Translations.of(context);
    final settings = ref.read(settingsControllerProvider);
    final tokenController = TextEditingController(text: settings.hfToken);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.vpn_key_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.settings.modelManagement.hfToken,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                t.settings.modelManagement.hfTokenHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'hf_...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save_outlined, size: 20),
                    onPressed: () async {
                      final token = tokenController.text.trim();
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .updateSettings(
                            settings.copyWith(hfToken: token),
                            reloadModel: false,
                          );
                      if (context.mounted) {
                        showSuccessSnackBar(
                          context,
                          t.settings.modelManagement.hfTokenSaved,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstalledModelCard(AvailableModel model) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.check_circle, color: Colors.green.shade600),
        title: Text(model.name, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: _buildModelChips(model, theme),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          tooltip: t.settings.deleteModelTitle,
          onPressed: () => _confirmDeleteModel(model),
        ),
      ),
    );
  }

  Widget _buildAvailableModelCard(AvailableModel model) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Card.outlined(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.cloud_download_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(model.name),
        subtitle: _buildModelChips(model, theme),
        trailing: FilledButton.tonalIcon(
          icon: const Icon(Icons.download, size: 18),
          label: Text(t.settings.modelManagement.download),
          onPressed: () => _showDownloadDialog(model),
        ),
      ),
    );
  }

  Widget _buildModelChips(AvailableModel model, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (model.isRecommended)
            _buildChip(
              Icons.star_outline,
              t.common.recommended,
              theme.colorScheme.tertiary,
            ),
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

  void _confirmDeleteModel(AvailableModel model) {
    final t = Translations.of(context);
    final currentSettings = ref.read(settingsControllerProvider);

    if (currentSettings.selectedModel == model.id) {
      showErrorSnackBar(
        context,
        t.settings.modelManagement.cannotDeleteActiveModel,
      );
      return;
    }

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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(modelDownloaderProvider.notifier)
                    .deleteModel(model);
                if (mounted) {
                  showSuccessSnackBar(context, t.settings.modelDeleted);
                }
              } catch (e) {
                if (mounted) {
                  showErrorSnackBar(context, e.toString());
                }
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(AvailableModel model) {
    final settings = ref.read(settingsControllerProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DownloadModelDialog(
        model: model,
        currentSettings: settings,
        onDownloaded: () {
          ref.invalidate(isModelInstalledProvider(model.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    final installedModels = kAvailableModels.where((m) {
      return ref.watch(isModelInstalledProvider(m.id)).value == true;
    }).toList();

    final availableModels = kAvailableModels.where((m) {
      return ref.watch(isModelInstalledProvider(m.id)).value != true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.modelManagement.title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildHfTokenSection(context, theme),

          const SizedBox(height: 8),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          if (installedModels.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              t.settings.modelManagement.installedModels,
              Icons.download_done_outlined,
            ),
            ...installedModels.map((model) => _buildInstalledModelCard(model)),
            const SizedBox(height: 8),
            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 8),
          ],

          _buildSectionHeader(
            context,
            t.settings.modelManagement.availableModels,
            Icons.cloud_download_outlined,
          ),
          if (availableModels.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  t.settings.modelManagement.allModelsDownloaded,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...availableModels.map((model) => _buildAvailableModelCard(model)),

          const SizedBox(height: 16),
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

          const SizedBox(height: 32),
        ],
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
