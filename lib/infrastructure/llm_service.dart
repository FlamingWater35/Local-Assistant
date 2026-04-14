import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logger.dart';
import '../domain/models.dart';

part 'llm_service.g.dart';

class LlmService {
  InferenceModel? _activeModel;
  InferenceChat? _activeChat;

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
    appLogger.w("Model unloaded from memory.");
  }
}

@Riverpod(keepAlive: true)
LlmService llmService(Ref ref) {
  return LlmService();
}
