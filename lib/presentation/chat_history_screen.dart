import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/application/chat_provider.dart';
import 'package:local_assistant/core/snackbar_helper.dart';
import 'package:local_assistant/domain/models.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';

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

  List<ChatSession> _filterSessions(List<ChatSession> sessions) {
    if (_searchQuery.isEmpty) return sessions;
    return sessions
        .where(
          (session) =>
              session.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

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
            onPressed: () {
              ref.read(chatLogicProvider.notifier).deleteSession(sessionId);
              Navigator.pop(ctx);
              showSuccessSnackBar(context, t.chat.chatDeleted);
            },
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
  }

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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                    onTap: () async {
                      if (!isActive) {
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
    );
  }
}
