/// centralizes all Firestore collection paths to avoid magic strings.
class FirestorePaths {
  // Prevent instantiation
  FirestorePaths._();

  static const String users = 'users';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String calls = 'calls';
  static const String presence = 'presence';
}
