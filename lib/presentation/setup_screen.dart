import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';
import 'package:local_assistant/router/app_router.dart';

import '../application/device_info_provider.dart';
import '../application/model_manager_provider.dart';
import '../application/settings_provider.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';
import '../domain/models.dart';
import '../infrastructure/llm_service.dart';

// First-time setup onboarding flow screen allowing selection and download of initial local LLMs
@RoutePage()
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late AppSettings _draftSettings;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  String _formatSize(int sizeMb) {
    if (sizeMb >= 1024) {
      return '${(sizeMb / 1024).toStringAsFixed(1)} GB';
    }
    return '$sizeMb MB';
  }

  // Audits current platform file system to determine if there is an existing local model or initiates download flow
  Future<void> _checkInitialState() async {
    appLogger.i("SetupScreen: Checking initial state...");
    final settings = ref.read(settingsControllerProvider);
    bool anyInstalled = false;
    String? firstInstalledId;

    try {
      for (var model in kAvailableModels) {
        if (await FlutterGemma.isModelInstalled(model.fileName)) {
          anyInstalled = true;
          firstInstalledId ??= model.id;
        }
      }
    } catch (e, st) {
      appLogger.e(
        "Failed to check installed models during onboarding audit",
        error: e,
        stackTrace: st,
      );
    }

    if (anyInstalled) {
      appLogger.i("SetupScreen: Found installed model. Proceeding to Chat.");
      try {
        final currentModelInstalled = await FlutterGemma.isModelInstalled(
          kAvailableModels
              .firstWhere((m) => m.id == settings.selectedModel)
              .fileName,
        );
        if (!currentModelInstalled) {
          ref
              .read(settingsControllerProvider.notifier)
              .updateSettings(
                settings.copyWith(selectedModel: firstInstalledId),
                reloadModel: false,
              );
        }

        ref
            .read(llmServiceProvider)
            .initModel(ref.read(settingsControllerProvider));
      } catch (e, st) {
        appLogger.e(
          "Onboarding model pre-init failed, continuing anyway",
          error: e,
          stackTrace: st,
        );
      }

      if (mounted) context.router.replace(const ChatRoute());
    } else {
      appLogger.w("SetupScreen: No models installed. Presenting Welcome UI.");
      if (mounted) {
        setState(() {
          _isChecking = false;
          _draftSettings = settings;
        });
      }
    }
  }

  // Saves onboarding configuration and opens the main chat room interface
  Future<void> _finishSetup() async {
    try {
      ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(_draftSettings, reloadModel: false);
      ref.read(llmServiceProvider).initModel(_draftSettings);
      if (mounted) context.router.replace(const ChatRoute());
    } catch (e, st) {
      appLogger.e(
        "SetupScreen: Error applying model or transitioning",
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        showErrorSnackBar(context, t.errors.failedToStartModel);
      }
    }
  }

  // Prepares system and initiates the background model download workflow
  void _startDownload(AvailableModel model) async {
    final token = _draftSettings.hfToken;
    if (model.requiresAuth && token.isEmpty) {
      _showTokenDialog(model);
      return;
    }
    await _executeDownload(model, token);
  }

  // Opens secure dialog capturing HuggingFace tokens for gated models
  void _showTokenDialog(AvailableModel model) {
    final t = Translations.of(context);
    final controller = TextEditingController(text: _draftSettings.hfToken);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.download.hfTokenRequired),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.download.requiresAuth),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t.download.hfToken,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              final inputToken = controller.text.trim();
              if (inputToken.isNotEmpty) {
                Navigator.pop(ctx);
                setState(
                  () => _draftSettings = _draftSettings.copyWith(
                    hfToken: inputToken,
                  ),
                );
                _executeDownload(model, inputToken);
              }
            },
            child: Text(t.download.proceed),
          ),
        ],
      ),
    );
  }

  // Triggers the download manager provider with storage validation checks
  Future<void> _executeDownload(AvailableModel model, String token) async {
    final t = Translations.of(context);

    int freeBytes = -1;
    try {
      freeBytes = await ref.read(freeStorageBytesProvider.future);
    } catch (e) {
      appLogger.w(
        "Could not query disk space. Proceeding cautiously.",
        error: e,
      );
    }

    final requiredBytes = (model.sizeMb * 1024 * 1024) + (1024 * 1024 * 1024);
    if (freeBytes != -1 && freeBytes < requiredBytes) {
      if (!mounted) return;
      showErrorSnackBar(
        context,
        t.settings.notEnoughSpace(
          required: (requiredBytes / 1024 / 1024 / 1024).toStringAsFixed(1),
        ),
      );
      return;
    }

    try {
      await ref.read(modelDownloaderProvider.notifier).download(model, token);
    } catch (e, st) {
      appLogger.e(
        "Download init failed on onboarding screen",
        error: e,
        stackTrace: st,
      );
      if (mounted) showErrorSnackBar(context, t.errors.operationFailed);
    }
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

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    bool canContinue = false;
    for (var model in kAvailableModels) {
      if (ref.watch(isModelInstalledProvider(model.id)).value == true) {
        canContinue = true;
        break;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                t.setup.welcomeTitle,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.setup.welcomeSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                t.setup.availableModels,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: kAvailableModels.length,
                  itemBuilder: (context, index) {
                    final model = kAvailableModels[index];
                    final isInstalledAsync = ref.watch(
                      isModelInstalledProvider(model.id),
                    );
                    final isSelected = _draftSettings.selectedModel == model.id;
                    final downloadState =
                        ref.watch(modelDownloaderProvider)[model.id] ??
                        const DownloadStatus();

                    return Card.outlined(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              '${model.name} (${_formatSize(model.sizeMb)})',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
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
                            if (downloadState.isDownloading ||
                                downloadState.isPaused)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    LinearProgressIndicator(
                                      value: downloadState.progress / 100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${downloadState.progress}%',
                                          style: theme.textTheme.labelSmall,
                                        ),
                                        if (downloadState.isPaused)
                                          Text(
                                            t.settings.modelManagement.paused,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                          )
                                        else if (downloadState
                                                .estimatedTimeRemaining >
                                            0)
                                          Text(
                                            '~${(downloadState.estimatedTimeRemaining / 60).toStringAsFixed(1)}m',
                                            style: theme.textTheme.labelSmall,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            else
                              isInstalledAsync.when(
                                data: (installed) => Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    installed
                                        ? t.setup.downloaded
                                        : t.setup.tapToDownload,
                                    style: TextStyle(
                                      color: installed
                                          ? Colors.green.shade600
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                loading: () => Text(t.setup.checking),
                                error: (_, _) => Text(t.setup.error),
                              ),
                          ],
                        ),
                        trailing: downloadState.isDownloading
                            ? null
                            : downloadState.isPaused
                            ? FilledButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: Text(t.settings.modelManagement.resume),
                                onPressed: () => _startDownload(model),
                              )
                            : isInstalledAsync.value == true
                            ? (isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: theme.colorScheme.primary,
                                    )
                                  : const Icon(Icons.circle_outlined))
                            : FilledButton.icon(
                                icon: const Icon(Icons.download, size: 18),
                                label: Text(t.setup.get),
                                onPressed: () => _startDownload(model),
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
                  },
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canContinue ? _finishSetup : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    t.setup.startChatting,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
