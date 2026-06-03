import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/application/chat_provider.dart';
import 'package:local_assistant/core/logger.dart';
import 'package:local_assistant/core/snackbar_helper.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';
import 'package:local_assistant/router/app_router.dart';

// Side drawer component displaying recent chat history and navigation links.
// Provides quick access to create new chats, view all history, and open settings.
class ChatDrawer extends ConsumerWidget {
  const ChatDrawer({super.key});

  // Opens a confirmation dialog and securely attempts to delete a chat session.
  // Wraps the deletion in try/catch to notify the user if the operation fails.
  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    String title,
  ) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                appLogger.i("UI: Deleting chat session ID: $sessionId");
                await ref
                    .read(chatLogicProvider.notifier)
                    .deleteSession(sessionId);
                if (context.mounted) {
                  showSuccessSnackBar(context, t.chat.chatDeleted);
                }
              } catch (e, st) {
                appLogger.e(
                  "UI: Failed to delete chat",
                  error: e,
                  stackTrace: st,
                );
                if (context.mounted) {
                  showErrorSnackBar(context, t.errors.failedToDeleteChat);
                }
              }
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

  // Builds the drawer UI with a header, new chat button, recent history list, and settings link.
  // Uses RepaintBoundary to optimize rendering performance of the chat list.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final history = ref.watch(chatHistoryProvider);
    final activeSessionId = ref
        .watch(chatLogicProvider.notifier)
        .currentSessionId;
    final appTheme = Theme.of(context);
    final recentHistory = history.take(20).toList();

    return Drawer(
      backgroundColor: appTheme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section with app logo and title
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
            // Button to start a new chat session
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FilledButton.icon(
                onPressed: () {
                  appLogger.i("UI: Starting new chat from drawer.");
                  Navigator.pop(context);
                  ref.read(chatLogicProvider.notifier).loadSession(null);
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
            const SizedBox(height: 24),
            // Section header for recent chat history
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                t.chat.recentHistory.toUpperCase(),
                style: appTheme.textTheme.labelSmall?.copyWith(
                  color: appTheme.colorScheme.outline,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            // Scrollable list of recent chat sessions
            Expanded(
              child: RepaintBoundary(
                child: Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: recentHistory.length,
                    itemBuilder: (context, index) {
                      final session = recentHistory[index];
                      final isActive = session.id == activeSessionId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: isActive,
                          selectedTileColor:
                              appTheme.colorScheme.secondaryContainer,
                          leading: Icon(
                            isActive
                                ? Icons.chat_bubble
                                : Icons.chat_bubble_outline,
                            color: isActive
                                ? appTheme.colorScheme.onSecondaryContainer
                                : appTheme.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isActive
                                  ? appTheme.colorScheme.onSecondaryContainer
                                  : appTheme.colorScheme.onSurface,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: appTheme.colorScheme.error.withValues(
                              alpha: 0.8,
                            ),
                            onPressed: () => _confirmDelete(
                              context,
                              ref,
                              session.id,
                              session.title,
                            ),
                          ),
                          onTap: () {
                            if (!isActive) {
                              appLogger.i(
                                "UI: Loading existing chat: ${session.title}",
                              );
                              Navigator.pop(context);
                              ref
                                  .read(chatLogicProvider.notifier)
                                  .loadSession(session.id);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Link to view the complete chat history screen
            if (history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.router.push(const ChatHistoryRoute());
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: Text(t.chat.viewAllHistory),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const Divider(height: 1),
            // Link to open the settings and model management screen
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(Icons.settings_outlined),
                title: Text(
                  t.chat.settingsAndModels,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  appLogger.i("UI: Navigating to Settings.");
                  Navigator.pop(context);
                  context.router.push(const SettingsRoute());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
