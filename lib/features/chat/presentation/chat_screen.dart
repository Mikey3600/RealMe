import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/message_entity.dart';

// Placeholder provider for messages - to be implemented properly in a real ChatController
final chatMessagesProvider = StreamProvider.family<List<MessageEntity>, String>((ref, otherUserId) {
  return const Stream.empty();
});

class ChatScreen extends ConsumerWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(otherUserId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                reverse: true, // Show newest messages at the bottom
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return ListTile(
                    title: Text(msg.content),
                    subtitle: Text(msg.senderId),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    key: Key('message_input'),
                    decoration: InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  key: const Key('send_button'),
                  onPressed: () {
                    // Send logic placeholder
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
