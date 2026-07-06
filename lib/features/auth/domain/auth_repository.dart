import 'user_entity.dart';

/// Contract definition for Authentication functionalities in domain layer.
abstract class AuthRepository {
  /// Stream to listen to auth state updates.
  Stream<UserEntity?> get authStateChanges;

  /// Fetch cached or live current authenticated user details.
  Future<UserEntity?> getCurrentUser();

  /// Authenticate user via email and password credentials.
  /// Throws [AuthFailure] on errors.
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Register a new user account.
  /// Throws [AuthFailure] on errors.
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign out current session and flush local tokens.
  Future<void> signOut();

  /// Updates company setup association link.
  Future<void> updateUserCompanyAssociation(String uid, String companyId);
}
