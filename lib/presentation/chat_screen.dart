import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:local_assistant/router/app_router.dart';

import '../application/chat_provider.dart';
import '../core/logger.dart';
import '../core/snackbar_helper.dart';

@RoutePage()
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    String title,
  ) {
    appLogger.i("UI: Opened delete confirmation for chat: $title");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete "$title"?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              appLogger.i("UI: Deleting chat session ID: $sessionId");
              ref.read(chatLogicProvider.notifier).deleteSession(sessionId);
              Navigator.pop(ctx);
              if (context.mounted) {
                showSuccessSnackBar(context, 'Chat deleted');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(
    BuildContext context,
    WidgetRef ref,
    String messageId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              appLogger.i("UI: Deleting message ID: $messageId");
              await ref
                  .read(chatLogicProvider.notifier)
                  .deleteMessage(messageId);
              if (context.mounted) {
                Navigator.pop(ctx);
                showSuccessSnackBar(context, 'Message deleted');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        appBar: AppBar(
          title: const Text('Gemma Local AI'),
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
                Container(
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 20,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: appTheme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: appTheme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Gemma AI",
                        style: appTheme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                    label: const Text('New Chat'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    "RECENT",
                    style: appTheme.textTheme.labelSmall?.copyWith(
                      color: appTheme.colorScheme.outline,
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final session = history[index];
                      final isActive = session.id == activeSessionId;

                      return ListTile(
                        selected: isActive,
                        selectedTileColor: appTheme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: isActive ? appTheme.colorScheme.primary : null,
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: appTheme.colorScheme.error,
                          onPressed: () => _confirmDelete(
                            context,
                            ref,
                            session.id,
                            session.title,
                          ),
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
                      );
                    },
                  ),
                ),
                const Divider(height: 1),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings & Models'),
                  onTap: () {
                    appLogger.i("UI: Navigating to Settings.");
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.router.push(const SettingsRoute());
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Chat(
            key: ValueKey(chatController.hashCode),
            chatController: chatController,
            currentUserId: 'user',

            theme: chatTheme,

            builders: Builders(
              textMessageBuilder:
                  (
                    context,
                    core.TextMessage message,
                    int index, {
                    required bool isSentByMe,
                    core.MessageGroupStatus? groupStatus,
                  }) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                : appTheme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16).copyWith(
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
                            style: appTheme.textTheme.bodyLarge?.copyWith(
                              color: isSentByMe
                                  ? appTheme.colorScheme.onPrimaryContainer
                                  : appTheme.colorScheme.onSurfaceVariant,
                            ),
                            useDollarSignsForLatex: true,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 2,
                            bottom: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.content_copy, size: 18),
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Copy message',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: message.text),
                                  );
                                  if (context.mounted) {
                                    showInfoSnackBar(
                                      context,
                                      'Copied to clipboard',
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
                                tooltip: 'Delete message',
                                onPressed: () {
                                  _confirmDeleteMessage(
                                    context,
                                    ref,
                                    message.id,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
            ),

            resolveUser: (core.UserID id) async {
              return core.User(id: id, name: id == 'user' ? 'Me' : 'Gemma AI');
            },
            onMessageSend: (String text) {
              appLogger.i("UI: Send button pressed.");
              ref.read(chatLogicProvider.notifier).sendMessage(text);
            },
          ),
        ),
      ),
    );
  }
}
