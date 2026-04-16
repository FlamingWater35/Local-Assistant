import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
        supportImage: true,
        supportAudio: true,
        maxNumImages: 1,
      );

      if (_activeChat != null) await _activeChat!.close();

      _activeChat = await _activeModel!.createChat(
        systemInstruction: settings.systemPrompt,
        supportImage: true,
        supportAudio: true,
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
        supportImage: true,
        supportAudio: true,
      );
      int totalTokens = systemTokens;

      if (session != null && session.messages.isNotEmpty) {
        final sortedMessages = List<LocalChatMessage>.from(session.messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final maxInputTokens = (settings.maxTokens * 0.8).toInt();
        final messagesToInject = <LocalChatMessage>[];

        bool isFirstMessage = true;

        for (final msg in sortedMessages.reversed) {
          if (_isUnloading || !_isSessionActive) return;

          if (msg.authorId == 'ai' && msg.text.isEmpty) continue;

          int msgTokens = _estimateTokens(msg.text);
          if (msg.imageUrl != null ||
              (msg.fileUrl != null && msg.mimeType == 'audio/wav')) {
            msgTokens += 256;
          }

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

          if (msg.imageUrl != null) {
            final fileInfo = await DefaultCacheManager().getFileFromCache(
              msg.imageUrl!,
            );
            if (fileInfo != null) {
              final bytes = await fileInfo.file.readAsBytes();
              if (msg.text.isEmpty) {
                await _activeChat!.addQueryChunk(
                  Message.imageOnly(
                    imageBytes: bytes,
                    isUser: msg.authorId == 'user',
                  ),
                );
              } else {
                await _activeChat!.addQueryChunk(
                  Message.withImage(
                    text: msg.text,
                    imageBytes: bytes,
                    isUser: msg.authorId == 'user',
                  ),
                );
              }
            } else {
              await _activeChat!.addQueryChunk(
                Message.text(
                  text: msg.text.isEmpty ? "[Image missing]" : msg.text,
                  isUser: msg.authorId == 'user',
                ),
              );
            }
          } else if (msg.fileUrl != null && msg.mimeType == 'audio/wav') {
            final fileInfo = await DefaultCacheManager().getFileFromCache(
              msg.fileUrl!,
            );
            if (fileInfo != null) {
              final bytes = await fileInfo.file.readAsBytes();
              await _activeChat!.addQueryChunk(
                Message.audioOnly(
                  audioBytes: bytes,
                  isUser: msg.authorId == 'user',
                ),
              );
            } else {
              await _activeChat!.addQueryChunk(
                Message.text(
                  text: "[Audio missing]",
                  isUser: msg.authorId == 'user',
                ),
              );
            }
          } else if (msg.fileUrl != null) {
            final docPrompt =
                "Document '${msg.fileName}' contents:\n\n${msg.text}";
            await _activeChat!.addQueryChunk(
              Message.text(text: docPrompt, isUser: msg.authorId == 'user'),
            );
          } else {
            await _activeChat!.addQueryChunk(
              Message.text(text: msg.text, isUser: msg.authorId == 'user'),
            );
          }
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
    Uint8List? imageBytes,
    Uint8List? audioBytes,
    String? fileExtractedText,
    String? fileName,
  }) async* {
    if (_isUnloading || !_isSessionActive || _activeChat == null) {
      appLogger.w("generateResponseStream: Aborted - session not ready");
      throw Exception("MODEL_NOT_READY");
    }

    int promptTokens = _estimateTokens(prompt);
    if (imageBytes != null || audioBytes != null) promptTokens += 256;
    if (fileExtractedText != null) {
      promptTokens += _estimateTokens(fileExtractedText);
    }

    if (_currentContextTokens + promptTokens > settings.maxTokens * 0.8) {
      appLogger.w(
        "⚠️ Context threshold exceeded. Forcing smart memory prune...",
      );
      await loadSessionContext(session, settings, allSessions);
    }

    if (audioBytes != null) {
      if (prompt.isEmpty) {
        await _activeChat!.addQueryChunk(
          Message.audioOnly(audioBytes: audioBytes, isUser: true),
        );
      } else {
        await _activeChat!.addQueryChunk(
          Message.withAudio(text: prompt, audioBytes: audioBytes, isUser: true),
        );
      }
    } else if (fileExtractedText != null) {
      String combined = "Document '$fileName' contents:\n\n$fileExtractedText";
      if (prompt.isNotEmpty) combined += "\n\nUser prompt: $prompt";
      await _activeChat!.addQueryChunk(
        Message.text(text: combined, isUser: true),
      );
    } else if (imageBytes != null) {
      if (prompt.isEmpty) {
        await _activeChat!.addQueryChunk(
          Message.imageOnly(imageBytes: imageBytes, isUser: true),
        );
      } else {
        await _activeChat!.addQueryChunk(
          Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true),
        );
      }
    } else {
      await _activeChat!.addQueryChunk(
        Message.text(text: prompt, isUser: true),
      );
    }

    _currentContextTokens += promptTokens;

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
    if (_isUnloading) return;

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
