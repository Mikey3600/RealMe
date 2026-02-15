import '../../../core/errors/result.dart';
import 'message_entity.dart';

/// Defines the contract for chat operations.
///
/// Abstracts the underlying data source (Firestore) for message handling.
abstract class ChatRepository {
  /// Sends a message between users.
  ///
  /// Returns [Result.success] if the message is handed off to the network layer successfully.
  Future<Result<void>> sendMessage(MessageEntity message);

  /// Retrieves a stream of messages exchanged with [otherUserId].
  ///
  /// Typically orders messages by timestamp descending (newest first) or ascending.
  Stream<List<MessageEntity>> getMessages(String otherUserId);

  /// Marks a specific message as read.
  Future<Result<void>> markAsRead(String messageId);
}
