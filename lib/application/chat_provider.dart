import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/logger.dart';
import '../domain/models.dart';
import '../infrastructure/hive_service.dart';
import '../infrastructure/llm_service.dart';
import 'settings_provider.dart';

part 'chat_provider.g.dart';

@Riverpod(keepAlive: true)
class ChatHistory extends _$ChatHistory {
  void refresh() {
    state = ref.read(hiveServiceProvider).getAllSessions();
  }

  @override
  List<ChatSession> build() {
    return ref.watch(hiveServiceProvider).getAllSessions();
  }
}

@Riverpod(keepAlive: true)
class ChatLogic extends _$ChatLogic {
  String? currentSessionId;

  final _uuid = const Uuid();

  Future<void> loadSession(String? sessionId) async {
    currentSessionId = sessionId;

    final newController = core.InMemoryChatController();
    ChatSession? session;

    if (sessionId != null) {
      session = ref.read(hiveServiceProvider).getSession(sessionId);
      if (session != null) {
        for (final msg in session.messages) {
          newController.insertMessage(msg.toChatCoreType());
        }
      }
    }

    final settings = ref.read(settingsControllerProvider);
    await ref
        .read(llmServiceProvider)
        .loadSessionContext(session, settings.systemPrompt);

    state.dispose();
    state = newController;
  }

  Future<void> sendMessage(String text) async {
    final hiveService = ref.read(hiveServiceProvider);

    if (currentSessionId == null) {
      currentSessionId = _uuid.v4();
      final newSession = ChatSession(
        id: currentSessionId!,
        title: text.length > 25 ? '${text.substring(0, 25)}...' : text,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        messages: [],
      );
      await hiveService.saveSession(newSession);
      ref.read(chatHistoryProvider.notifier).refresh();
    }

    final userMsg = _createLocalMessage(text, 'user');
    _addMessageToStateAndDb(userMsg);

    final aiMsgId = _uuid.v4();
    var aiText = '';
    final aiMsg = _createLocalMessage(aiText, 'ai', id: aiMsgId);
    _addMessageToStateAndDb(aiMsg);

    try {
      final stream = ref.read(llmServiceProvider).generateResponseStream(text);
      await for (final chunk in stream) {
        aiText += chunk;
        _updateLocalMessage(aiMsgId, aiText);
      }
    } catch (e) {
      appLogger.e("Inference error", error: e);
      _updateLocalMessage(aiMsgId, "⚠️ Error: Model inference failed.");
    }
  }

  LocalChatMessage _createLocalMessage(
    String text,
    String authorId, {
    String? id,
  }) {
    return LocalChatMessage(
      id: id ?? _uuid.v4(),
      text: text,
      authorId: authorId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _addMessageToStateAndDb(LocalChatMessage msg) {
    state.insertMessage(msg.toChatCoreType());
    _saveSessionToHive();
  }

  void _updateLocalMessage(String id, String newText) {
    final index = state.messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      final oldCoreMsg = state.messages[index] as core.TextMessage;
      final newCoreMsg = core.TextMessage(
        id: oldCoreMsg.id,
        authorId: oldCoreMsg.authorId,
        createdAt: oldCoreMsg.createdAt,
        text: newText,
      );
      state.updateMessage(oldCoreMsg, newCoreMsg);
      _saveSessionToHive();
    }
  }

  void _saveSessionToHive() {
    if (currentSessionId == null) return;
    final hiveService = ref.read(hiveServiceProvider);
    final session = hiveService.getSession(currentSessionId!);
    if (session != null) {
      final currentLocalMessages = state.messages.map((m) {
        final tm = m as core.TextMessage;
        return LocalChatMessage(
          id: tm.id,
          text: tm.text,
          authorId: tm.authorId,
          createdAt:
              tm.createdAt?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();

      final updatedSession = session.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        messages: currentLocalMessages.reversed.toList(),
      );
      hiveService.saveSession(updatedSession);
      ref.read(chatHistoryProvider.notifier).refresh();
    }
  }

  @override
  core.InMemoryChatController build() {
    final controller = core.InMemoryChatController();
    ref.onDispose(() => controller.dispose());
    return controller;
  }
}
