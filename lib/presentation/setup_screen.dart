import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';
import 'package:local_assistant/router/app_router.dart';

import '../application/model_manager_provider.dart';
import '../application/settings_provider.dart';
import '../core/logger.dart';
import '../domain/models.dart';
import '../infrastructure/llm_service.dart';
import 'settings_screen.dart';

@RoutePage()
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late AppSettings _draftSettings;
  bool _isChecking = true;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    appLogger.i("SetupScreen: Checking initial state...");
    final settings = ref.read(settingsControllerProvider);
    bool anyInstalled = false;
    String? firstInstalledId;

    for (var model in kAvailableModels) {
      if (await FlutterGemma.isModelInstalled(model.fileName)) {
        anyInstalled = true;
        firstInstalledId ??= model.id;
      }
    }

    if (anyInstalled) {
      appLogger.i(
        "SetupScreen: Found installed model. Proceeding to initialization.",
      );
      if (!(await FlutterGemma.isModelInstalled(
        kAvailableModels
            .firstWhere((m) => m.id == settings.selectedModel)
            .fileName,
      ))) {
        await ref
            .read(settingsControllerProvider.notifier)
            .updateSettings(
              settings.copyWith(selectedModel: firstInstalledId),
              reloadModel: false,
            );
      }

      try {
        await ref
            .read(llmServiceProvider)
            .initModel(ref.read(settingsControllerProvider));
      } catch (e) {
        appLogger.e("SetupScreen: Error during initModel", error: e);
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

  Future<void> _finishSetup() async {
    setState(() => _isInitializing = true);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(_draftSettings, reloadModel: false);
      await ref.read(llmServiceProvider).initModel(_draftSettings);
      if (mounted) context.router.replace(const ChatRoute());
    } catch (e) {
      appLogger.e("SetupScreen: Error applying model", error: e);
      setState(() => _isInitializing = false);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    if (_isChecking || _isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _isChecking ? t.setup.checkingSystem : t.setup.startingModel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
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
                              model.name,
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
                        subtitle: isInstalledAsync.when(
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
                        trailing: isInstalledAsync.value == true
                            ? (isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: theme.colorScheme.primary,
                                    )
                                  : const Icon(Icons.circle_outlined))
                            : FilledButton.icon(
                                icon: const Icon(Icons.download, size: 18),
                                label: Text(t.setup.get),
                                onPressed: () => _showDownloadDialog(model),
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
