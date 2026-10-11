import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/auth/data/repositories/local_auth_repository.dart';
import 'package:qanat/features/auth/domain/models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('accounts and current session survive store recreation', () async {
    final firstStore = PreferencesAuthStore();
    final user = AppUser(
      id: 'user-1',
      name: 'Ayan Serik',
      email: 'ayan@example.com',
      createdAt: DateTime.utc(2026, 10, 11),
    );
    await firstStore.saveAccount(
      LocalAccount(user: user, passwordDigest: 'digest'),
    );
    await firstStore.saveSession(user);

    final recreatedStore = PreferencesAuthStore();
    final account = await recreatedStore.findAccount('AYAN@EXAMPLE.COM');
    final restoredUser = await recreatedStore.readSession();

    expect(account?.passwordDigest, 'digest');
    expect(restoredUser?.id, 'user-1');
    expect(restoredUser?.name, 'Ayan Serik');
  });

  test('logout clears only the session and keeps the account', () async {
    final store = PreferencesAuthStore();
    final user = AppUser(
      id: 'user-1',
      name: 'Ayan',
      email: 'ayan@example.com',
      createdAt: DateTime.utc(2026, 10, 11),
    );
    await store.saveAccount(LocalAccount(user: user, passwordDigest: 'digest'));
    await store.saveSession(user);
    await store.saveSession(null);

    expect(await PreferencesAuthStore().readSession(), isNull);
    expect(
      await PreferencesAuthStore().findAccount('ayan@example.com'),
      isNotNull,
    );
  });
}
