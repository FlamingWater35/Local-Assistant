import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../i18n/generated/translations.g.dart';
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
    if (state.locale != newSettings.locale) {
      if (newSettings.locale.isEmpty) {
        LocaleSettings.useDeviceLocale();
      } else {
        try {
          LocaleSettings.setLocaleRaw(newSettings.locale);
        } catch (_) {
          LocaleSettings.useDeviceLocale();
        }
      }
    }

    state = newSettings;
    await ref.read(hiveServiceProvider).saveSettings(newSettings);

    final hiveService = ref.read(hiveServiceProvider);
    final activeId = hiveService.getActiveConfigurationId();
    final activeConfig = hiveService.getConfiguration(activeId);
    if (activeConfig != null) {
      final updatedConfig = SettingConfiguration.fromSettings(
        newSettings,
        id: activeConfig.id,
        name: activeConfig.name,
      );
      await hiveService.saveConfiguration(updatedConfig);
    }

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

  Future<void> switchConfiguration(String configId) async {
    final hiveService = ref.read(hiveServiceProvider);
    final config = hiveService.getConfiguration(configId);
    if (config == null) return;

    await hiveService.setActiveConfigurationId(configId);

    final newSettings = config.applyToSettings(state);
    await updateSettings(newSettings, reloadModel: true);
  }

  Future<SettingConfiguration> addConfiguration(
    String name, {
    bool copyCurrent = true,
  }) async {
    final hiveService = ref.read(hiveServiceProvider);
    final id = const Uuid().v4();

    final SettingConfiguration newConfig;
    if (copyCurrent) {
      newConfig = SettingConfiguration.fromSettings(state, id: id, name: name);
    } else {
      newConfig = SettingConfiguration(id: id, name: name);
    }

    await hiveService.saveConfiguration(newConfig);
    await switchConfiguration(id);
    return newConfig;
  }

  Future<void> renameConfiguration(String id, String newName) async {
    final hiveService = ref.read(hiveServiceProvider);
    final config = hiveService.getConfiguration(id);
    if (config == null) return;
    final updated = config.copyWith(name: newName);
    await hiveService.saveConfiguration(updated);
  }

  Future<bool> deleteConfiguration(String id) async {
    final hiveService = ref.read(hiveServiceProvider);
    final configs = hiveService.getAllConfigurations();
    if (configs.length <= 1) return false;

    await hiveService.deleteConfiguration(id);

    if (hiveService.getActiveConfigurationId() == id) {
      final remaining = hiveService.getAllConfigurations();
      if (remaining.isNotEmpty) {
        await switchConfiguration(remaining.first.id);
      }
    }
    return true;
  }

  List<SettingConfiguration> getConfigurations() {
    return ref.read(hiveServiceProvider).getAllConfigurations();
  }

  String getActiveConfigurationId() {
    return ref.read(hiveServiceProvider).getActiveConfigurationId();
  }

  SettingConfiguration? getActiveConfiguration() {
    final hiveService = ref.read(hiveServiceProvider);
    final activeId = hiveService.getActiveConfigurationId();
    return hiveService.getConfiguration(activeId);
  }

  @override
  AppSettings build() {
    final hiveService = ref.read(hiveServiceProvider);
    var settings = hiveService.getSettings();

    final activeId = hiveService.getActiveConfigurationId();
    final activeConfig = hiveService.getConfiguration(activeId);
    if (activeConfig != null) {
      settings = activeConfig.applyToSettings(settings);
    }

    return settings;
  }
}
