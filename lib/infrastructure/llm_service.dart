import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants.dart';
import '../core/logger.dart';
import '../domain/models.dart';

part 'llm_service.g.dart';

// Represents an individual chunk of data yielded by the LLM stream
class GenerationChunk {
  GenerationChunk({this.text, this.thinking});

  final String? text;
  final String? thinking;

  bool get isText => text != null;
  bool get isThinking => thinking != null;
}

// Tracks the global initialization state of the local LLM
@Riverpod(keepAlive: true)
class ModelStatus extends _$ModelStatus {
  void setStatus(ModelState status) {
    state = status;
  }

  @override
  ModelState build() => ModelState.uninitialized;
}

// Core service responsible for initializing, handling context, and running inference on the local LLM
class LlmService {
  LlmService(this.ref);

  final Ref ref;

  InferenceChat? _activeChat;
  InferenceModel? _activeModel;
  int _currentContextTokens = 0;
  int _currentImageCount = 0;
  bool _isSessionActive = false;
  bool _isUnloading = false;
  final _sessionLock = Completer<void>();

  // Mounts the selected LLM into memory and initializes a fresh InferenceChat session
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
    _setStatus(ModelState.loading);

    try {
      WakelockPlus.enable();
    } catch (e) {
      appLogger.w("Could not acquire Wakelock during initModel", error: e);
    }

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

      final fileType = modelDef.fileName.endsWith('.litertlm')
          ? ModelFileType.litertlm
          : ModelFileType.task;

      await FlutterGemma.installModel(
            modelType: modelDef.modelType,
            fileType: fileType,
          )
          .fromNetwork(
            modelDef.url,
            token: settings.hfToken.isNotEmpty ? settings.hfToken : null,
          )
          .install();

      final safeMaxTokens = settings.maxTokens.clamp(
        512,
        modelDef.maxContextSize,
      );
      appLogger.i(
        "⚙️ initModel: Allocating LiteRT KV Cache for $safeMaxTokens tokens.",
      );

      _activeModel = await FlutterGemma.getActiveModel(
        maxTokens: safeMaxTokens,
        preferredBackend: settings.selectedBackend,
        supportImage: modelDef.supportsImages,
        supportAudio: modelDef.supportsAudio,
        maxNumImages: AppConstants.maxAttachments,
      );

      if (_activeChat != null) await _activeChat!.close();

      _activeChat = await _activeModel!.createChat(
        systemInstruction: settings.systemPrompt,
        supportImage: modelDef.supportsImages,
        supportAudio: modelDef.supportsAudio,
        isThinking: settings.enableThinking && modelDef.supportsThinking,
        temperature: settings.temperature,
        maxOutputTokens: settings.maxTokens,
      );

      _currentContextTokens = AppConstants.estimateTokens(
        settings.systemPrompt,
      );
      _currentImageCount = 0;
      _isSessionActive = true;
      _setStatus(ModelState.ready);
      appLogger.i("✅ initModel: Model initialized successfully.");
    } catch (e, st) {
      appLogger.e(
        "❌ initModel: Failed to initialize model.",
        error: e,
        stackTrace: st,
      );
      _isSessionActive = false;
      _setStatus(ModelState.error);
      rethrow;
    } finally {
      try {
        WakelockPlus.disable();
      } catch (e) {
        appLogger.d("Wakelock already disabled", error: e);
      }
    }
  }

  // Parses attached documents, generates embeddings via Gecko model, and augments the original prompt
  Future<String> processAttachmentsForRag(
    String prompt,
    List<ChatAttachment> attachments,
  ) async {
    final docAttachments = attachments
        .where((a) => a.type == 'doc' && a.textContent != null)
        .toList();
    if (docAttachments.isEmpty) return prompt;

    appLogger.i("RAG: Fetching & initializing Gecko 64 embedder...");
    try {
      await FlutterGemma.installEmbedder()
          .modelFromNetwork(
            'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/Gecko_64_quant.tflite',
          )
          .tokenizerFromNetwork(
            'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/sentencepiece.model',
          )
          .install();

      final embedder = await FlutterGemma.getActiveEmbedder(
        preferredBackend: PreferredBackend.cpu,
      );

      appLogger.i("RAG: Initializing VectorStore...");
      await FlutterGemma.rag.initialize('rag_temp.db');
      await FlutterGemma.rag.clear();

      int docId = 0;
      for (var doc in docAttachments) {
        final chunks = _chunkText(doc.textContent!, 500);
        for (var chunk in chunks) {
          final embedding = await embedder.generateEmbedding(chunk);
          await FlutterGemma.rag.addDocumentWithEmbedding(
            id: 'chunk_${docId++}',
            content: chunk,
            embedding: embedding,
          );
        }
      }

      final query = prompt.trim().isEmpty
          ? "Summarize the key points of the documents."
          : prompt;

      final results = await FlutterGemma.rag.searchSimilar(
        query: query,
        topK: 4,
        threshold: 0.0,
      );

      await embedder.close();

      if (results.isEmpty) return prompt;

      String contextText = results.map((r) => r.content).join('\n\n---\n\n');
      appLogger.i(
        "RAG: Augmented prompt with ${results.length} context chunks.",
      );
      return "Use the following retrieved document context to answer the user's query.\n\nContext:\n$contextText\n\nUser Query: $query";
    } catch (e, st) {
      appLogger.e(
        "RAG: Failed during embedding or vector search. Proceeding with unaugmented prompt.",
        error: e,
        stackTrace: st,
      );
      return prompt; // Fallback to safe raw prompt
    }
  }

  // Injects prior messages from a specific session into the model's fresh chat context
  Future<bool> loadSessionContext(
    ChatSession? session,
    AppSettings settings,
    List<ChatSession> allSessions, {
    int reserveImages = 0,
  }) async {
    if (_isUnloading || !_isSessionActive || _activeModel == null) {
      return false;
    }
    _setStatus(ModelState.loading);

    try {
      String finalSystemPrompt = settings.systemPrompt;
      int systemTokens = AppConstants.estimateTokens(finalSystemPrompt);

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
          systemTokens = AppConstants.estimateTokens(finalSystemPrompt);
        }
      }

      if (_activeChat != null) await _activeChat!.close();

      final modelDef = kAvailableModels.firstWhere(
        (m) => m.id == settings.selectedModel,
        orElse: () => kAvailableModels.first,
      );

      _activeChat = await _activeModel!.createChat(
        systemInstruction: finalSystemPrompt,
        supportImage: modelDef.supportsImages,
        supportAudio: modelDef.supportsAudio,
        isThinking: settings.enableThinking && modelDef.supportsThinking,
        temperature: settings.temperature,
        maxOutputTokens: settings.maxTokens,
      );

      int totalTokens = systemTokens;
      int imageCount = reserveImages;

      if (session != null && session.messages.isNotEmpty) {
        final sortedMessages = List<LocalChatMessage>.from(session.messages)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final maxInputTokens =
            (settings.maxTokens * AppConstants.contextThresholdRatio).toInt();
        final messagesToInject = <LocalChatMessage>[];

        bool isFirstMessage = true;

        for (final msg in sortedMessages.reversed) {
          if (_isUnloading || !_isSessionActive) return false;
          if (msg.authorId == 'ai' && msg.text.isEmpty) continue;

          final atts = msg.attachments ?? [];
          final msgPhotos = atts.where((a) => a.type == 'photo').length;

          if (imageCount + msgPhotos > AppConstants.maxAttachments) continue;

          int msgTokens = AppConstants.estimateTokens(msg.text);
          msgTokens += AppConstants.estimateLocalAttachmentTokens(atts);

          if (!isFirstMessage && totalTokens + msgTokens > maxInputTokens) {
            break;
          }

          imageCount += msgPhotos;
          totalTokens += msgTokens;
          messagesToInject.add(msg);
          isFirstMessage = false;
        }

        for (final msg in messagesToInject.reversed) {
          if (_isUnloading) return false;

          if (msg.authorId == 'user') {
            String combinedText = "";
            List<LocalAttachment> mediaAtts = [];

            final attsToProcess = msg.attachments ?? [];
            for (final att in attsToProcess) {
              if (att.type == 'photo' || att.type == 'audio') {
                mediaAtts.add(att);
              }
            }
            if (msg.text.isNotEmpty) combinedText += msg.text;
            combinedText = combinedText.trim();

            if (mediaAtts.isEmpty) {
              if (combinedText.isNotEmpty) {
                await _activeChat!.addQuery(
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
                    await _activeChat!.addQuery(
                      Message.withImage(
                        text: textPayload,
                        imageBytes: bytes,
                        isUser: true,
                      ),
                    );
                  } else {
                    final fallback = textPayload.isNotEmpty
                        ? "[Image missing]\n\n$textPayload"
                        : "[Image missing]";
                    await _activeChat!.addQuery(
                      Message.text(text: fallback, isUser: true),
                    );
                  }
                } else if (att.type == 'audio') {
                  if (bytes != null) {
                    await _activeChat!.addQuery(
                      Message.withAudio(
                        text: textPayload,
                        audioBytes: bytes,
                        isUser: true,
                      ),
                    );
                  } else {
                    final fallback = textPayload.isNotEmpty
                        ? "[Audio missing]\n\n$textPayload"
                        : "[Audio missing]";
                    await _activeChat!.addQuery(
                      Message.text(text: fallback, isUser: true),
                    );
                  }
                }
              }
            }
          } else {
            if (msg.text.isNotEmpty) {
              await _activeChat!.addQuery(
                Message.text(text: msg.text, isUser: false),
              );
            }
          }
        }
      }

      _currentContextTokens = totalTokens;
      _currentImageCount = imageCount - reserveImages;
      _setStatus(ModelState.ready);
      return true;
    } catch (e, st) {
      appLogger.e("Failed to load session context", error: e, stackTrace: st);
      _isSessionActive = false;
      _setStatus(ModelState.error);
      return false;
    }
  }

  // Asynchronously generates the response from the LLM, passing results chunk by chunk
  Stream<GenerationChunk> generateResponseStream({
    required String prompt,
    required ChatSession session,
    required AppSettings settings,
    required List<ChatSession> allSessions,
    List<ChatAttachment> attachments = const [],
  }) async* {
    if (_isUnloading || !_isSessionActive || _activeChat == null) {
      throw Exception("MODEL_NOT_READY");
    }

    final augmentedPrompt = await processAttachmentsForRag(prompt, attachments);

    int promptTokens = AppConstants.estimateTokens(augmentedPrompt);
    int incomingImages = attachments.where((a) => a.type == 'photo').length;
    promptTokens += AppConstants.estimateAttachmentTokens(attachments);

    if (_currentContextTokens + promptTokens >
            settings.maxTokens * AppConstants.contextThresholdRatio ||
        _currentImageCount + incomingImages > AppConstants.maxAttachments) {
      final success = await loadSessionContext(
        session,
        settings,
        allSessions,
        reserveImages: incomingImages,
      );
      if (!success) throw Exception("CONTEXT_OVERFLOW");
    }

    final photos = attachments.where((a) => a.type == 'photo').toList();
    final audios = attachments.where((a) => a.type == 'audio').toList();
    final mediaAttachments = [...audios, ...photos];

    if (mediaAttachments.isEmpty) {
      if (augmentedPrompt.isNotEmpty) {
        await _activeChat!.addQuery(
          Message.text(text: augmentedPrompt, isUser: true),
        );
      }
    } else {
      for (int i = 0; i < mediaAttachments.length; i++) {
        final att = mediaAttachments[i];
        bool isLast = (i == mediaAttachments.length - 1);
        String textPayload = isLast ? augmentedPrompt : "";

        if (att.type == 'photo') {
          await _activeChat!.addQuery(
            Message.withImage(
              text: textPayload,
              imageBytes: att.bytes,
              isUser: true,
            ),
          );
        } else if (att.type == 'audio') {
          await _activeChat!.addQuery(
            Message.withAudio(
              text: textPayload,
              audioBytes: att.bytes,
              isUser: true,
            ),
          );
        }
      }
    }

    _currentContextTokens += promptTokens;
    _currentImageCount += incomingImages;
    int generatedTokens = 0;

    try {
      final stream = _activeChat!.generateChatResponseAsync();
      await for (final response in stream) {
        if (_isUnloading || !_isSessionActive) break;

        if (response is TextResponse) {
          if (_isSessionActive && !_isUnloading) {
            try {
              int tok = AppConstants.estimateTokens(response.token);
              generatedTokens += tok;
              _currentContextTokens += tok;
            } catch (e) {
              appLogger.d("Error estimating generation tokens", error: e);
            }
          }
          yield GenerationChunk(text: response.token);
        } else if (response is ThinkingResponse && settings.enableThinking) {
          yield GenerationChunk(thinking: response.content);
        }
      }
    } catch (e, st) {
      _currentContextTokens -= (promptTokens + generatedTokens);
      _currentImageCount -= incomingImages;

      final errorStr = e.toString();
      if (errorStr.contains('CANCELLED') ||
          errorStr.contains('Process cancelled') ||
          errorStr.contains('Session not created')) {
        return;
      }

      appLogger.e(
        "Inference failed during generation stream",
        error: e,
        stackTrace: st,
      );

      if (errorStr.contains('Failed to invoke') ||
          errorStr.contains('SizeOfDimension')) {
        throw Exception("CONTEXT_OVERFLOW");
      }
      rethrow;
    }
  }

  // Stops native inference for the active chat, if one is mid-generation.
  // This is the on-device cancel: it aborts the LiteRT-LM/MediaPipe
  // generation loop so the model stops burning compute, instead of only
  // detaching the Dart stream (which would leave native generation running
  // to completion in the background).
  Future<void> stopGeneration() async {
    final chat = _activeChat;
    if (chat == null) return;
    try {
      await chat.stopGeneration();
    } catch (e, st) {
      appLogger.d(
        "stopGeneration: native cancel failed (best-effort)",
        error: e,
        stackTrace: st,
      );
    }
  }

  // Gracefully shuts down the LLM Engine, disposing of active chats and models
  Future<void> unloadModel() async {
    if (_isUnloading) return;

    _isUnloading = true;
    _isSessionActive = false;
    _setStatus(ModelState.unloading);

    try {
      if (_activeChat != null) {
        await _activeChat!.close();
        _activeChat = null;
      }
      if (_activeModel != null) {
        await _activeModel!.close();
        _activeModel = null;
      }
      _currentContextTokens = 0;
      _currentImageCount = 0;
    } catch (e, st) {
      appLogger.e(
        "Error safely unloading LLM instances",
        error: e,
        stackTrace: st,
      );
    } finally {
      _isUnloading = false;
      _setStatus(ModelState.uninitialized);
      if (!_sessionLock.isCompleted) {
        _sessionLock.complete();
      }
    }
  }

  // Updates ModelStatus flag to Ready if initialization succeeds behind the scenes
  void markSessionReady() {
    if (_activeModel != null && _activeChat != null) {
      _isSessionActive = true;
      _isUnloading = false;
      _setStatus(ModelState.ready);
    }
  }

  List<String> _chunkText(String text, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      chunks.add(
        text.substring(
          i,
          i + chunkSize > text.length ? text.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  void _setStatus(ModelState status) {
    ref.read(modelStatusProvider.notifier).setStatus(status);
  }
}

@Riverpod(keepAlive: true)
LlmService llmService(Ref ref) {
  return LlmService(ref);
}
