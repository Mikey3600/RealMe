import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/result.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/user_entity.dart';

/// Concrete implementation of [AuthRepository] using Firebase Authentication.
///
/// This class handles all direct interactions with Firebase and Google Sign-In,
/// isolating side effects and 3rd party exceptions from the domain layer.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  @override
  Stream<UserEntity?> get currentUser {
    return _firebaseAuth.userChanges().map((user) {
      if (user == null) return null;
      return _convertFirebaseUserToDomain(user);
    });
    // TODO: Handle token expiry and auto-refresh scenarios explicitly if needed for custom backend calls.
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Failure(AppError(message: 'Google sign in cancelled by user'));
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        return const Failure(AppError(message: 'Firebase sign in failed: User is null'));
      }

      return Success(_convertFirebaseUserToDomain(user));
    } on FirebaseAuthException catch (e) {
      return Failure(AppError(
        message: e.message ?? 'Authentication failed',
        code: e.code,
        stackTrace: StackTrace.current,
      ));
    } catch (e, stack) {
      return Failure(AppError(
        message: 'An unexpected error occurred during sign in',
        stackTrace: stack,
      ));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Success(null);
    } catch (e, stack) {
      return Failure(AppError(
        message: 'Failed to sign out',
        stackTrace: stack,
      ));
    }
  }

  /// Maps a Firebase [User] to a domain [UserEntity].
  UserEntity _convertFirebaseUserToDomain(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      // lastSeen is not provided by Auth User natively in a way needed for presence,
      // so we leave it null here or it would come from Firestore in a real app.
      lastSeen: null, 
    );
  }
}
