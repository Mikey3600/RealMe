import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/message_entity.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';

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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: EmptyStateWidget(
                        // FIX 1 & 2: Added required parameters
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No messages yet',
                        subtitle: 'Be the first to say hello!',
                      ),
                    );
                  }
                  // Using Slivers for maximum smoothness during keyboard pop-up
                  return CustomScrollView(
                    reverse: true,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final msg = messages[index];
                              final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
                              final isMe = msg.senderId == uid;
                              return MessageBubble(message: msg, isMe: isMe);
                            },
                            childCount: messages.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: EmptyStateWidget(
                    // FIX: Ensuring error state also has required parameters
                    icon: Icons.error_outline_rounded,
                    title: 'Connection Error',
                    subtitle: err.toString(),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    // FIX 3: Changed withOpacity to withValues to satisfy linter
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ChatInput(
                onSendText: (text) => _sendMessage(ref, text, MessageType.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(WidgetRef ref, String content, MessageType type) {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    final message = MessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: uid,
      receiverId: otherUserId,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      type: type,
    );
    ref.read(chatRepositoryProvider).sendMessage(message);
  }
}