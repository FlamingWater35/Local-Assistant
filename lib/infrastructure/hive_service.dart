import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logger.dart';
import '../domain/models.dart';

part 'hive_service.g.dart';

class HiveService {
  late final Box<AppSettings> _settingsBox;
  late final Box<ChatSession> _sessionsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(LocalChatMessageAdapter());
    Hive.registerAdapter(ChatSessionAdapter());

    _settingsBox = await Hive.openBox<AppSettings>('settingsBox');
    _sessionsBox = await Hive.openBox<ChatSession>('sessionsBox');
    appLogger.i("Hive Initialized");
  }

  AppSettings getSettings() =>
      _settingsBox.get('app_settings') ?? AppSettings();

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('app_settings', settings);
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
}

@Riverpod(keepAlive: true)
HiveService hiveService(Ref ref) =>
    throw UnimplementedError('Initialized in main.dart');
