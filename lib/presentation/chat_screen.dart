import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_assistant/infrastructure/llm_service.dart';
import 'package:uuid/uuid.dart';

import '../application/chat_provider.dart';
import '../application/settings_provider.dart';
import '../application/stream_manager_provider.dart';
import '../application/updater_provider.dart';
import '../core/audio_converter.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';
import '../domain/models.dart';
import '../i18n/generated/translations.g.dart';
import 'chat_drawer.dart';
import 'widgets/model_status_app_bar_title.dart';
import 'widgets/thinking_widget.dart';
import 'widgets/throttled_markdown_widget.dart';

// The primary screen where users interact with the Local Assistant AI model.
// Manages message composition, attachment handling, and real-time streaming UI.
@RoutePage()
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final List<ChatAttachment> _pendingAttachments = [];

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  // Opens a confirmation dialog and securely attempts to delete a single target message.
  // Wraps the deletion in try/catch to notify the user if the database operation fails.
  void _confirmDeleteMessage(String messageId) {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.chat.deleteMessageTitle),
        content: Text(t.chat.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref
                    .read(chatLogicProvider.notifier)
                    .deleteMessage(messageId);
                if (mounted && ctx.mounted) {
                  Navigator.pop(ctx);
                  showSuccessSnackBar(context, t.chat.messageDeleted);
                }
              } catch (e, st) {
                appLogger.e("Error deleting message", error: e, stackTrace: st);
                if (mounted && ctx.mounted) {
                  Navigator.pop(ctx);
                  showErrorSnackBar(
                    context,
                    "Failed to delete message. Please try again.",
                  );
                }
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  // Opens a bottom sheet for the user to select an attachment type, then processes the selection securely.
  // Wraps file picking and parsing in try/catch to handle permission denials or invalid file formats gracefully.
  Future<void> _handleAttachmentTap() async {
    final t = Translations.of(context);
    if (_pendingAttachments.length >= AppConstants.maxAttachments) {
      showErrorSnackBar(context, t.chat.maxAttachments);
      return;
    }

    final settings = ref.read(settingsControllerProvider);
    final modelDef = kAvailableModels.firstWhere(
      (m) => m.id == settings.selectedModel,
      orElse: () => kAvailableModels.first,
    );

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Attachment',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AttachmentOption(
                      icon: Icons.image,
                      label: t.attachments.photo,
                      extensions: '.jpg, .png',
                      enabled: modelDef.supportsImages,
                      onTap: () => Navigator.pop(ctx, 'photo'),
                    ),
                  ),
                  Expanded(
                    child: _AttachmentOption(
                      icon: Icons.audio_file,
                      label: t.attachments.audio,
                      extensions: '.wav',
                      enabled: modelDef.supportsAudio,
                      onTap: () => Navigator.pop(ctx, 'audio'),
                    ),
                  ),
                  Expanded(
                    child: _AttachmentOption(
                      icon: Icons.insert_drive_file,
                      label: t.attachments.document,
                      extensions: '.txt, .md, .csv',
                      enabled: true,
                      onTap: () => Navigator.pop(ctx, 'doc'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;

    try {
      if (choice == 'photo') {
        final picker = ImagePicker();
        final xFile = await picker.pickImage(source: ImageSource.gallery);
        if (xFile == null) return;
        final bytes = await xFile.readAsBytes();
        final url = 'http://local_image_${const Uuid().v4()}.jpg';
        await DefaultCacheManager().putFile(url, bytes, fileExtension: 'jpg');
        if (!mounted) return;
        setState(() {
          _pendingAttachments.add(
            ChatAttachment(
              type: 'photo',
              bytes: bytes,
              url: url,
              fileName: xFile.name,
              mimeType: 'image/jpeg',
            ),
          );
        });
      } else if (choice == 'audio') {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['wav'],
        );
        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final rawBytes = await file.readAsBytes();
          Uint8List pcmData;
          try {
            final parsed = AudioConverter.parseWav(rawBytes);
            pcmData = AudioConverter.toPCM16kHzMono(
              parsed.pcmData,
              sourceSampleRate: parsed.sampleRate,
              sourceChannels: parsed.channels,
            );
          } catch (e) {
            appLogger.e("Invalid WAV file", error: e);
            if (mounted) {
              showErrorSnackBar(context, t.errors.invalidAudioFormat);
            }
            return;
          }
          final url = 'http://local_audio_${const Uuid().v4()}.wav';
          await DefaultCacheManager().putFile(
            url,
            pcmData,
            fileExtension: 'wav',
          );
          if (!mounted) return;
          setState(() {
            _pendingAttachments.add(
              ChatAttachment(
                type: 'audio',
                bytes: pcmData,
                url: url,
                fileName: result.files.single.name,
                fileSize: pcmData.length,
                mimeType: 'audio/wav',
              ),
            );
          });
        }
      } else if (choice == 'doc') {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['txt', 'md', 'csv', 'json', 'log'],
        );
        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          String textContent;
          try {
            textContent = await file.readAsString();
          } catch (e) {
            if (mounted) {
              showErrorSnackBar(context, t.errors.cannotReadFile);
            }
            return;
          }
          final bytes = await file.readAsBytes();
          final url = 'http://local_doc_${const Uuid().v4()}.txt';
          await DefaultCacheManager().putFile(url, bytes, fileExtension: 'txt');
          if (!mounted) return;
          setState(() {
            _pendingAttachments.add(
              ChatAttachment(
                type: 'doc',
                bytes: bytes,
                url: url,
                fileName: result.files.single.name,
                fileSize: result.files.single.size,
                mimeType: 'text/plain',
                textContent: textContent,
              ),
            );
          });
        }
      }
    } catch (e, st) {
      appLogger.e(
        "Failed to process attachment selection",
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        showErrorSnackBar(
          context,
          "An error occurred while attaching the file.",
        );
      }
    }
  }

  // Sends the current input text and attached files securely to the LLM service.
  // Wraps the send operation in try/catch to notify the user if the message fails to queue.
  void _triggerSend(String text) {
    if (text.trim().isEmpty && _pendingAttachments.isEmpty) return;
    try {
      ref
          .read(chatLogicProvider.notifier)
          .sendMessage(
            text.trim(),
            attachments: List.from(_pendingAttachments),
          );
      setState(() {
        _pendingAttachments.clear();
        _composerController.clear();
      });
    } catch (e, st) {
      appLogger.e("Failed to submit chat message", error: e, stackTrace: st);
      showErrorSnackBar(context, "Failed to send message.");
    }
  }

  // Expands the input field into a full-screen editor modal for long messages.
  // Provides a dedicated send button that respects model readiness and attachment state.
  void _openExpandedComposer() {
    final t = Translations.of(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          appBar: AppBar(
            title: Text(t.chat.composePrompt),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final isModelReady =
                      ref.watch(modelStatusProvider) == ModelState.ready;
                  return ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _composerController,
                    builder: (context, value, child) {
                      final canSend =
                          isModelReady &&
                          (value.text.trim().isNotEmpty ||
                              _pendingAttachments.isNotEmpty);
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          label: Text(t.chat.send),
                          onPressed: canSend
                              ? () {
                                  Navigator.pop(context);
                                  _triggerSend(_composerController.text);
                                }
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _composerController,
              maxLines: null,
              expands: true,
              autofocus: true,
              textAlignVertical: TextAlignVertical.top,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: t.chat.writePromptHint,
                border: InputBorder.none,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // Generates visual component for any attachment in chat (images, audio, documents).
  // Handles missing file errors gracefully by showing a broken image icon or fallback text.
  Widget _buildUnifiedAttachmentBubble(
    Map att,
    bool isSentByMe,
    ThemeData theme,
  ) {
    final type = att['type'];
    final url = att['url'];
    final name = att['fileName'] ?? 'Attachment';

    if (type == 'photo') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isSentByMe ? Radius.zero : const Radius.circular(16),
            bottomLeft: !isSentByMe ? Radius.zero : const Radius.circular(16),
          ),
          color: isSentByMe
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
        ),
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: StreamBuilder<FileResponse>(
            stream: DefaultCacheManager().getFileStream(url),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox(
                  height: 150,
                  width: 250,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data is FileInfo) {
                return Image.file(
                  (snapshot.data as FileInfo).file,
                  width: 250,
                  fit: BoxFit.contain,
                );
              }
              return const SizedBox(
                height: 150,
                width: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSentByMe
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: isSentByMe ? Radius.zero : const Radius.circular(16),
          bottomLeft: !isSentByMe ? Radius.zero : const Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == 'audio' ? Icons.audio_file : Icons.insert_drive_file,
            color: isSentByMe
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            size: 28,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              name,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isSentByMe
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Composes the sticky bottom navigation chat bar taking active attachments and model readiness into account.
  // Dynamically switches between send and stop buttons based on the LLM generation state.
  Widget _buildCustomComposer(BuildContext context, ThemeData theme) {
    final t = Translations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ).copyWith(top: 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            if (_pendingAttachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                  left: 48,
                  right: 48,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _pendingAttachments.map((att) {
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 4),
                      color: theme.colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            if (att.type == 'photo')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  att.bytes,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  att.type == 'audio'
                                      ? Icons.audio_file
                                      : Icons.insert_drive_file,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                att.fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(
                                () => _pendingAttachments.remove(att),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: theme.colorScheme.primary,
                  onPressed: _handleAttachmentTap,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.only(left: 16, right: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _composerController,
                            maxLines: 4,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: t.chat.messageHint,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: IconButton(
                            icon: const Icon(Icons.open_in_full),
                            iconSize: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: _openExpandedComposer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Consumer(
                  builder: (context, ref, child) {
                    final isModelReady =
                        ref.watch(modelStatusProvider) == ModelState.ready;
                    final isGenerating = ref.watch(isGeneratingProvider);
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _composerController,
                      builder: (context, value, child) {
                        final canSend =
                            isModelReady &&
                            !isGenerating &&
                            (value.text.trim().isNotEmpty ||
                                _pendingAttachments.isNotEmpty);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: IconButton.filled(
                            icon: Icon(
                              isGenerating ? Icons.stop : Icons.arrow_upward,
                            ),
                            onPressed: isGenerating
                                ? () => ref
                                      .read(chatLogicProvider.notifier)
                                      .stopGeneration()
                                : canSend
                                ? () => _triggerSend(_composerController.text)
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Builds the main chat interface with a scrollable message list and a custom composer.
  // Listens for app updates and handles safe session flushing when the user navigates back.
  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    ref.listen(updaterControllerProvider, (previous, next) {
      if (next is UpdateAvailable && previous is! UpdateAvailable) {
        showInfoSnackBar(
          context,
          t.settings.updateAvailableSnackbar(version: next.info.version),
        );
      }
    });

    final chatController = ref.watch(chatLogicProvider);
    final appTheme = Theme.of(context);
    final chatTheme = ChatTheme.fromThemeData(appTheme);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          try {
            await ref.read(chatLogicProvider.notifier).loadSession(null);
          } catch (e) {
            appLogger.w("Failed to flush session safely on pop", error: e);
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const ModelStatusAppBarTitle(),
          centerTitle: true,
        ),
        drawer: const ChatDrawer(),
        body: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                child: Chat(
                  key: ValueKey(chatController.hashCode),
                  chatController: chatController,
                  currentUserId: 'user',
                  theme: chatTheme,
                  builders: Builders(
                    composerBuilder: (context) => const SizedBox.shrink(),
                    customMessageBuilder:
                        (
                          context,
                          core.CustomMessage message,
                          int index, {
                          required bool isSentByMe,
                          core.MessageGroupStatus? groupStatus,
                        }) {
                          final msgType = message.metadata?['type'] as String?;
                          if (msgType == 'typing') {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: appTheme
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: appTheme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          } else if (msgType == 'stream') {
                            final streamId =
                                message.metadata!['streamId'] as String;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final streamState = ref.watch(
                                    chatStreamManagerProvider.select(
                                      (s) => s[streamId],
                                    ),
                                  );
                                  final isGenerating = ref.watch(
                                    isGeneratingProvider,
                                  );
                                  final text = streamState?.text ?? '';
                                  final thinking = streamState?.thinking ?? '';
                                  return Padding(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (thinking.isNotEmpty)
                                          ThinkingWidget(
                                            thinkingContent: thinking,
                                            isGenerating:
                                                isGenerating && text.isEmpty,
                                          ),
                                        if (text.isNotEmpty || thinking.isEmpty)
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: appTheme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    16,
                                                  ).copyWith(
                                                    bottomLeft: Radius.zero,
                                                  ),
                                            ),
                                            child: ThrottledMarkdownWidget(
                                              text: text.isEmpty
                                                  ? t.chat.generating
                                                  : text,
                                              isGenerating: isGenerating,
                                              style: appTheme
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: appTheme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                          final text =
                              message.metadata?['text'] as String? ?? '';
                          final atts =
                              message.metadata?['attachments'] as List? ?? [];
                          final thinking =
                              message.metadata?['thinking'] as String? ?? '';
                          return Padding(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: isSentByMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (thinking.isNotEmpty)
                                  ThinkingWidget(
                                    thinkingContent: thinking,
                                    isGenerating: false,
                                  ),
                                if (atts.isNotEmpty)
                                  ...atts.map(
                                    (att) => _buildUnifiedAttachmentBubble(
                                      att,
                                      isSentByMe,
                                      appTheme,
                                    ),
                                  ),
                                if (text.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSentByMe
                                          ? appTheme
                                                .colorScheme
                                                .primaryContainer
                                          : appTheme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16)
                                          .copyWith(
                                            bottomRight: isSentByMe
                                                ? Radius.zero
                                                : const Radius.circular(16),
                                            bottomLeft: !isSentByMe
                                                ? Radius.zero
                                                : const Radius.circular(16),
                                          ),
                                    ),
                                    child: GptMarkdown(
                                      text,
                                      style: appTheme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: isSentByMe
                                                ? appTheme
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                : appTheme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 2,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.content_copy,
                                            size: 18,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          tooltip: t.chat.copyMessage,
                                          onPressed: () {
                                            Clipboard.setData(
                                              ClipboardData(text: text),
                                            );
                                            if (mounted) {
                                              showInfoSnackBar(
                                                context,
                                                t.chat.copiedToClipboard,
                                              );
                                            }
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: t.chat.deleteMessageGroup,
                                        onPressed: () =>
                                            _confirmDeleteMessage(message.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                    textMessageBuilder:
                        (
                          context,
                          core.TextMessage message,
                          int index, {
                          required bool isSentByMe,
                          core.MessageGroupStatus? groupStatus,
                        }) {
                          return Padding(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: isSentByMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (message.text.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSentByMe
                                          ? appTheme
                                                .colorScheme
                                                .primaryContainer
                                          : appTheme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16)
                                          .copyWith(
                                            bottomRight: isSentByMe
                                                ? Radius.zero
                                                : const Radius.circular(16),
                                            bottomLeft: !isSentByMe
                                                ? Radius.zero
                                                : const Radius.circular(16),
                                          ),
                                    ),
                                    child: GptMarkdown(
                                      message.text,
                                      style: appTheme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: isSentByMe
                                                ? appTheme
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                : appTheme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 2,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.content_copy,
                                          size: 18,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: t.chat.copyMessage,
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: message.text),
                                          );
                                          if (mounted) {
                                            showInfoSnackBar(
                                              context,
                                              t.chat.copiedToClipboard,
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: t.chat.deleteMessage,
                                        onPressed: () =>
                                            _confirmDeleteMessage(message.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                  ),
                  resolveUser: (core.UserID id) async {
                    return core.User(
                      id: id,
                      name: id == 'user' ? t.chat.userName : t.chat.aiName,
                    );
                  },
                  onMessageSend: _triggerSend,
                ),
              ),
            ),
            _buildCustomComposer(context, appTheme),
          ],
        ),
      ),
    );
  }
}

// Custom Stateless Widget representing an attachment option in the bottom sheet.
// Visually disables itself if the selected model doesn't support the attachment type.
class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.extensions,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final String extensions;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: enabled
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: enabled ? theme.colorScheme.onPrimaryContainer : color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              extensions,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
