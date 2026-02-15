import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/message_entity.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers.dart';

class MessageBubble extends ConsumerWidget {
  final MessageEntity message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceHighlight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.type == MessageType.audio)
              _buildAudioPlayer(context, ref)
            else
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isMe ? AppColors.background : AppColors.textPrimary,
                      fontSize: 16,
                    ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isMe
                            ? AppColors.background.withOpacity(0.7)
                            : AppColors.textFaint,
                        fontSize: 10,
                      ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(message.status),
                    size: 12,
                    color: AppColors.background.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.play_arrow_rounded,
            color: isMe ? AppColors.background : AppColors.textPrimary,
            size: 32,
          ),
          onPressed: () async {
            final result = await ref.read(voicePlayerServiceProvider).play(message.content);
            result.fold(
              (_) {}, // Success
              (error) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Playback failed: ${error.message}')),
              ),
            );
          },
        ),
        Text(
          'Voice Note',
          style: TextStyle(
            color: isMe ? AppColors.background : AppColors.textPrimary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.pending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
    }
  }
}
