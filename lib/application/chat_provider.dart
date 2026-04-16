import 'dart:async';

import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
class IsGenerating extends _$IsGenerating {
  void setGenerating(bool value) => state = value;

  @override
  bool build() => false;
}

@Riverpod(keepAlive: true)
class ChatLogic extends _$ChatLogic {
  String? currentSessionId;

  String? _activeGenerationSessionId;
  StreamSubscription? _generationSubscription;
  final Map<String, String> _pendingTextUpdates = {};
  Timer? _saveDebounceTimer;
  final _uuid = const Uuid();

  Future<void> loadSession(String? sessionId) async {
    await _cancelActiveGeneration();

    currentSessionId = sessionId;

    final newController = core.InMemoryChatController();
    ChatSession? session;

    if (sessionId != null) {
      session = ref.read(hiveServiceProvider).getSession(sessionId);
      if (session != null) {
        final sortedMessages = List<LocalChatMessage>.from(session.messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        for (final msg in sortedMessages) {
          newController.insertMessage(msg.toChatCoreType());
        }
      }
    }

    final settings = ref.read(settingsControllerProvider);
    final allSessions = ref.read(hiveServiceProvider).getAllSessions();

    final llmService = ref.read(llmServiceProvider);
    await Future.delayed(const Duration(milliseconds: 50));
    await llmService.loadSessionContext(session, settings, allSessions);

    state.dispose();
    state = newController;
  }

  Future<void> deleteSession(String sessionId) async {
    await _cancelActiveGeneration();
    await ref.read(hiveServiceProvider).deleteSession(sessionId);
    ref.read(chatHistoryProvider.notifier).refresh();

    if (currentSessionId == sessionId) {
      await loadSession(null);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (currentSessionId == null) return;

    final hiveService = ref.read(hiveServiceProvider);
    final session = hiveService.getSession(currentSessionId!);
    if (session == null) return;

    final coreMsg = state.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () =>
          core.TextMessage(id: '', text: '', authorId: '', createdAt: null),
    );
    if (coreMsg.id.isNotEmpty) {
      state.removeMessage(coreMsg);
    }

    final updatedMessages = session.messages
        .where((msg) => msg.id != messageId)
        .toList();

    final updatedSession = session.copyWith(
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      messages: updatedMessages,
    );
    await hiveService.saveSession(updatedSession);
    ref.read(chatHistoryProvider.notifier).refresh();

    final settings = ref.read(settingsControllerProvider);
    final allSessions = hiveService.getAllSessions();
    final llmService = ref.read(llmServiceProvider);

    await Future.delayed(const Duration(milliseconds: 50));
    await llmService.loadSessionContext(updatedSession, settings, allSessions);

    appLogger.i(
      "Message deleted from memory: $messageId from session: $currentSessionId",
    );
  }

  Future<void> sendMessage(
    String text, {
    List<ChatAttachment> attachments = const [],
  }) async {
    await _cancelActiveGeneration();

    final hiveService = ref.read(hiveServiceProvider);

    if (currentSessionId == null) {
      currentSessionId = _uuid.v4();
      final newTitle = text.isNotEmpty
          ? (text.length > 25 ? '${text.substring(0, 25)}...' : text)
          : (attachments.isNotEmpty ? 'Attachment session' : 'New chat');

      final newSession = ChatSession(
        id: currentSessionId!,
        title: newTitle,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        messages: [],
      );
      await hiveService.saveSession(newSession);
      ref.read(chatHistoryProvider.notifier).refresh();
    }

    _activeGenerationSessionId = currentSessionId;
    ref.read(isGeneratingProvider.notifier).setGenerating(true);

    final localAtts = attachments
        .map(
          (a) => LocalAttachment(
            type: a.type,
            url: a.url,
            fileName: a.fileName,
            mimeType: a.mimeType,
            fileSize: a.fileSize,
            textContent: a.textContent,
          ),
        )
        .toList();

    final userMsg = _createLocalMessage(text, 'user', attachments: localAtts);
    _addMessageToStateAndDb(userMsg);

    final aiMsgId = _uuid.v4();
    var aiText = '';
    final aiMsg = _createLocalMessage(aiText, 'ai', id: aiMsgId);
    _addMessageToStateAndDb(aiMsg);

    WakelockPlus.enable();

    try {
      final session = hiveService.getSession(currentSessionId!)!;
      final settings = ref.read(settingsControllerProvider);
      final allSessions = hiveService.getAllSessions();

      final stream = ref
          .read(llmServiceProvider)
          .generateResponseStream(
            prompt: text,
            session: session,
            settings: settings,
            allSessions: allSessions,
            attachments: attachments,
          );

      _generationSubscription = stream.listen(
        (chunk) {
          if (_activeGenerationSessionId == currentSessionId) {
            aiText += chunk;
            _updateLocalMessage(aiMsgId, aiText);
            _debouncedSave();
          }
        },
        onError: (error) {
          final errorStr = error.toString();
          if (errorStr.contains('CANCELLED') ||
              errorStr.contains('Process cancelled') ||
              errorStr.contains('Session not created') ||
              errorStr.contains('MODEL_NOT_READY')) {
            appLogger.i(
              "Generation cancelled gracefully (expected): $errorStr",
            );
            return;
          }

          if (errorStr.contains('CONTEXT_OVERFLOW')) {
            if (_activeGenerationSessionId == currentSessionId) {
              _updateLocalMessage(
                aiMsgId,
                "⚠️ Error: The input exceeded strict hardware memory limits. The system attempted to prune memory but the prompt is too large. Please increase 'Total Context Window' in Settings or start a new chat.",
              );
            }
          } else {
            if (_activeGenerationSessionId == currentSessionId) {
              _updateLocalMessage(
                aiMsgId,
                "⚠️ Error: Model inference failed.\nDetails: $error",
              );
            }
          }
          appLogger.e("Inference error", error: error);
        },
        onDone: () {
          appLogger.i("Generation stream completed");
          _generationSubscription = null;
          _activeGenerationSessionId = null;
          ref.read(isGeneratingProvider.notifier).setGenerating(false);
          _flushPendingSaves();
        },
        cancelOnError: false,
      );
    } catch (e) {
      WakelockPlus.disable();
      ref.read(isGeneratingProvider.notifier).setGenerating(false);
      appLogger.e("Inference setup error", error: e);

      if (_activeGenerationSessionId == currentSessionId) {
        _updateLocalMessage(
          aiMsgId,
          "⚠️ Error: Failed to start generation.\nDetails: $e",
        );
      }
      _flushPendingSaves();
    }
  }

  Future<void> _cancelActiveGeneration() async {
    if (_generationSubscription != null) {
      appLogger.i("Cancelling active generation stream...");
      await _generationSubscription!.cancel();
      _generationSubscription = null;
    }
    _activeGenerationSessionId = null;
    ref.read(isGeneratingProvider.notifier).setGenerating(false);
    _flushPendingSaves();
  }

  LocalChatMessage _createLocalMessage(
    String text,
    String authorId, {
    String? id,
    List<LocalAttachment>? attachments,
  }) {
    return LocalChatMessage(
      id: id ?? _uuid.v4(),
      text: text,
      authorId: authorId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      attachments: attachments,
    );
  }

  void _addMessageToStateAndDb(LocalChatMessage msg) {
    state.insertMessage(msg.toChatCoreType());
    _debouncedSave();
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
    }

    _pendingTextUpdates[id] = newText;
  }

  void _debouncedSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(
      const Duration(milliseconds: 300),
      _saveSessionToHive,
    );
  }

  void _flushPendingSaves() {
    _saveDebounceTimer?.cancel();
    if (_pendingTextUpdates.isNotEmpty || currentSessionId != null) {
      _saveSessionToHive();
    }
  }

  void _saveSessionToHive() {
    if (currentSessionId == null) return;
    if (_pendingTextUpdates.isEmpty) return;

    final hiveService = ref.read(hiveServiceProvider);
    final session = hiveService.getSession(currentSessionId!);
    if (session != null) {
      final currentLocalMessages = state.messages.map((m) {
        if (m is core.CustomMessage) {
          return LocalChatMessage(
            id: m.id,
            text: m.metadata?['text'] ?? '',
            authorId: m.authorId,
            createdAt:
                m.createdAt?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            attachments: (m.metadata?['attachments'] as List?)
                ?.map(
                  (a) => LocalAttachment(
                    type: a['type'],
                    url: a['url'],
                    fileName: a['fileName'],
                    mimeType: a['mimeType'],
                    fileSize: a['fileSize'],
                    textContent: a['textContent'],
                  ),
                )
                .toList(),
          );
        } else {
          final tm = m as core.TextMessage;
          return LocalChatMessage(
            id: tm.id,
            text: tm.text,
            authorId: tm.authorId,
            createdAt:
                tm.createdAt?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
          );
        }
      }).toList();

      final updatedSession = session.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        messages: currentLocalMessages,
      );
      hiveService.saveSession(updatedSession);
      ref.read(chatHistoryProvider.notifier).refresh();

      _pendingTextUpdates.clear();
    }
  }

  @override
  core.InMemoryChatController build() {
    final controller = core.InMemoryChatController();
    ref.onDispose(() async {
      _saveDebounceTimer?.cancel();
      await _cancelActiveGeneration();
      controller.dispose();
    });
    return controller;
  }
}
