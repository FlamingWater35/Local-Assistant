import 'dart:async';

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
  int _currentImageCount = 0;
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
        maxNumImages: 2,
      );

      if (_activeChat != null) await _activeChat!.close();

      _activeChat = await _activeModel!.createChat(
        systemInstruction: settings.systemPrompt,
        supportImage: true,
        supportAudio: true,
      );
      _currentContextTokens = _estimateTokens(settings.systemPrompt);
      _currentImageCount = 0;
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
    List<ChatSession> allSessions, {
    int reserveImages = 0,
  }) async {
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
      int imageCount = reserveImages;

      if (session != null && session.messages.isNotEmpty) {
        final sortedMessages = List<LocalChatMessage>.from(session.messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final maxInputTokens = (settings.maxTokens * 0.8).toInt();
        final messagesToInject = <LocalChatMessage>[];

        bool isFirstMessage = true;

        for (final msg in sortedMessages.reversed) {
          if (_isUnloading || !_isSessionActive) return;
          if (msg.authorId == 'ai' && msg.text.isEmpty) continue;

          final atts = msg.attachments ?? [];
          final msgPhotos = atts.where((a) => a.type == 'photo').length;

          if (imageCount + msgPhotos > 2) {
            continue;
          }

          int msgTokens = _estimateTokens(msg.text);
          for (final att in atts) {
            if (att.type == 'photo' || att.type == 'audio') msgTokens += 256;
            if (att.type == 'doc' && att.textContent != null) {
              msgTokens += _estimateTokens(att.textContent!);
            }
          }

          if (!isFirstMessage && totalTokens + msgTokens > maxInputTokens) {
            appLogger.i(
              "✂️ Smart Truncation: Stopped adding older history at ${messagesToInject.length} messages (Context reached $totalTokens tokens).",
            );
            break;
          }

          imageCount += msgPhotos;
          totalTokens += msgTokens;
          messagesToInject.add(msg);
          isFirstMessage = false;
        }

        for (final msg in messagesToInject.reversed) {
          if (_isUnloading) return;

          if (msg.authorId == 'user') {
            String combinedText = "";
            List<LocalAttachment> mediaAtts = [];

            final attsToProcess = msg.attachments ?? [];
            for (final att in attsToProcess) {
              if (att.type == 'photo' || att.type == 'audio') {
                mediaAtts.add(att);
              } else if (att.type == 'doc' && att.textContent != null) {
                combinedText +=
                    "Document '${att.fileName}' contents:\n\n${att.textContent}\n\n";
              }
            }
            if (msg.text.isNotEmpty) combinedText += msg.text;
            combinedText = combinedText.trim();

            if (mediaAtts.isEmpty) {
              if (combinedText.isNotEmpty) {
                await _activeChat!.addQueryChunk(
                  Message.text(text: combinedText, isUser: true),
                );
              }
            } else {
              for (int i = 0; i < mediaAtts.length; i++) {
                final att = mediaAtts[i];
                bool isLast = (i == mediaAtts.length - 1);
                String textPayload = isLast ? combinedText : "";

                final fileInfo = await DefaultCacheManager().getFileFromCache(
                  att.url,
                );
                final bytes = fileInfo != null
                    ? await fileInfo.file.readAsBytes()
                    : null;

                if (att.type == 'photo') {
                  if (bytes != null) {
                    if (textPayload.isNotEmpty) {
                      await _activeChat!.addQueryChunk(
                        Message.withImage(
                          text: textPayload,
                          imageBytes: bytes,
                          isUser: true,
                        ),
                      );
                    } else {
                      await _activeChat!.addQueryChunk(
                        Message.imageOnly(imageBytes: bytes, isUser: true),
                      );
                    }
                  } else {
                    final fallback = textPayload.isNotEmpty
                        ? "[Image missing]\n\n$textPayload"
                        : "[Image missing]";
                    await _activeChat!.addQueryChunk(
                      Message.text(text: fallback, isUser: true),
                    );
                  }
                } else if (att.type == 'audio') {
                  if (bytes != null) {
                    if (textPayload.isNotEmpty) {
                      await _activeChat!.addQueryChunk(
                        Message.withAudio(
                          text: textPayload,
                          audioBytes: bytes,
                          isUser: true,
                        ),
                      );
                    } else {
                      await _activeChat!.addQueryChunk(
                        Message.audioOnly(audioBytes: bytes, isUser: true),
                      );
                    }
                  } else {
                    final fallback = textPayload.isNotEmpty
                        ? "[Audio missing]\n\n$textPayload"
                        : "[Audio missing]";
                    await _activeChat!.addQueryChunk(
                      Message.text(text: fallback, isUser: true),
                    );
                  }
                }
              }
            }
          } else {
            if (msg.text.isNotEmpty) {
              await _activeChat!.addQueryChunk(
                Message.text(text: msg.text, isUser: false),
              );
            }
          }
        }
      }

      _currentContextTokens = totalTokens;
      _currentImageCount = imageCount - reserveImages;
      appLogger.i(
        "📂 loadSessionContext: Rebuilt context with $_currentContextTokens tokens & $_currentImageCount images.",
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
    List<ChatAttachment> attachments = const [],
  }) async* {
    if (_isUnloading || !_isSessionActive || _activeChat == null) {
      appLogger.w("generateResponseStream: Aborted - session not ready");
      throw Exception("MODEL_NOT_READY");
    }

    int promptTokens = _estimateTokens(prompt);
    int incomingImages = attachments.where((a) => a.type == 'photo').length;

    for (var att in attachments) {
      if (att.type == 'photo' || att.type == 'audio') promptTokens += 256;
      if (att.type == 'doc' && att.textContent != null) {
        promptTokens += _estimateTokens(att.textContent!);
      }
    }

    if (_currentContextTokens + promptTokens > settings.maxTokens * 0.8 ||
        _currentImageCount + incomingImages > 2) {
      appLogger.w("⚠️ Threshold exceeded. Forcing memory prune...");
      await loadSessionContext(
        session,
        settings,
        allSessions,
        reserveImages: incomingImages,
      );
    }

    String combinedText = "";

    for (var att in attachments) {
      if (att.type == 'doc' && att.textContent != null) {
        combinedText +=
            "Document '${att.fileName}' contents:\n\n${att.textContent}\n\n";
      }
    }
    if (prompt.isNotEmpty) {
      combinedText += prompt;
    }
    combinedText = combinedText.trim();

    final photos = attachments.where((a) => a.type == 'photo').toList();
    final audios = attachments.where((a) => a.type == 'audio').toList();
    final mediaAttachments = [...audios, ...photos];

    if (mediaAttachments.isEmpty) {
      if (combinedText.isNotEmpty) {
        await _activeChat!.addQueryChunk(
          Message.text(text: combinedText, isUser: true),
        );
      }
    } else {
      for (int i = 0; i < mediaAttachments.length; i++) {
        final att = mediaAttachments[i];
        bool isLast = (i == mediaAttachments.length - 1);
        String textPayload = isLast ? combinedText : "";

        if (att.type == 'photo') {
          if (textPayload.isNotEmpty) {
            await _activeChat!.addQueryChunk(
              Message.withImage(
                text: textPayload,
                imageBytes: att.bytes,
                isUser: true,
              ),
            );
          } else {
            await _activeChat!.addQueryChunk(
              Message.imageOnly(imageBytes: att.bytes, isUser: true),
            );
          }
        } else if (att.type == 'audio') {
          if (textPayload.isNotEmpty) {
            await _activeChat!.addQueryChunk(
              Message.withAudio(
                text: textPayload,
                audioBytes: att.bytes,
                isUser: true,
              ),
            );
          } else {
            await _activeChat!.addQueryChunk(
              Message.audioOnly(audioBytes: att.bytes, isUser: true),
            );
          }
        }
      }
    }

    _currentContextTokens += promptTokens;
    _currentImageCount += incomingImages;

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
      _currentImageCount = 0;
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
