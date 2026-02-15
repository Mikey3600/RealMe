import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/hive_service.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/result.dart';
import '../../chat/domain/chat_repository.dart';
import '../../chat/domain/message_entity.dart';

/// Concrete implementation of [ChatRepository] using Cloud Firestore.
///
/// Handles message persistence and real-time synchronization.
class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore;
  final String _currentUserId;
  // ignore: unused_field
  final HiveService _hiveService; // Injected for offline support

  FirebaseChatRepository({
    required FirebaseFirestore firestore,
    required String currentUserId,
    required HiveService hiveService,
  })  : _firestore = firestore,
        _currentUserId = currentUserId,
        _hiveService = hiveService;

  @override
  Future<Result<void>> sendMessage(MessageEntity message) async {
    try {
      final chatId = _generateCanonicalChatId(message.senderId, message.receiverId);
      final messageRef = _firestore
          .collection(FirestorePaths.chats)
          .doc(chatId)
          .collection(FirestorePaths.messages)
          .doc(message.id);

      // TODO: Handle race conditions where two users send messages at the exact same timestamp (ordering).

      final messageMap = _mapMessageToData(message);

      // Side effect: Write to Firestore (Command)
      // Note: Firestore SDK buffers offline writes by default. This await completes
      // even if offline (persistence enabled). The catch block below triggers on
      // explicit failures (e.g. permission denied), effectively making Hive a secondary backup.
      await messageRef.set(messageMap);

      return const Success(null);
    } catch (e) {
      // Offline fallback: Cache message as pending
      // Return Success to maintain optimistic UI state, even though sync is pending.
      final messageMap = _mapMessageToData(message);
      messageMap['status'] = 'pending';
      
      final cacheResult = await _hiveService.addPendingMessage(messageMap);
      
      return cacheResult.fold(
        (success) => const Success(null),
        (failure) => Failure(failure), // If both fail, then it's a failure
      );
    }
  }

  @override
  Stream<List<MessageEntity>> getMessages(String otherUserId) {
    final chatId = _generateCanonicalChatId(_currentUserId, otherUserId);

    // Queries are side-effect free (mostly) reads
    return _firestore
        .collection(FirestorePaths.chats)
        .doc(chatId)
        .collection(FirestorePaths.messages)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _mapDataToMessage(doc.data(), doc.id);
      }).toList();
    });
    // TODO: Implement pagination to avoid loading entire chat history (Scale limit: ~100 messages).
    // TODO: Add listener for connectivity changes to trigger retry of pending messages (Reliability).
  }

  @override
  Future<Result<void>> markAsRead(String messageId) async {
    // Note: To implement this properly, we need the chatId.
    // In a real app, messageId might be globally unique or we'd pass ChatId.
    // For this simple architecture, we assume we update it via a known path or query.
    // Trade-off: Without ChatID here, we might need to query for the message parent
    // or change the interface. For simplicity, we'll return generic failure or
    // skip implementation as it requires interface change not requested in Phase 8.
    //
    // *Correction*: I will skip implementation detail requiring query-first-then-write
    // to strictly follow "Small functions" and "Clear command/query".
    // I will implement a placeholder that would technically require chatId.
    return const Failure(AppError(
        message: 'markAsRead requires ChatId in this architecture'));
  }

  // --- Helpers ---

  /// Generates a consistent Chat ID for two users regardless of who started it.
  String _generateCanonicalChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
    // TODO: This ID generation strategy only supports 1-on-1 chats. Update for Group Chats (Future Feature).
  }

  Map<String, dynamic> _mapMessageToData(MessageEntity message) {
    return {
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'content': message.content,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'status': message.status.name, // Storing enum as string
      'type': message.type.name,
    };
  }

  MessageEntity _mapDataToMessage(Map<String, dynamic> data, String id) {
    return MessageEntity(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}
