import 'package:qanat/features/auth/domain/models/app_user.dart';
import 'package:qanat/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Future<AppUser?> restoreSession() async =>
      _toAppUser(_client.auth.currentUser);

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'name': name.trim()},
      );
      if (result.session == null) {
        throw const EmailConfirmationRequiredException();
      }
      final user = _toAppUser(result.user);
      if (user == null) throw const AuthServiceException();
      return user;
    } on sb.AuthException catch (error) {
      if (error.message.toLowerCase().contains('already registered')) {
        throw const EmailAlreadyUsedException();
      }
      throw const AuthServiceException();
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = _toAppUser(result.user);
      if (user == null) throw const InvalidCredentialsException();
      return user;
    } on sb.AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid') || message.contains('confirm')) {
        throw const InvalidCredentialsException();
      }
      throw const AuthServiceException();
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AppUser? _toAppUser(sb.User? user) {
    if (user == null || user.email == null) return null;
    final name = user.userMetadata?['name'] as String?;
    return AppUser(
      id: user.id,
      name: name?.trim().isNotEmpty == true
          ? name!.trim()
          : user.email!.split('@').first,
      email: user.email!,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }
}
