import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/auth/data/repositories/local_auth_repository.dart';
import 'package:qanat/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('LocalAuthRepository', () {
    late MemoryAuthStore store;
    late LocalAuthRepository repository;

    setUp(() {
      store = MemoryAuthStore();
      repository = LocalAuthRepository(store);
    });

    test(
      'register normalizes email and creates a restorable session',
      () async {
        final user = await repository.register(
          name: '  Ayan Serik  ',
          email: '  AYAN@EXAMPLE.COM ',
          password: 'Qanat123',
        );

        expect(user.name, 'Ayan Serik');
        expect(user.email, 'ayan@example.com');
        expect(await repository.restoreSession(), same(user));
      },
    );

    test('registered account can sign in after logout', () async {
      final registered = await repository.register(
        name: 'Ayan',
        email: 'ayan@example.com',
        password: 'Qanat123',
      );
      await repository.signOut();

      expect(await repository.restoreSession(), isNull);
      final signedIn = await repository.signIn(
        email: 'AYAN@example.com',
        password: 'Qanat123',
      );
      expect(signedIn.id, registered.id);
    });

    test('rejects duplicate email regardless of case', () async {
      await repository.register(
        name: 'Ayan',
        email: 'ayan@example.com',
        password: 'Qanat123',
      );

      expect(
        () => repository.register(
          name: 'Other',
          email: 'AYAN@EXAMPLE.COM',
          password: 'Other123',
        ),
        throwsA(isA<EmailAlreadyUsedException>()),
      );
    });

    test('rejects an incorrect password', () async {
      await repository.register(
        name: 'Ayan',
        email: 'ayan@example.com',
        password: 'Qanat123',
      );

      expect(
        () =>
            repository.signIn(email: 'ayan@example.com', password: 'Wrong123'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });
  });
}
