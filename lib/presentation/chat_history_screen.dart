import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/application/chat_provider.dart';
import 'package:local_assistant/core/logger.dart';
import 'package:local_assistant/core/snackbar_helper.dart';
import 'package:local_assistant/domain/models.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';

// Full-screen scrollable list of all past chat sessions.
// Provides search functionality and secure deletion with error feedback.
@RoutePage()
class ChatHistoryScreen extends ConsumerStatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  ConsumerState<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends ConsumerState<ChatHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filters the global session list based on the user's search input.
  // Performs case-insensitive substring matching on session titles.
  List<ChatSession> _filterSessions(List<ChatSession> sessions) {
    if (_searchQuery.isEmpty) return sessions;
    return sessions
        .where(
          (session) =>
              session.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  // Opens a confirmation dialog and securely attempts to delete a chat session.
  // Wraps the deletion in try/catch to notify the user if the database operation fails.
  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    String title,
  ) {
    final t = Translations.of(context);
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
                await ref
                    .read(chatLogicProvider.notifier)
                    .deleteSession(sessionId);
                if (context.mounted) {
                  showSuccessSnackBar(context, t.chat.chatDeleted);
                }
              } catch (e, st) {
                appLogger.e(
                  "Error deleting chat from history",
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

  // Formats a Unix timestamp into a human-readable relative date string.
  // Returns 'Today', 'Yesterday', 'X days ago', or the full date for older sessions.
  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Builds the main UI with a search bar and a scrollable list of filtered sessions.
  // Uses RepaintBoundary to optimize rendering performance of the long list.
  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final allSessions = ref.watch(chatHistoryProvider);
    final activeSessionId = ref
        .watch(chatLogicProvider.notifier)
        .currentSessionId;
    final filteredSessions = _filterSessions(allSessions);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.chat.chatHistory),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: t.chat.searchHistory,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: filteredSessions.isEmpty
          ? Center(
              child: Text(
                _searchQuery.isEmpty ? t.chat.noHistory : t.chat.noResults,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : RepaintBoundary(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                itemCount: filteredSessions.length,
                itemBuilder: (context, index) {
                  final session = filteredSessions[index];
                  final isActive = session.id == activeSessionId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isActive ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isActive
                          ? BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        session.title,
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(session.updatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: theme.colorScheme.error,
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
                            "UI: Loading existing chat from history: ${session.title}",
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
    );
  }
}
