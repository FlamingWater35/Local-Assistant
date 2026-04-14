import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logger.dart';
import '../domain/models.dart';

part 'llm_service.g.dart';

class LlmService {
  InferenceChat? _activeChat;
  InferenceModel? _activeModel;

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

      _activeModel = await FlutterGemma.getActiveModel(
        maxTokens: settings.maxTokens,
      );

      if (_activeChat != null) {
        appLogger.i(
          "🧹 initModel: Clearing previous chat memory from C++ engine...",
        );
        await _activeChat!.close();
      }

      _activeChat = await _activeModel!.createChat(
        systemInstruction: settings.systemPrompt,
      );
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
    if (_activeModel == null) {
      appLogger.w(
        "⚠️ loadSessionContext: _activeModel is null, aborting context load.",
      );
      return;
    }

    try {
      appLogger.i("🔄 loadSessionContext: Preparing to switch chat context...");
      String finalSystemPrompt = settings.systemPrompt;

      if (settings.enableGlobalMemory && allSessions.isNotEmpty) {
        appLogger.i(
          "🧠 loadSessionContext: Global Memory is ENABLED. Fetching cross-chat context.",
        );
        final otherMessages =
            allSessions
                .where((s) => s.id != session?.id)
                .expand((s) => s.messages)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final recentGlobal = otherMessages.take(10).toList().reversed;
        if (recentGlobal.isNotEmpty) {
          final memoryString = recentGlobal
              .map((m) => "${m.authorId == 'user' ? 'User' : 'AI'}: ${m.text}")
              .join("\n");
          finalSystemPrompt +=
              "\n\n[System Note: Context from the user's other recent conversations for cross-chat memory:]\n$memoryString\n[End cross-chat memory]";
          appLogger.i(
            "🧠 loadSessionContext: Injected ${recentGlobal.length} global memory messages into System Prompt.",
          );
        }
      } else {
        appLogger.i(
          "🔒 loadSessionContext: Global Memory is DISABLED. Strict isolation enforced.",
        );
      }

      if (_activeChat != null) {
        appLogger.i(
          "🧹 loadSessionContext: Wiping previous hardware memory state...",
        );
        await _activeChat!.close();
      }

      appLogger.i(
        "💬 loadSessionContext: Creating clean InferenceChat session...",
      );
      _activeChat = await _activeModel!.createChat(
        systemInstruction: finalSystemPrompt,
      );

      if (session != null && session.messages.isNotEmpty) {
        final sortedMessages = List<LocalChatMessage>.from(session.messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final limitedMessages = sortedMessages.length > settings.contextLimit
            ? sortedMessages.sublist(
                sortedMessages.length - settings.contextLimit,
              )
            : sortedMessages;

        appLogger.i(
          "📂 loadSessionContext: Injecting ${limitedMessages.length} past messages from this session into active context (Limit: ${settings.contextLimit}).",
        );

        for (final msg in limitedMessages) {
          await _activeChat!.addQueryChunk(
            Message.text(text: msg.text, isUser: msg.authorId == 'user'),
          );
        }
      } else {
        appLogger.i(
          "📂 loadSessionContext: New/Empty session loaded. Context is completely clean.",
        );
      }
    } catch (e) {
      appLogger.e(
        "❌ loadSessionContext: Failed to restore LLM context",
        error: e,
      );
    }
  }

  Stream<String> generateResponseStream(String prompt) async* {
    if (_activeChat == null) {
      throw Exception("Model not ready. Check settings or setup.");
    }

    appLogger.i("⚡ generateResponseStream: Sending prompt to model: '$prompt'");
    await _activeChat!.addQueryChunk(Message.text(text: prompt, isUser: true));

    final stream = _activeChat!.generateChatResponseAsync();
    await for (final response in stream) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
    appLogger.i("✅ generateResponseStream: Stream completed successfully.");
  }

  Future<void> unloadModel() async {
    appLogger.w("🧹 unloadModel: Freeing all RAM and VRAM...");
    await _activeChat?.close();
    await _activeModel?.close();
    _activeModel = null;
    _activeChat = null;
    appLogger.i("✅ unloadModel: Model fully unloaded from memory.");
  }
}

@Riverpod(keepAlive: true)
LlmService llmService(Ref ref) {
  return LlmService();
}
