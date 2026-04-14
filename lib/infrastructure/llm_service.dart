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

      appLogger.i("Activating Gemma model: ${modelDef.name}");

      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(
            modelDef.url,
            token: settings.hfToken.isNotEmpty ? settings.hfToken : null,
          )
          .install();

      _activeModel = await FlutterGemma.getActiveModel(
        maxTokens: settings.maxTokens,
      );
      _activeChat = await _activeModel!.createChat(
        systemInstruction: settings.systemPrompt,
      );

      appLogger.i("Model initialized successfully.");
    } catch (e) {
      appLogger.e("Failed to initialize model.", error: e);
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
      String finalSystemPrompt = settings.systemPrompt;

      if (settings.enableGlobalMemory && allSessions.isNotEmpty) {
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
        }
      }

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
          "Restoring ${limitedMessages.length} messages to LLM context (Limit: ${settings.contextLimit}).",
        );

        for (final msg in limitedMessages) {
          await _activeChat!.addQueryChunk(
            Message.text(text: msg.text, isUser: msg.authorId == 'user'),
          );
        }
      }
    } catch (e) {
      appLogger.e("Failed to restore LLM context", error: e);
    }
  }

  Stream<String> generateResponseStream(String prompt) async* {
    if (_activeChat == null) {
      throw Exception("Model not ready. Check settings or setup.");
    }
    await _activeChat!.addQueryChunk(Message.text(text: prompt, isUser: true));
    final stream = _activeChat!.generateChatResponseAsync();
    await for (final response in stream) {
      if (response is TextResponse) yield response.token;
    }
  }

  Future<void> unloadModel() async {
    await _activeModel?.close();
    _activeModel = null;
    _activeChat = null;
  }
}

@Riverpod(keepAlive: true)
LlmService llmService(Ref ref) {
  return LlmService();
}
