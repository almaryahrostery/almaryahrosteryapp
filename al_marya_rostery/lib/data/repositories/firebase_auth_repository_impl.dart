import 'package:qahwat_al_emarat/domain/repositories/auth_repository.dart';
import 'package:qahwat_al_emarat/domain/models/auth_models.dart';
import 'package:qahwat_al_emarat/domain/models/auth_request_models.dart';
import '../datasources/firebase_auth_service.dart';
import '../../core/services/oauth_service.dart';

/// Firebase-based implementation of AuthRepository
class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _firebaseAuthService;
  final OAuthService _oauthService = OAuthService();

  FirebaseAuthRepositoryImpl(this._firebaseAuthService);

  @override
  Future<bool> isLoggedIn() async {
    return await _firebaseAuthService.isLoggedIn();
  }

  @override
  Future<User?> getCurrentUser() async {
    return await _firebaseAuthService.getCurrentUser();
  }

  @override
  Future<AuthResponse> login(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
    return await _firebaseAuthService.login(request);
  }

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    final request = RegisterRequest(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phone: phone,
    );
    return await _firebaseAuthService.register(request);
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    // Use OAuthService to get backend JWT token (not Firebase token!)
    final result = await _oauthService.signInWithGoogle();

    if (result['success'] != true) {
      throw AuthException(result['message'] ?? 'Google Sign-In failed');
    }

    // Get user data from Firebase
    final firebaseUser = await _firebaseAuthService.getCurrentUser();
    if (firebaseUser == null) {
      throw AuthException('Failed to get user data after Google Sign-In');
    }

    // Return AuthResponse with backend JWT token (30 days expiry)
    return AuthResponse(
      accessToken: result['token'],
      refreshToken: '', // Backend doesn't use refresh tokens for OAuth
      expiresIn: 2592000, // 30 days in seconds (30 * 24 * 60 * 60)
      tokenType: 'Bearer',
      user: firebaseUser,
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _firebaseAuthService.forgotPassword(email);
  }

  @override
  Future<void> resetPassword(
    String token,
    String password,
    String confirmPassword,
  ) async {
    // Firebase handles password reset via email link, not token-based
    // This method would typically redirect to Firebase Auth UI or handle deep links
    throw UnimplementedError(
      'Password reset via token not applicable for Firebase Auth. Use forgotPassword() instead.',
    );
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    await _firebaseAuthService.changePassword(
      currentPassword,
      newPassword,
      confirmPassword,
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    await _firebaseAuthService.sendEmailVerification();
  }

  @override
  Future<void> verifyEmail(String verificationToken) async {
    // Firebase handles email verification via email links, not tokens
    throw UnimplementedError(
      'Email verification via token not applicable for Firebase Auth. '
      'Use sendEmailVerification() and handle deep links instead.',
    );
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    return await _firebaseAuthService.refreshToken(refreshToken);
  }

  @override
  Future<AuthResponse> updateProfile(User updatedUser) async {
    await _firebaseAuthService.updateProfile(
      name: updatedUser.name,
      photoURL: updatedUser.avatar,
    );

    // Get current user's auth info to create proper response
    final currentUser = await _firebaseAuthService.getCurrentUser();
    if (currentUser == null) {
      throw AuthException('Failed to get updated user info');
    }

    return AuthResponse(
      accessToken: '', // Firebase handles tokens internally
      refreshToken: '',
      expiresIn: 3600,
      tokenType: 'Bearer',
      user: currentUser,
    );
  }

  @override
  Future<AuthResponse> updateProfileWithFile(
    String? name,
    String? phone,
    dynamic avatarFile,
  ) async {
    // For Firebase, we'd need to upload the file to Firebase Storage first
    // then update the profile with the download URL
    await _firebaseAuthService.updateProfile(
      name: name,
      // photoURL would be set after uploading avatarFile to Firebase Storage
    );

    // Get current user's auth info to create proper response
    final currentUser = await _firebaseAuthService.getCurrentUser();
    if (currentUser == null) {
      throw AuthException('Failed to get updated user info');
    }

    return AuthResponse(
      accessToken: '', // Firebase handles tokens internally
      refreshToken: '',
      expiresIn: 3600,
      tokenType: 'Bearer',
      user: currentUser,
    );
  }

  @override
  Future<void> logout() async {
    await _firebaseAuthService.logout();
  }
}
