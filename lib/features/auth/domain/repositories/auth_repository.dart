import '../models/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
}

sealed class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Email немесе құпиясөз қате.');
}

final class EmailAlreadyUsedException extends AuthException {
  const EmailAlreadyUsedException()
    : super('Бұл email мекенжайымен аккаунт бұрын тіркелген.');
}

final class EmailConfirmationRequiredException extends AuthException {
  const EmailConfirmationRequiredException()
    : super('Аккаунт құрылды. Email хаты арқылы мекенжайыңызды растаңыз, содан кейін кіріңіз.');
}

final class AuthServiceException extends AuthException {
  const AuthServiceException()
    : super('Қазір аккаунт қызметіне қосыла алмадық. Кейінірек қайталаңыз.');
}
