import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/router/app_router.dart';

import '../application/settings_provider.dart';
import '../core/logger.dart';
import '../domain/models.dart';
import '../infrastructure/llm_service.dart';

@RoutePage()
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
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
      appLogger.w("SetupScreen: No models installed. Redirecting to Settings.");
      if (mounted) context.router.replace(const SettingsRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Checking Model Status..."),
            ],
          ),
        ),
      ),
    );
  }
}
