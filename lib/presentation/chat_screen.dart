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
import 'package:local_assistant/application/updater_provider.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';
import 'package:local_assistant/router/app_router.dart';
import 'package:uuid/uuid.dart';

import '../application/chat_provider.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';
import '../domain/models.dart';

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

  void _confirmDelete(String sessionId, String title) {
    final t = Translations.of(context);
    appLogger.i("UI: Opened delete confirmation for chat: $title");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.chat.deleteChatTitle),
        content: Text(t.chat.deleteChatConfirm(title: title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              appLogger.i("UI: Deleting chat session ID: $sessionId");
              ref.read(chatLogicProvider.notifier).deleteSession(sessionId);
              Navigator.pop(ctx);
              if (mounted) {
                showSuccessSnackBar(context, t.chat.chatDeleted);
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

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
              appLogger.i("UI: Deleting unified message block ID: $messageId");
              await ref
                  .read(chatLogicProvider.notifier)
                  .deleteMessage(messageId);
              if (mounted && ctx.mounted) {
                Navigator.pop(ctx);
                showSuccessSnackBar(context, t.chat.messageDeleted);
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAttachmentTap() async {
    final t = Translations.of(context);
    if (_pendingAttachments.length >= 2) {
      showErrorSnackBar(context, t.chat.maxAttachments);
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(t.attachments.photo),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.audio_file),
              title: Text(t.attachments.audio),
              onTap: () => Navigator.pop(ctx, 'audio'),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(t.attachments.document),
              onTap: () => Navigator.pop(ctx, 'doc'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

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
        final bytes = await file.readAsBytes();
        final url = 'http://local_audio_${const Uuid().v4()}.wav';
        await DefaultCacheManager().putFile(url, bytes, fileExtension: 'wav');

        if (!mounted) return;
        setState(() {
          _pendingAttachments.add(
            ChatAttachment(
              type: 'audio',
              bytes: bytes,
              url: url,
              fileName: result.files.single.name,
              fileSize: result.files.single.size,
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
          appLogger.w(
            "File read error: User picked a non-text document",
            error: e,
          );
          if (mounted) {
            showErrorSnackBar(
              context,
              'Cannot read file. Please ensure it is a valid text document.',
            );
          }
          return;
        }

        if (textContent.length > 20000) {
          textContent =
              "${textContent.substring(0, 20000)}\n\n...[TRUNCATED due to length constraints]";
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
  }

  void _triggerSend(String text) {
    if (text.trim().isEmpty && _pendingAttachments.isEmpty) return;

    appLogger.i("UI: Send triggered.");
    ref
        .read(chatLogicProvider.notifier)
        .sendMessage(text.trim(), attachments: List.from(_pendingAttachments));

    setState(() {
      _pendingAttachments.clear();
      _composerController.clear();
    });
  }

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
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _composerController,
                builder: (context, value, child) {
                  final canSend =
                      value.text.trim().isNotEmpty ||
                      _pendingAttachments.isNotEmpty;
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

  Widget _buildCustomComposer(BuildContext context, ThemeData theme) {
    final t = Translations.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
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
                            .withAlpha(128),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _composerController,
                              maxLines: 2,
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
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _composerController,
                    builder: (context, value, child) {
                      final canSend =
                          value.text.trim().isNotEmpty ||
                          _pendingAttachments.isNotEmpty;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: IconButton.filled(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: canSend
                              ? () => _triggerSend(_composerController.text)
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    final history = ref.watch(chatHistoryProvider);
    final activeSessionId = ref
        .watch(chatLogicProvider.notifier)
        .currentSessionId;
    final isGenerating = ref.watch(isGeneratingProvider);

    final appTheme = Theme.of(context);
    final chatTheme = ChatTheme.fromThemeData(appTheme);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await ref.read(chatLogicProvider.notifier).loadSession(null);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(t.chat.title),
          centerTitle: true,
          actions: [
            if (isGenerating)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      appTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: appTheme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        t.chat.assistantName,
                        style: appTheme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: appTheme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FilledButton.icon(
                    onPressed: () async {
                      appLogger.i("UI: Starting new chat from drawer.");
                      await ref
                          .read(chatLogicProvider.notifier)
                          .loadSession(null);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(t.chat.newChat),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Text(
                    t.chat.recentHistory,
                    style: appTheme.textTheme.labelMedium?.copyWith(
                      color: appTheme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final session = history[index];
                      final isActive = session.id == activeSessionId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: isActive,
                          selectedTileColor:
                              appTheme.colorScheme.primaryContainer,
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: isActive
                                ? appTheme.colorScheme.onPrimaryContainer
                                : appTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isActive
                                  ? appTheme.colorScheme.onPrimaryContainer
                                  : appTheme.colorScheme.onSurface,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: appTheme.colorScheme.error,
                            onPressed: () =>
                                _confirmDelete(session.id, session.title),
                          ),
                          onTap: () async {
                            if (!isActive) {
                              appLogger.i(
                                "UI: Loading existing chat: ${session.title}",
                              );
                              await ref
                                  .read(chatLogicProvider.notifier)
                                  .loadSession(session.id);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(t.chat.settingsAndModels),
                    onTap: () {
                      appLogger.i("UI: Navigating to Settings.");
                      if (mounted) {
                        Navigator.pop(context);
                        context.router.push(const SettingsRoute());
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        body: RepaintBoundary(
          child: Chat(
            key: ValueKey(chatController.hashCode),
            chatController: chatController,
            currentUserId: 'user',
            theme: chatTheme,
            builders: Builders(
              composerBuilder: (context) =>
                  _buildCustomComposer(context, appTheme),
              customMessageBuilder:
                  (
                    context,
                    core.CustomMessage message,
                    int index, {
                    required bool isSentByMe,
                    core.MessageGroupStatus? groupStatus,
                  }) {
                    final text = message.metadata?['text'] as String? ?? '';
                    final atts =
                        message.metadata?['attachments'] as List? ?? [];

                    final isNewestMessage =
                        index == chatController.messages.length - 1;
                    final isThisMessageGenerating =
                        isGenerating && isNewestMessage && !isSentByMe;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isNewestMessage ? 64.0 : 0,
                      ),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: isSentByMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
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
                                      ? appTheme.colorScheme.primaryContainer
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
                                child: ThrottledMarkdownWidget(
                                  text: text,
                                  isGenerating: isThisMessageGenerating,
                                  style: appTheme.textTheme.bodyLarge?.copyWith(
                                    color: isSentByMe
                                        ? appTheme
                                              .colorScheme
                                              .onPrimaryContainer
                                        : appTheme.colorScheme.onSurfaceVariant,
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
                    final isNewestMessage =
                        index == chatController.messages.length - 1;
                    final isThisMessageGenerating =
                        isGenerating && isNewestMessage && !isSentByMe;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isNewestMessage ? 64.0 : 0,
                      ),
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: isSentByMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSentByMe
                                    ? appTheme.colorScheme.primaryContainer
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
                              child: ThrottledMarkdownWidget(
                                text: message.text,
                                isGenerating: isThisMessageGenerating,
                                style: appTheme.textTheme.bodyLarge?.copyWith(
                                  color: isSentByMe
                                      ? appTheme.colorScheme.onPrimaryContainer
                                      : appTheme.colorScheme.onSurfaceVariant,
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
                                    onPressed: () {
                                      _confirmDeleteMessage(message.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
    );
  }
}

class ThrottledMarkdownWidget extends StatefulWidget {
  const ThrottledMarkdownWidget({
    super.key,
    required this.text,
    required this.isGenerating,
    this.style,
  });

  final bool isGenerating;
  final TextStyle? style;
  final String text;

  @override
  State<ThrottledMarkdownWidget> createState() =>
      _ThrottledMarkdownWidgetState();
}

class _ThrottledMarkdownWidgetState extends State<ThrottledMarkdownWidget> {
  late String _displayedText;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant ThrottledMarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      if (!widget.isGenerating) {
        _timer?.cancel();
        setState(() {
          _displayedText = widget.text;
        });
      } else {
        if (_timer == null || !_timer!.isActive) {
          _timer = Timer(const Duration(milliseconds: 250), () {
            if (mounted) {
              setState(() {
                _displayedText = widget.text;
              });
            }
          });
        }
      }
    } else if (oldWidget.isGenerating && !widget.isGenerating) {
      _timer?.cancel();
      setState(() {
        _displayedText = widget.text;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _displayedText = widget.text;
  }

  @override
  Widget build(BuildContext context) {
    return GptMarkdown(
      _displayedText,
      style: widget.style,
      useDollarSignsForLatex: true,
    );
  }
}
