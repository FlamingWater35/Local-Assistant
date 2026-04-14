import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logger.dart';
import '../domain/models.dart';

part 'llm_service.g.dart';

class LlmService {
  InferenceChat? _activeChat;
  InferenceModel? _activeModel;
  int _currentContextTokens = 0;
  bool _isSessionActive = false;
  bool _isUnloading = false;
  final _sessionLock = Completer<void>();

  Future<void> initModel(AppSettings settings) async {
    if (_isUnloading) {
      await _sessionLock.future
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => appLogger.w("Session lock timeout during init"),
          )
          .catchError((_) {});
    }

    _isSessionActive = false;
    _isUnloading = false;

    try {
      appLogger.i("⚙️ initModel: Starting model initialization...");
      final modelDef = kAvailableModels.firstWhere(
        (m) => m.id == settings.selectedModel,
        orElse: () => kAvailableModels.first,
      );

      final isInstalled = await FlutterGemma.isModelInstalled(
        modelDef.fileName,
      );
      if (!isInstalled) {
        throw StateError("Model file not found. Please download it first.");
      }

      appLogger.i("⚙️ initModel: Mounting Gemma model: ${modelDef.name}");

      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(
            modelDef.url,
            token: settings.hfToken.isNotEmpty ? settings.hfToken : null,
          )
          .install();

      final safeMaxTokens = settings.maxTokens < 2048
          ? 2048
          : settings.maxTokens;
      appLogger.i(
        "⚙️ initModel: Allocating LiteRT KV Cache for $safeMaxTokens tokens.",
      );
      _activeModel = await FlutterGemma.getActiveModel(
        maxTokens: safeMaxTokens,
      );

      if (_activeChat != null) await _activeChat!.close();

      _activeChat = await _activeModel!.createChat(
        systemInstruction: settings.systemPrompt,
      );
      _currentContextTokens = _estimateTokens(settings.systemPrompt);
      _isSessionActive = true;
      appLogger.i("✅ initModel: Model initialized successfully.");
    } catch (e) {
      appLogger.e("❌ initModel: Failed to initialize model.", error: e);
      _isSessionActive = false;
      rethrow;
    }
  }

  Future<void> loadSessionContext(
    ChatSession? session,
    AppSettings settings,
    List<ChatSession> allSessions,
  ) async {
    if (_isUnloading || !_isSessionActive || _activeModel == null) {
      appLogger.i("loadSessionContext: Skipped - session not active");
      return;
    }

    try {
      appLogger.i("🔄 loadSessionContext: Rebuilding chat context...");
      String finalSystemPrompt = settings.systemPrompt;
      int systemTokens = _estimateTokens(finalSystemPrompt);

      if (settings.enableGlobalMemory && allSessions.isNotEmpty) {
        final otherMessages =
            allSessions
                .where((s) => s.id != session?.id)
                .expand((s) => s.messages)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final recentGlobal = otherMessages.take(3).toList().reversed;
        if (recentGlobal.isNotEmpty) {
          final memoryString = recentGlobal
              .map((m) => "${m.authorId == 'user' ? 'User' : 'AI'}: ${m.text}")
              .join("\n");
          finalSystemPrompt +=
              "\n\n[System Note: Context from the user's other recent conversations for cross-chat memory:]\n$memoryString\n[End cross-chat memory]";
          systemTokens = _estimateTokens(finalSystemPrompt);
        }
      }

      if (_activeChat != null) await _activeChat!.close();

      _activeChat = await _activeModel!.createChat(
        systemInstruction: finalSystemPrompt,
      );
      int totalTokens = systemTokens;

      if (session != null && session.messages.isNotEmpty) {
        final sortedMessages = List<LocalChatMessage>.from(session.messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final maxInputTokens = (settings.maxTokens * 0.8).toInt();
        final messagesToInject = <LocalChatMessage>[];

        bool isFirstMessage = true;

        for (final msg in sortedMessages.reversed) {
          if (_isUnloading || !_isSessionActive) {
            appLogger.i("loadSessionContext: Aborted mid-processing");
            return;
          }

          if (msg.authorId == 'ai' && msg.text.isEmpty) continue;

          final msgTokens = _estimateTokens(msg.text);

          if (!isFirstMessage && totalTokens + msgTokens > maxInputTokens) {
            appLogger.i(
              "✂️ Smart Truncation: Stopped adding older history at ${messagesToInject.length} messages (Context reached $totalTokens tokens).",
            );
            break;
          }

          totalTokens += msgTokens;
          messagesToInject.add(msg);
          isFirstMessage = false;
        }

        for (final msg in messagesToInject.reversed) {
          if (_isUnloading) return;
          await _activeChat!.addQueryChunk(
            Message.text(text: msg.text, isUser: msg.authorId == 'user'),
          );
        }
      }

      _currentContextTokens = totalTokens;
      appLogger.i(
        "📂 loadSessionContext: Rebuilt context with $_currentContextTokens estimated tokens.",
      );
    } catch (e) {
      if (!e.toString().contains('CANCELLED')) {
        appLogger.e(
          "❌ loadSessionContext: Failed to restore LLM context",
          error: e,
        );
      }
    }
  }

  Stream<String> generateResponseStream({
    required String prompt,
    required ChatSession session,
    required AppSettings settings,
    required List<ChatSession> allSessions,
  }) async* {
    if (_isUnloading || !_isSessionActive || _activeChat == null) {
      appLogger.w("generateResponseStream: Aborted - session not ready");
      throw Exception("MODEL_NOT_READY");
    }

    int promptTokens = _estimateTokens(prompt);
    bool didPrune = false;

    if (_currentContextTokens + promptTokens > settings.maxTokens * 0.8) {
      appLogger.w(
        "⚠️ Context threshold exceeded. Forcing smart memory prune...",
      );
      await loadSessionContext(session, settings, allSessions);
      didPrune = true;
    }

    if (!didPrune) {
      await _activeChat!.addQueryChunk(
        Message.text(text: prompt, isUser: true),
      );
      _currentContextTokens += promptTokens;
    }

    try {
      final stream = _activeChat!.generateChatResponseAsync();
      await for (final response in stream) {
        if (_isUnloading || !_isSessionActive) {
          appLogger.i("generateResponseStream: Stream cancelled by lifecycle");
          break;
        }

        if (response is TextResponse) {
          if (_isSessionActive && !_isUnloading) {
            try {
              _currentContextTokens += _estimateTokens(response.token);
            } catch (_) {}
          }
          yield response.token;
        }
      }
    } catch (e) {
      if (e.toString().contains('CANCELLED') ||
          e.toString().contains('Process cancelled') ||
          e.toString().contains('Session not created')) {
        appLogger.i("generateResponseStream: Expected cancellation");
        return;
      }

      if (e.toString().contains('Failed to invoke') ||
          e.toString().contains('SizeOfDimension')) {
        throw Exception("CONTEXT_OVERFLOW");
      }
      rethrow;
    }
  }

  Future<void> unloadModel() async {
    if (_isUnloading) {
      appLogger.i("unloadModel: Already unloading, skipping");
      return;
    }

    _isUnloading = true;
    _isSessionActive = false;

    try {
      appLogger.i("🔄 unloadModel: Closing active chat...");

      if (_activeChat != null) {
        try {
          await _activeChat!.close();
        } catch (e) {
          if (!e.toString().contains('CANCELLED')) {
            appLogger.w("unloadModel: Close warning", error: e);
          }
        }
        _activeChat = null;
      }

      appLogger.i("🔄 unloadModel: Closing model...");
      if (_activeModel != null) {
        try {
          await _activeModel!.close();
        } catch (e) {
          if (!e.toString().contains('CANCELLED')) {
            appLogger.w("unloadModel: Model close warning", error: e);
          }
        }
        _activeModel = null;
      }

      _currentContextTokens = 0;
      appLogger.i("✅ unloadModel: Complete");
    } catch (e) {
      appLogger.e("❌ unloadModel: Error during cleanup", error: e);
    } finally {
      _isUnloading = false;
      if (!_sessionLock.isCompleted) {
        _sessionLock.complete();
      }
    }
  }

  void markSessionReady() {
    if (_activeModel != null && _activeChat != null) {
      _isSessionActive = true;
      _isUnloading = false;
      appLogger.i("Session marked ready for inference");
    }
  }

  int _estimateTokens(String text) =>
      text.isEmpty ? 0 : (text.length / 3.5).ceil();
}

@Riverpod(keepAlive: true)
LlmService llmService(Ref ref) {
  return LlmService();
}
