import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logger.dart';
import '../domain/models.dart';

part 'llm_service.g.dart';

class LlmService {
  InferenceChat? _activeChat;
  InferenceModel? _activeModel;
  int _currentContextTokens = 0;

  Future<void> initModel(AppSettings settings) async {
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

      if (_activeChat != null) {
        await _activeChat!.close();
      }

      _activeChat = await _activeModel!.createChat(
        systemInstruction: settings.systemPrompt,
      );
      _currentContextTokens = _estimateTokens(settings.systemPrompt);
      appLogger.i("✅ initModel: Model initialized successfully.");
    } catch (e) {
      appLogger.e("❌ initModel: Failed to initialize model.", error: e);
      rethrow;
    }
  }

  Future<void> loadSessionContext(
    ChatSession? session,
    AppSettings settings,
    List<ChatSession> allSessions,
  ) async {
    if (_activeModel == null) return;

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

      if (_activeChat != null) {
        await _activeChat!.close();
      }

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
      appLogger.e(
        "❌ loadSessionContext: Failed to restore LLM context",
        error: e,
      );
    }
  }

  Stream<String> generateResponseStream({
    required String prompt,
    required ChatSession session,
    required AppSettings settings,
    required List<ChatSession> allSessions,
  }) async* {
    if (_activeChat == null) {
      throw Exception("Model not ready. Check settings or setup.");
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
      appLogger.i("⚡ generateResponseStream: Appending to existing context...");
      await _activeChat!.addQueryChunk(
        Message.text(text: prompt, isUser: true),
      );
      _currentContextTokens += promptTokens;
    } else {
      appLogger.i(
        "⚡ generateResponseStream: Context was rebuilt (prompt implicitly injected).",
      );
    }

    try {
      final stream = _activeChat!.generateChatResponseAsync();
      await for (final response in stream) {
        if (response is TextResponse) {
          _currentContextTokens += _estimateTokens(response.token);
          yield response.token;
        }
      }
    } catch (e) {
      if (e.toString().contains('Failed to invoke') ||
          e.toString().contains('SizeOfDimension')) {
        throw Exception("CONTEXT_OVERFLOW");
      }
      rethrow;
    }
  }

  Future<void> unloadModel() async {
    await _activeChat?.close();
    await _activeModel?.close();
    _activeModel = null;
    _activeChat = null;
  }

  int _estimateTokens(String text) =>
      text.isEmpty ? 0 : (text.length / 3.5).ceil();
}

@Riverpod(keepAlive: true)
LlmService llmService(Ref ref) {
  return LlmService();
}
