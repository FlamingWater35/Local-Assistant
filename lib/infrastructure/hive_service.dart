import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:local_assistant/infrastructure/adapters/preferred_backend_adapter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logger.dart';
import '../domain/models.dart';

part 'hive_service.g.dart';

class HiveService {
  late final Box<String> _configurationsBox;
  late final Box<ChatSession> _sessionsBox;
  late final Box<AppSettings> _settingsBox;

  Future<void> init() async {
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
  }

  AppSettings getSettings() {
    final s = _settingsBox.get('app_settings');
    appLogger.i(
      "📂 Loaded Settings from Hive: GlobalMemory=${s?.enableGlobalMemory}",
    );
    return s ?? AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    appLogger.i("💾 Saving settings to Hive DB...");
    await _settingsBox.put('app_settings', settings);
    appLogger.i("✅ Settings successfully persisted.");
  }

  List<ChatSession> getAllSessions() {
    final sessions = _sessionsBox.values.toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  ChatSession? getSession(String id) => _sessionsBox.get(id);

  Future<void> saveSession(ChatSession session) async {
    await _sessionsBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
  }

  String getActiveConfigurationId() {
    return _configurationsBox.get('active_id', defaultValue: 'default')!;
  }

  Future<void> setActiveConfigurationId(String id) async {
    await _configurationsBox.put('active_id', id);
  }

  List<SettingConfiguration> getAllConfigurations() {
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
  }

  SettingConfiguration? getConfiguration(String id) {
    final jsonStr = _configurationsBox.get('cfg_$id');
    if (jsonStr != null) {
      try {
        return SettingConfiguration.fromJson(
          Map<String, dynamic>.from(jsonDecode(jsonStr)),
        );
      } catch (e) {
        appLogger.e("Failed to parse configuration $id", error: e);
        return null;
      }
    }
    return null;
  }

  Future<void> saveConfiguration(SettingConfiguration config) async {
    await _configurationsBox.put(
      'cfg_${config.id}',
      jsonEncode(config.toJson()),
    );
  }

  Future<void> deleteConfiguration(String id) async {
    await _configurationsBox.delete('cfg_$id');
  }

  String? getInterruptedDownload() {
    return _configurationsBox.get('interrupted_download');
  }

  int getInterruptedDownloadProgress() {
    final val = _configurationsBox.get('interrupted_download_progress');
    return val != null ? int.tryParse(val) ?? 0 : 0;
  }

  Future<void> setInterruptedDownload(String? id, [int progress = 0]) async {
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
  }

  void _migrateConfigurations() {
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
  }
}

@Riverpod(keepAlive: true)
HiveService hiveService(Ref ref) =>
    throw UnimplementedError('Initialized in main.dart');
