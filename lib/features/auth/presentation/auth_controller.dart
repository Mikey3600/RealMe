import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/providers.dart';
import '../../auth/data/firebase_auth_repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/user_entity.dart';

// --- Providers ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseAuthRepository(
    firebaseAuth: firebaseAuth,
    googleSignIn: GoogleSignIn(),
  );
});

final authUserProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

// --- Controller ---

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    final result = await _repository.signInWithGoogle();

    result.fold(
      (user) {
        state = const AsyncValue.data(null);
      },
      (error) {
        state = AsyncValue.error(error, error.stackTrace ?? StackTrace.current);
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}
