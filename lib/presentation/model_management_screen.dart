import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/device_info_provider.dart';
import '../application/model_manager_provider.dart';
import '../application/settings_provider.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';
import '../domain/models.dart';
import '../i18n/generated/translations.g.dart';

// Displays real on-device storage usage from flutter_gemma's facade
// (StorageStats) and offers a one-tap cleanup of orphaned download
// fragments via the facade's storage helpers.
class StorageInfoCard extends ConsumerStatefulWidget {
  const StorageInfoCard({super.key});

  @override
  ConsumerState<StorageInfoCard> createState() => _StorageInfoCardState();
}

class _StorageInfoCardState extends ConsumerState<StorageInfoCard> {
  StorageStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await FlutterGemma.getStorageInfo();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e, st) {
      appLogger.e("Failed to load storage info", error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cleanupOrphans() async {
    final t = Translations.of(context);
    try {
      final orphans = await FlutterGemma.getOrphanedFiles();
      if (orphans.isEmpty) {
        if (mounted) showInfoSnackBar(context, t.settings.noOrphanedFiles);
        await _refresh();
        return;
      }
      final removed = await FlutterGemma.cleanupStorage();
      if (mounted) {
        showSuccessSnackBar(
          context,
          t.settings.freedUpStorage(count: removed),
        );
      }
      await _refresh();
    } catch (e, st) {
      appLogger.e("Storage cleanup failed", error: e, stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context, t.settings.cleanupFailed(error: e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(t.settings.storageManagement),
                ],
              )
            : _error != null
            ? Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.settings.storageManagement,
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: t.common.refresh,
                        icon: const Icon(Icons.refresh),
                        onPressed: _refresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _statRow(
                    theme,
                    Icons.sd_storage_outlined,
                    t.settings.modelManagement.installedModels,
                    _formatMb(_stats?.totalSizeMB ?? 0),
                  ),
                  const SizedBox(height: 4),
                  _statRow(
                    theme,
                    Icons.cleaning_services_outlined,
                    t.settings.orphanedFiles,
                    '${_stats?.orphanedFiles.length ?? 0} (${_formatMb(_stats?.orphanedSizeMB ?? 0)})',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _cleanupOrphans,
                    icon: const Icon(Icons.cleaning_services),
                    label: Text(t.settings.cleanUpStorage),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatMb(double mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }
}

// Screen for managing local LLM assets: downloading, deleting, and configuring auth tokens.
// Validates storage space before downloads and provides cleanup tools for orphaned files.
@RoutePage()
class ModelManagementScreen extends ConsumerStatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  ConsumerState<ModelManagementScreen> createState() =>
      _ModelManagementScreenState();
}

class _ModelManagementScreenState extends ConsumerState<ModelManagementScreen> {
  // Formats megabytes into a human-readable string (MB or GB).
  String _formatSize(int sizeMb) {
    if (sizeMb >= 1024) {
      return '${(sizeMb / 1024).toStringAsFixed(1)} GB';
    }
    return '$sizeMb MB';
  }

  // Maps a typed flutter_gemma DownloadError to a localized, user-facing
  // message. Falls back to the raw error string for anything unexpected.
  String _localizeDownloadError(DownloadError error) {
    final t = Translations.of(context);
    final errors = t.settings.downloadErrors;
    return switch (error) {
      UnauthorizedError() => errors.unauthorized,
      ForbiddenError() => errors.forbidden,
      NotFoundError() => errors.notFound,
      RateLimitedError() => errors.rateLimited,
      ServerError(:final statusCode) => errors.serverError(statusCode: statusCode),
      NetworkError(:final message) => errors.network(message: message),
      CanceledError() => errors.canceled,
      UnknownError(:final message) => errors.unknown(message: message),
    };
  }

  // Renders a consistent section header with an icon and title for grouping UI elements.
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

  // Renders the HuggingFace token input field for gated model authentication.
  // Wraps the save operation in try/catch to notify the user if persistence fails.
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
                  hintText: t.settings.modelManagement.hfTokenPlaceholder,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save_outlined, size: 20),
                    onPressed: () async {
                      final token = tokenController.text.trim();
                      try {
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
                      } catch (e, st) {
                        appLogger.e(
                          "Failed to save HF token",
                          error: e,
                          stackTrace: st,
                        );
                        if (context.mounted) {
                          showErrorSnackBar(
                            context,
                            t.errors.failedToSaveToken,
                          );
                        }
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

  // Renders a card for an installed model with a delete action.
  Widget _buildInstalledModelCard(AvailableModel model) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.check_circle, color: Colors.green.shade600),
        title: Text(
          '${model.name} (${_formatSize(model.sizeMb)})',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: _buildModelChips(model, theme),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          tooltip: t.settings.deleteModelTitle,
          onPressed: () => _confirmDeleteModel(model),
        ),
      ),
    );
  }

  // Initiates the model download process after validating storage space and auth tokens.
  // Wraps the download call in try/catch to show error snackbars if the network or file system fails.
  void _startDownload(AvailableModel model) async {
    final t = Translations.of(context);
    final settings = ref.read(settingsControllerProvider);

    if (model.requiresAuth && settings.hfToken.isEmpty) {
      showErrorSnackBar(context, t.errors.tokenRequired);
      return;
    }

    final freeBytes = await ref.read(freeStorageBytesProvider.future);
    final requiredBytes =
        (model.sizeMb * 1024 * 1024) + (1024 * 1024 * 1024); // 1GB buffer

    if (freeBytes != -1 && freeBytes < requiredBytes) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.settings.storageSpaceWarning),
          content: Text(
            t.settings.notEnoughSpace(
              required: (requiredBytes / 1024 / 1024 / 1024).toStringAsFixed(1),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  // Facade-level cleanup (orphaned download fragments).
                  await FlutterGemma.cleanupStorage();
                  if (mounted) {
                    showSuccessSnackBar(
                      context,
                      t.settings.cleanUpStorageAttempted,
                    );
                  }
                } catch (e) {
                  appLogger.e("Storage cleanup failed", error: e);
                  if (mounted) {
                    showErrorSnackBar(context, t.settings.cleanUpStorageFailed);
                  }
                }
              },
              child: Text(t.settings.cleanUpStorage),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await ref
          .read(modelDownloaderProvider.notifier)
          .download(model, settings.hfToken);
    } catch (e, st) {
      appLogger.e("Failed to start model download", error: e, stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context, t.errors.operationFailed);
      }
    }
  }

  // Renders a card for an available model with download/resume buttons and progress indicators.
  Widget _buildAvailableModelCard(AvailableModel model) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final downloadState =
        ref.watch(modelDownloaderProvider)[model.id] ?? const DownloadStatus();

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(
              Icons.cloud_download_outlined,
              color: theme.colorScheme.primary,
            ),
            title: Text('${model.name} (${_formatSize(model.sizeMb)})'),
            subtitle: _buildModelChips(model, theme),
            trailing: downloadState.isDownloading
                ? null
                : downloadState.isPaused
                ? FilledButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(t.settings.modelManagement.resume),
                    onPressed: () => _startDownload(model),
                  )
                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(t.settings.modelManagement.download),
                    onPressed: () => _startDownload(model),
                  ),
          ),
          if (downloadState.isDownloading || downloadState.isPaused)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: downloadState.progress / 100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${downloadState.progress}%',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (downloadState.estimatedTimeRemaining > 0 &&
                          !downloadState.isPaused)
                        Text(
                          '~${(downloadState.estimatedTimeRemaining / 60).toStringAsFixed(1)} ${t.settings.modelManagement.minsLeft}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (downloadState.isPaused)
                        Text(
                          downloadState.error != null
                              ? _localizeDownloadError(downloadState.error!)
                              : t.settings.modelManagement.paused,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Generates a row of feature chips (Images, Audio, Thinking) for a given model.
  Widget _buildModelChips(AvailableModel model, ThemeData theme) {
    final t = Translations.of(context);
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

  // Renders a single feature chip with an icon and label.
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

  // Opens a confirmation dialog and securely attempts to delete an installed model.
  // Wraps the deletion in try/catch to notify the user if the file system operation fails.
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
              } catch (e, st) {
                appLogger.e(
                  "Failed to delete model ${model.name}",
                  error: e,
                  stackTrace: st,
                );
                if (mounted) {
                  showErrorSnackBar(context, t.errors.failedToDeleteModel);
                }
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  // Builds the main scrollable layout containing token input, installed models, available models, and storage cleanup.
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
          const StorageInfoCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
