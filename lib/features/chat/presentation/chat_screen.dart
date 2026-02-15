import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/message_entity.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';
import '../../../core/widgets/empty_state.dart';

// Stream provider for messages
final chatMessagesProvider = StreamProvider.family<List<MessageEntity>, String>((ref, otherUserId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(otherUserId);
});

class ChatScreen extends ConsumerWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(otherUserId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chat with $otherUserId', 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    subtitle: 'Say hello to start the conversation!',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final currentUserId = ref.read(firebaseAuthProvider).currentUser?.uid;
                    final isMe = msg.senderId == currentUserId;

                    return MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => EmptyStateWidget(
                icon: Icons.error_outline_rounded,
                title: 'Something went wrong',
                subtitle: err.toString(),
                onRetry: () => ref.refresh(chatMessagesProvider(otherUserId)),
              ),
            ),
          ),
          ChatInput(
            onSendText: (text) {
              final currentUserId = ref.read(firebaseAuthProvider).currentUser?.uid;
              if (currentUserId == null) return;

              final newMessage = MessageEntity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                senderId: currentUserId,
                receiverId: otherUserId,
                content: text,
                timestamp: DateTime.now(),
                status: MessageStatus.pending,
                type: MessageType.text,
              );

              ref.read(chatRepositoryProvider).sendMessage(newMessage);
            },
            onSendVoice: (url) {
              final currentUserId = ref.read(firebaseAuthProvider).currentUser?.uid;
              if (currentUserId == null) return;

              final newMessage = MessageEntity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                senderId: currentUserId,
                receiverId: otherUserId,
                content: url, // Access Token/URL
                timestamp: DateTime.now(),
                status: MessageStatus.pending,
                type: MessageType.audio,
              );

              ref.read(chatRepositoryProvider).sendMessage(newMessage);
            },
          ),
        ],
      ),
    );
  }
}
