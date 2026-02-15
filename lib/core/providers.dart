import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/presence/presence_service.dart';
import '../services/hive_service.dart';
import '../features/chat/domain/chat_repository.dart';
import '../features/chat/data/firebase_chat_repository.dart';
import '../features/auth/presentation/auth_controller.dart';

// --- Firebase Instances ---

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// --- Core Services ---

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

// --- Feature Services ---

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  
  final service = PresenceService(auth: auth, firestore: firestore);
  
  // Lifecycle: Dispose service when provider is destroyed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// --- Repository Providers ---

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final authUser = ref.watch(authUserProvider).value;
  final hive = ref.watch(hiveServiceProvider);
  
  return FirebaseChatRepository(
    firestore: firestore,
    currentUserId: authUser?.id ?? '',
    hiveService: hive,
  );
});
