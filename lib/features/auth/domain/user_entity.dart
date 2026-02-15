/// Represents a user in the application domain.
///
/// This entity is immutable and decoupled from any specific data source implementation
/// (like Firebase Auth User or Firestore document).
class UserEntity {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime? lastSeen;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.lastSeen,
  });

  /// Creates a copy of this user with the given fields replaced with the new values.
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? lastSeen,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserEntity &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.lastSeen == lastSeen;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoUrl.hashCode ^
        lastSeen.hashCode;
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, displayName: $displayName, photoUrl: $photoUrl, lastSeen: $lastSeen)';
  }
}
