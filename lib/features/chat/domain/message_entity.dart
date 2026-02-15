/// Status of a message in the delivery pipeline.
enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
}

/// Type of content contained in the message.
enum MessageType {
  text,
  image,
  audio,
}

/// Represents a chat message in the domain layer.
///
/// Immutable and decoupled from data source implementation specifics.
class MessageEntity {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
  });

  MessageEntity copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    MessageType? type,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageEntity &&
        other.id == id &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.status == status &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        content.hashCode ^
        timestamp.hashCode ^
        status.hashCode ^
        type.hashCode;
  }

  @override
  String toString() {
    return 'MessageEntity(id: $id, content: $content, status: $status)';
  }
}
