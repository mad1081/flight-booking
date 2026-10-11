import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authStoreProvider = Provider<AuthStore>((ref) => PreferencesAuthStore());
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(ref.watch(authStoreProvider)),
);
final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  @override
  Future<AppUser?> build() => _repository.restoreSession();
  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signIn(email: email, password: password),
    );
    return !state.hasError;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.register(name: name, email: email, password: password),
    );
    return !state.hasError;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signOut();
      return null;
    });
  }

  void continueAsGuest() => state = const AsyncData(null);
}

String authErrorMessage(Object error) =>
    error is AuthException ? error.message : 'Қате орын алды. Қайта көріңіз.';
