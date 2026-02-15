import '../../../core/errors/result.dart';
import 'user_entity.dart';

/// Defines the contract for authentication operations.
///
/// This repository is responsible for abstracting the underlying authentication
/// provider (e.g., Firebase Auth) and converting external types to domain entities.
abstract class AuthRepository {
  /// Stream of the current authenticated user.
  ///
  /// Emits [Result.success] with [UserEntity] when a user is logged in.
  /// Emits [Result.success] with `null` (or handles it via specific failure) if logged out.
  /// *Design decision*: Streaming `UserEntity?` allows real-time auth state listening.
  Stream<UserEntity?> get currentUser;

  /// Signs in the user using Google Authentication.
  ///
  /// Returns a [Result] containing the authenticated [UserEntity] on success,
  /// or a [Failure] on error.
  Future<Result<UserEntity>> signInWithGoogle();

  /// Signs out the current user.
  ///
  /// Returns a [Result] containing `void` on success.
  Future<Result<void>> signOut();
}
