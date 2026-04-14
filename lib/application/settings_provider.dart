import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/models.dart';
import '../infrastructure/hive_service.dart';
import '../infrastructure/llm_service.dart';
import 'chat_provider.dart';

part 'settings_provider.g.dart';

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  Future<void> updateSettings(
    AppSettings newSettings, {
    bool reloadModel = true,
  }) async {
    state = newSettings;
    await ref.read(hiveServiceProvider).saveSettings(newSettings);

    if (reloadModel) {
      try {
        await ref.read(llmServiceProvider).initModel(newSettings);
      } catch (e) {
        throw Exception("Failed to apply model settings: $e");
      }
    }

    final currentSessionId = ref
        .read(chatLogicProvider.notifier)
        .currentSessionId;
    await ref.read(chatLogicProvider.notifier).loadSession(currentSessionId);
  }

  @override
  AppSettings build() {
    return ref.read(hiveServiceProvider).getSettings();
  }
}
