import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/router/app_router.dart';

import '../application/chat_provider.dart';

@RoutePage()
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    String title,
  ) {
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
              ref.read(chatLogicProvider.notifier).deleteSession(sessionId);
              Navigator.pop(ctx);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gemma Local AI'), centerTitle: true),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 20,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Gemma AI",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(chatLogicProvider.notifier).loadSession(null);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('New Chat'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "RECENT",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
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
                    selectedTileColor: theme.colorScheme.primaryContainer
                        .withOpacity(0.5),
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      color: isActive ? theme.colorScheme.primary : null,
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
                      color: theme.colorScheme.error,
                      onPressed: () => _confirmDelete(
                        context,
                        ref,
                        session.id,
                        session.title,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (!isActive) {
                        ref
                            .read(chatLogicProvider.notifier)
                            .loadSession(session.id);
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
                Navigator.pop(context);
                context.router.push(const SettingsRoute());
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      body: Chat(
        key: ValueKey(chatController.hashCode),
        chatController: chatController,
        currentUserId: 'user',
        resolveUser: (core.UserID id) async {
          return core.User(id: id, name: id == 'user' ? 'Me' : 'Gemma AI');
        },
        onMessageSend: (String text) {
          ref.read(chatLogicProvider.notifier).sendMessage(text);
        },
      ),
    );
  }
}
