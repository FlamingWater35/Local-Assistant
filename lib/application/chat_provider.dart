import 'dart:async';

import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:local_assistant/i18n/generated/translations.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/logger.dart';
import '../domain/models.dart';
import '../infrastructure/hive_service.dart';
import '../infrastructure/llm_service.dart';
import 'settings_provider.dart';
import 'stream_manager_provider.dart';

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
class CurrentThinking extends _$CurrentThinking {
  void setThinking(String value) => state = value;

  void clear() => state = '';

  @override
  String build() => '';
}

@Riverpod(keepAlive: true)
class ChatLogic extends _$ChatLogic {
  String? currentSessionId;

  String? _activeGenerationSessionId;
  StreamSubscription? _generationSubscription;
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

    final oldController = state;
    state = newController;
    if (oldController != newController) {
      oldController.dispose();
    }

    await Future.delayed(const Duration(milliseconds: 50));

    final settings = ref.read(settingsControllerProvider);
    final allSessions = ref.read(hiveServiceProvider).getAllSessions();

    if (currentSessionId != sessionId) {
      return;
    }

    final llmService = ref.read(llmServiceProvider);
    final success = await llmService.loadSessionContext(
      session,
      settings,
      allSessions,
    );

    if (currentSessionId != sessionId) {
      return;
    }

    if (!success) {
      appLogger.e("Context loading failed. Model may need re-initialization.");
    }
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

    if (currentSessionId != session.id) return;

    await llmService.loadSessionContext(updatedSession, settings, allSessions);
  }

  Future<void> stopGeneration() async {
    if (_activeGenerationSessionId == currentSessionId &&
        _generationSubscription != null) {
      _finalizeActiveStreamMessage();
    }
    await _cancelActiveGeneration();
    _saveSessionToHive();
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
          : (attachments.isNotEmpty
                ? t.chat.attachmentSession
                : t.chat.newChat);

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
    state.insertMessage(userMsg.toChatCoreType());
    _saveSessionToHive();

    final aiMsgId = _uuid.v4();
    final typingMsgId = _uuid.v4();

    state.insertMessage(
      core.CustomMessage(
        id: typingMsgId,
        authorId: 'ai',
        createdAt: DateTime.now(),
        metadata: {'type': 'typing'},
      ),
    );

    await Future.delayed(const Duration(milliseconds: 150));

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

      bool isFirstChunk = true;

      _generationSubscription = stream.listen(
        (chunk) {
          if (_activeGenerationSessionId == currentSessionId) {
            if (isFirstChunk) {
              isFirstChunk = false;
              try {
                final typingMsg = state.messages.firstWhere(
                  (m) => m.id == typingMsgId,
                );
                state.removeMessage(typingMsg);
              } catch (_) {}
              state.insertMessage(
                core.CustomMessage(
                  id: aiMsgId,
                  authorId: 'ai',
                  createdAt: DateTime.now(),
                  metadata: {'type': 'stream', 'streamId': aiMsgId},
                ),
              );
              ref.read(chatStreamManagerProvider.notifier).startStream(aiMsgId);
            }

            if (chunk.isThinking && chunk.thinking != null) {
              ref
                  .read(chatStreamManagerProvider.notifier)
                  .addChunk(aiMsgId, thinking: chunk.thinking!);
            }
            if (chunk.isText && chunk.text != null) {
              ref
                  .read(chatStreamManagerProvider.notifier)
                  .addChunk(aiMsgId, text: chunk.text!);
            }
          }
        },
        onError: (error) {
          try {
            WakelockPlus.disable();
          } catch (_) {}

          final errorStr = error.toString();
          if (errorStr.contains('CANCELLED') ||
              errorStr.contains('Process cancelled') ||
              errorStr.contains('Session not created') ||
              errorStr.contains('MODEL_NOT_READY')) {
            return;
          }

          if (_activeGenerationSessionId == currentSessionId) {
            if (isFirstChunk) {
              try {
                final typingMsg = state.messages.firstWhere(
                  (m) => m.id == typingMsgId,
                );
                state.removeMessage(typingMsg);
              } catch (_) {}
              isFirstChunk = false;
            }

            final errText =
                errorStr.contains('CONTEXT_OVERFLOW') ||
                    errorStr.contains('SizeOfDimension') ||
                    errorStr.contains('Failed to invoke')
                ? t.errors.contextOverflow
                : t.errors.inferenceFailed(error: error);

            _finalizeActiveStreamMessage(errText);
          }

          _generationSubscription = null;
          _activeGenerationSessionId = null;
          ref.read(isGeneratingProvider.notifier).setGenerating(false);
          _saveSessionToHive();
        },
        onDone: () {
          try {
            WakelockPlus.disable();
          } catch (_) {}

          if (_activeGenerationSessionId == currentSessionId) {
            if (isFirstChunk) {
              try {
                final typingMsg = state.messages.firstWhere(
                  (m) => m.id == typingMsgId,
                );
                state.removeMessage(typingMsg);
              } catch (_) {}
              isFirstChunk = false;
            }

            _finalizeActiveStreamMessage();
          }

          _generationSubscription = null;
          _activeGenerationSessionId = null;
          ref.read(isGeneratingProvider.notifier).setGenerating(false);
          _saveSessionToHive();
        },
        cancelOnError: true,
      );
    } catch (e) {
      try {
        WakelockPlus.disable();
      } catch (_) {}
      ref.read(isGeneratingProvider.notifier).setGenerating(false);

      if (_activeGenerationSessionId == currentSessionId) {
        try {
          final typingMsg = state.messages.firstWhere(
            (m) => m.id == typingMsgId,
          );
          state.removeMessage(typingMsg);
        } catch (_) {}
        state.insertMessage(
          core.TextMessage(
            id: aiMsgId,
            text: t.errors.generationFailed(error: e),
            authorId: 'ai',
            createdAt: DateTime.now(),
          ),
        );
      }
      _saveSessionToHive();
    }
  }

  void _finalizeActiveStreamMessage([String? errorText]) {
    final streamMsg = state.messages
        .whereType<core.CustomMessage>()
        .where((m) => m.metadata?['type'] == 'stream')
        .firstOrNull;

    if (streamMsg != null) {
      final aiMsgId = streamMsg.id;
      final streamManager = ref.read(chatStreamManagerProvider.notifier);
      final aiText = streamManager.getText(aiMsgId);
      final aiThinking = streamManager.getThinking(aiMsgId);

      String combinedContent = aiText;
      if (errorText != null) {
        combinedContent = combinedContent.isNotEmpty
            ? "$combinedContent\n\n$errorText"
            : errorText;
      }

      String finalCombined = aiThinking.isNotEmpty
          ? '<local_assistant_thinking>\n$aiThinking\n</local_assistant_thinking>\n$combinedContent'
          : combinedContent;

      final finalMsg = _createLocalMessage(finalCombined, 'ai', id: aiMsgId);

      state.updateMessage(streamMsg, finalMsg.toChatCoreType());

      Future.delayed(const Duration(milliseconds: 100), () {
        streamManager.cleanup(aiMsgId);
      });
    }
  }

  Future<void> _cancelActiveGeneration() async {
    if (_generationSubscription != null) {
      _generationSubscription!.cancel();
      _generationSubscription = null;
    }
    _activeGenerationSessionId = null;
    ref.read(isGeneratingProvider.notifier).setGenerating(false);
    try {
      WakelockPlus.disable();
    } catch (_) {}
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

  void _saveSessionToHive() {
    if (currentSessionId == null) return;

    final hiveService = ref.read(hiveServiceProvider);
    final session = hiveService.getSession(currentSessionId!);
    if (session != null) {
      final currentLocalMessages = state.messages.map((m) {
        if (m is core.CustomMessage) {
          final rawText = m.metadata?['text'] ?? '';
          final thinking = m.metadata?['thinking'];
          final combinedText = (thinking != null && thinking.isNotEmpty)
              ? '<local_assistant_thinking>\n$thinking\n</local_assistant_thinking>\n$rawText'
              : rawText;

          return LocalChatMessage(
            id: m.id,
            text: combinedText,
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
    }
  }

  @override
  core.InMemoryChatController build() {
    final controller = core.InMemoryChatController();
    ref.onDispose(() async {
      await _cancelActiveGeneration();
      controller.dispose();
    });
    return controller;
  }
}
