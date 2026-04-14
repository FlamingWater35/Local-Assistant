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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatController = ref.watch(chatLogicProvider);
    final history = ref.watch(chatHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gemma Local AI'), centerTitle: true),
      drawer: Drawer(
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(chatLogicProvider.notifier).loadSession(null);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Start New Chat'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final session = history[index];
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      ref
                          .read(chatLogicProvider.notifier)
                          .loadSession(session.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings & Models'),
              onTap: () {
                Navigator.pop(context);
                context.router.push(const SettingsRoute());
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Chat(
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
