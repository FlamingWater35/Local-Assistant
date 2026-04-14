import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/router/app_router.dart';

import '../application/settings_provider.dart';
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
      if (!(await FlutterGemma.isModelInstalled(
        kAvailableModels
            .firstWhere((m) => m.id == settings.selectedModel)
            .fileName,
      ))) {
        await ref
            .read(settingsControllerProvider.notifier)
            .updateSettings(
              settings.copyWith(selectedModel: firstInstalledId!),
              reloadModel: false,
            );
      }

      ref
          .read(llmServiceProvider)
          .initModel(ref.read(settingsControllerProvider))
          .catchError((_) {});

      if (mounted) context.router.replace(const ChatRoute());
    } else {
      if (mounted) context.router.replace(const SettingsRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Checking Model Status..."),
          ],
        ),
      ),
    );
  }
}
