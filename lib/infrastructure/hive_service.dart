import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:local_assistant/infrastructure/adapters/preferred_backend_adapter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logger.dart';
import '../domain/models.dart';

part 'hive_service.g.dart';

// Provides synchronized read/write access to the local Hive database for user settings and chat histories
class HiveService {
  late final Box<String> _configurationsBox;
  late final Box<ChatSession> _sessionsBox;
  late final Box<AppSettings> _settingsBox;

  // Initializes Flutter Hive Engine and opens all needed configuration boxes
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(AppSettingsAdapter());
      Hive.registerAdapter(LocalChatMessageAdapter());
      Hive.registerAdapter(ChatSessionAdapter());
      Hive.registerAdapter(LocalAttachmentAdapter());
      Hive.registerAdapter(PreferredBackendAdapter());

      _settingsBox = await Hive.openBox<AppSettings>('settingsBox');
      _sessionsBox = await Hive.openBox<ChatSession>('sessionsBox');
      _configurationsBox = await Hive.openBox<String>('configurationsBox');

      _migrateConfigurations();
      appLogger.i("💡 Hive Initialized");
    } catch (e, st) {
      appLogger.e(
        "🚨 Failed to initialize Hive Service",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Returns the core application settings, falling back to default if uninitialized
  AppSettings getSettings() {
    try {
      final s = _settingsBox.get('app_settings');
      return s ?? AppSettings();
    } catch (e) {
      appLogger.e("Error reading settings from Hive", error: e);
      return AppSettings();
    }
  }

  // Writes AppSettings to Hive storage securely
  Future<void> saveSettings(AppSettings settings) async {
    try {
      await _settingsBox.put('app_settings', settings);
    } catch (e, st) {
      appLogger.e(
        "Failed to persist AppSettings to Hive",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Retrieves all ChatSessions sorted by the last updated time (newest first)
  List<ChatSession> getAllSessions() {
    try {
      final sessions = _sessionsBox.values.toList();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      appLogger.e("Error fetching all ChatSessions", error: e);
      return [];
    }
  }

  // Gets a specific chat session by its UUID
  ChatSession? getSession(String id) {
    try {
      return _sessionsBox.get(id);
    } catch (e) {
      appLogger.e("Error fetching ChatSession ID: $id", error: e);
      return null;
    }
  }

  // Commits a ChatSession object to Hive memory
  Future<void> saveSession(ChatSession session) async {
    try {
      await _sessionsBox.put(session.id, session);
    } catch (e, st) {
      appLogger.e(
        "Failed to save ChatSession ID: ${session.id}",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Deletes an entire ChatSession map
  Future<void> deleteSession(String id) async {
    try {
      await _sessionsBox.delete(id);
    } catch (e, st) {
      appLogger.e(
        "Failed to delete ChatSession ID: $id",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Gets the currently active config Profile ID
  String getActiveConfigurationId() {
    try {
      return _configurationsBox.get('active_id', defaultValue: 'default')!;
    } catch (e) {
      appLogger.e("Failed to read active config ID", error: e);
      return 'default';
    }
  }

  // Sets the system's active Configuration Profile ID
  Future<void> setActiveConfigurationId(String id) async {
    try {
      await _configurationsBox.put('active_id', id);
    } catch (e, st) {
      appLogger.e(
        "Failed to save active config ID: $id",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Parses and returns all available configuration profiles
  List<SettingConfiguration> getAllConfigurations() {
    try {
      return _configurationsBox.keys
          .where((key) => key is String && key.startsWith('cfg_'))
          .map((key) {
            final jsonStr = _configurationsBox.get(key);
            if (jsonStr != null) {
              try {
                return SettingConfiguration.fromJson(
                  Map<String, dynamic>.from(jsonDecode(jsonStr)),
                );
              } catch (e) {
                appLogger.e("Failed to parse configuration $key", error: e);
                return null;
              }
            }
            return null;
          })
          .whereType<SettingConfiguration>()
          .toList();
    } catch (e) {
      appLogger.e("Error fetching all configurations", error: e);
      return [];
    }
  }

  // Returns a distinct configuration profile if found
  SettingConfiguration? getConfiguration(String id) {
    try {
      final jsonStr = _configurationsBox.get('cfg_$id');
      if (jsonStr != null) {
        return SettingConfiguration.fromJson(
          Map<String, dynamic>.from(jsonDecode(jsonStr)),
        );
      }
    } catch (e) {
      appLogger.e("Failed to parse configuration $id", error: e);
    }
    return null;
  }

  // Serializes and stores a specific SettingConfiguration
  Future<void> saveConfiguration(SettingConfiguration config) async {
    try {
      await _configurationsBox.put(
        'cfg_${config.id}',
        jsonEncode(config.toJson()),
      );
    } catch (e, st) {
      appLogger.e(
        "Failed to save Configuration ${config.id}",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Hard deletes a user's configuration parameter
  Future<void> deleteConfiguration(String id) async {
    try {
      await _configurationsBox.delete('cfg_$id');
    } catch (e, st) {
      appLogger.e(
        "Failed to delete Configuration $id",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Gets the currently interrupted model download ID for UI state tracking
  String? getInterruptedDownload() {
    try {
      return _configurationsBox.get('interrupted_download');
    } catch (e) {
      return null;
    }
  }

  // Retrieves the integer percentage of progress for an interrupted download
  int getInterruptedDownloadProgress() {
    try {
      final val = _configurationsBox.get('interrupted_download_progress');
      return val != null ? int.tryParse(val) ?? 0 : 0;
    } catch (e) {
      return 0;
    }
  }

  // Updates or clears the interrupted download tracking flags
  Future<void> setInterruptedDownload(String? id, [int progress = 0]) async {
    try {
      if (id == null) {
        await _configurationsBox.delete('interrupted_download');
        await _configurationsBox.delete('interrupted_download_progress');
      } else {
        await _configurationsBox.put('interrupted_download', id);
        await _configurationsBox.put(
          'interrupted_download_progress',
          progress.toString(),
        );
      }
    } catch (e, st) {
      appLogger.e(
        "Failed to record interrupted download status",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Auto-populates the default parameter profile into Hive on initial launch
  void _migrateConfigurations() {
    try {
      if (_configurationsBox.get('active_id') == null) {
        final settings = getSettings();
        final defaultConfig = SettingConfiguration.fromSettings(
          settings,
          id: 'default',
          name: 'Default',
          isReadOnly: true,
        );
        saveConfiguration(defaultConfig);
        _configurationsBox.put('active_id', 'default');
        appLogger.i("💡 Created default configuration from existing settings");
      }
    } catch (e, st) {
      appLogger.e("Error migrating configurations", error: e, stackTrace: st);
    }
  }
}

@Riverpod(keepAlive: true)
HiveService hiveService(Ref ref) =>
    throw UnimplementedError('Initialized in main.dart');
