import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/logger.dart';
import '../domain/models.dart';
import '../i18n/generated/translations.g.dart';
import '../infrastructure/hive_service.dart';
import '../infrastructure/llm_service.dart';
import 'chat_provider.dart';

part 'settings_provider.g.dart';

// Controller providing active system settings and profile configs.
// Manages persistence, localization, and model re-initialization when settings change.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  // Saves new settings to storage, reloads translation keys, and restarts the model context.
  // Rethrows errors if model reloading fails so the UI can notify the user.
  Future<void> updateSettings(
    AppSettings newSettings, {
    bool reloadModel = true,
  }) async {
    try {
      if (state.locale != newSettings.locale) {
        if (newSettings.locale.isEmpty) {
          LocaleSettings.useDeviceLocale();
        } else {
          try {
            LocaleSettings.setLocaleRaw(newSettings.locale);
          } catch (e) {
            appLogger.w(
              "Requested locale unrecognized, falling back to system default",
              error: e,
            );
            LocaleSettings.useDeviceLocale();
          }
        }
      }

      state = newSettings;
      final hiveService = ref.read(hiveServiceProvider);
      await hiveService.saveSettings(newSettings);

      final activeId = hiveService.getActiveConfigurationId();
      final activeConfig = hiveService.getConfiguration(activeId);
      if (activeConfig != null && !activeConfig.isReadOnly) {
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
        } catch (e, st) {
          appLogger.e(
            "Failed to reload model configuration",
            error: e,
            stackTrace: st,
          );
          throw Exception("Failed to apply model settings: $e");
        }
      }

      final currentSessionId = ref
          .read(chatLogicProvider.notifier)
          .currentSessionId;
      await ref.read(chatLogicProvider.notifier).loadSession(currentSessionId);
    } catch (e, st) {
      appLogger.e(
        "Failed to completely update settings profile",
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // Switches active profile config and re-loads model parameters.
  // Rethrows errors so the UI can show a snackbar if the switch fails.
  Future<void> switchConfiguration(String configId) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final config = hiveService.getConfiguration(configId);
      if (config == null) throw Exception("Configuration not found");

      await hiveService.setActiveConfigurationId(configId);
      final newSettings = config.applyToSettings(state);
      await updateSettings(newSettings, reloadModel: true);
    } catch (e, st) {
      appLogger.e(
        "Failed to switch configuration profile to $configId",
        error: e,
        stackTrace: st,
      );
      rethrow; // UI must handle this
    }
  }

  // Registers a brand new custom config parameter profile.
  // Rethrows errors so the UI can notify the user if creation fails.
  Future<SettingConfiguration> addConfiguration(
    String name, {
    bool copyCurrent = true,
  }) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final id = const Uuid().v4();
      final SettingConfiguration newConfig;
      if (copyCurrent) {
        newConfig = SettingConfiguration.fromSettings(
          state,
          id: id,
          name: name,
        );
      } else {
        newConfig = SettingConfiguration(id: id, name: name);
      }
      await hiveService.saveConfiguration(newConfig);
      await switchConfiguration(id);
      return newConfig;
    } catch (e, st) {
      appLogger.e(
        "Failed to create configuration $name",
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // Saves a configuration profile imported from disk.
  // Rethrows errors so the UI can notify the user of import failure.
  Future<void> addImportedConfiguration(SettingConfiguration config) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      await hiveService.saveConfiguration(config);
      await switchConfiguration(config.id);
    } catch (e, st) {
      appLogger.e(
        "Failed to import configuration: ${config.id}",
        error: e,
        stackTrace: st,
      );
      rethrow; // UI must handle this
    }
  }

  // Duplicates an existing configuration profile.
  // Rethrows errors so the UI can notify the user if duplication fails.
  Future<void> duplicateConfiguration(SettingConfiguration config) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final id = const Uuid().v4();
      final newConfig = config.copyWith(
        id: id,
        name: '${config.name} (Copy)',
        isReadOnly: false,
      );
      await hiveService.saveConfiguration(newConfig);
      await switchConfiguration(id);
    } catch (e, st) {
      appLogger.e(
        "Failed to duplicate configuration ${config.name}",
        error: e,
        stackTrace: st,
      );
      rethrow; // UI must handle this
    }
  }

  // Locks or unlocks a configuration profile from user edits.
  // Rethrows errors so the UI can notify the user if the toggle fails.
  Future<void> toggleReadOnly(String id, bool isReadOnly) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final config = hiveService.getConfiguration(id);
      if (config == null) throw Exception("Configuration not found");

      final updated = config.copyWith(isReadOnly: isReadOnly);
      await hiveService.saveConfiguration(updated);
      ref.invalidateSelf();
    } catch (e, st) {
      appLogger.e(
        "Failed to toggle read-only status for $id",
        error: e,
        stackTrace: st,
      );
      rethrow; // UI must handle this
    }
  }

  // Renames a user-created configuration profile.
  // Rethrows errors so the UI can notify the user if the rename fails.
  Future<void> renameConfiguration(String id, String newName) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final config = hiveService.getConfiguration(id);
      if (config == null) throw Exception("Configuration not found");

      final updated = config.copyWith(name: newName);
      await hiveService.saveConfiguration(updated);
    } catch (e, st) {
      appLogger.e(
        "Failed to rename configuration $id to $newName",
        error: e,
        stackTrace: st,
      );
      rethrow; // UI must handle this
    }
  }

  // Deletes a target configuration profile, shifting the active profile to the fallback.
  // Rethrows errors so the UI can notify the user if the deletion fails.
  Future<bool> deleteConfiguration(String id) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final configs = hiveService.getAllConfigurations();
      if (configs.length <= 1) {
        throw Exception("Cannot delete the last configuration");
      }

      await hiveService.deleteConfiguration(id);
      if (hiveService.getActiveConfigurationId() == id) {
        final remaining = hiveService.getAllConfigurations();
        if (remaining.isNotEmpty) {
          await switchConfiguration(remaining.first.id);
        }
      }
      return true;
    } catch (e, st) {
      appLogger.e(
        "Failed to delete configuration profile $id",
        error: e,
        stackTrace: st,
      );
      rethrow; // UI must handle this
    }
  }

  // Reads and returns all config profiles from Hive DB.
  // Returns an empty list if the database read fails to prevent UI crashes.
  List<SettingConfiguration> getConfigurations() {
    try {
      return ref.read(hiveServiceProvider).getAllConfigurations();
    } catch (e, st) {
      appLogger.e("Failed to fetch profiles from DB", error: e, stackTrace: st);
      return [];
    }
  }

  // Returns the active configuration ID.
  // Falls back to 'default' if the read fails or no ID is set.
  String getActiveConfigurationId() {
    try {
      return ref.read(hiveServiceProvider).getActiveConfigurationId();
    } catch (e, st) {
      appLogger.e(
        "Failed to load active configuration ID",
        error: e,
        stackTrace: st,
      );
      return 'default';
    }
  }

  // Returns the resolved configuration profile mapped to the active ID.
  // Returns null if the profile doesn't exist or parsing fails.
  SettingConfiguration? getActiveConfiguration() {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final activeId = hiveService.getActiveConfigurationId();
      return hiveService.getConfiguration(activeId);
    } catch (e, st) {
      appLogger.e(
        "Error loading active configuration profile details",
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  // Initializes the provider state by loading settings and applying the active config.
  // Returns default settings if the database read fails to ensure app stability.
  @override
  AppSettings build() {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      var settings = hiveService.getSettings();
      final activeId = hiveService.getActiveConfigurationId();
      final activeConfig = hiveService.getConfiguration(activeId);
      if (activeConfig != null) {
        settings = activeConfig.applyToSettings(settings);
      }
      return settings;
    } catch (e, st) {
      appLogger.e(
        "Failed to build base Settings state",
        error: e,
        stackTrace: st,
      );
      return AppSettings();
    }
  }
}
