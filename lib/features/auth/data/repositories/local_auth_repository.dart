import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class LocalAccount {
  const LocalAccount({required this.user, required this.passwordDigest});

  final AppUser user;
  final String passwordDigest;

  Map<String, Object?> toJson() => {
    'user': {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'createdAt': user.createdAt.toIso8601String(),
    },
    'passwordDigest': passwordDigest,
  };

  factory LocalAccount.fromJson(Map<String, Object?> json) {
    final userJson = Map<String, Object?>.from(json['user']! as Map);
    return LocalAccount(
      user: AppUser(
        id: userJson['id']! as String,
        name: userJson['name']! as String,
        email: userJson['email']! as String,
        createdAt: DateTime.parse(userJson['createdAt']! as String),
      ),
      passwordDigest: json['passwordDigest']! as String,
    );
  }
}

abstract interface class AuthStore {
  Future<LocalAccount?> findAccount(String email);
  Future<void> saveAccount(LocalAccount account);
  Future<AppUser?> readSession();
  Future<void> saveSession(AppUser? user);
}

class MemoryAuthStore implements AuthStore {
  final Map<String, LocalAccount> _accounts = {};
  AppUser? _session;
  @override
  Future<LocalAccount?> findAccount(String email) async => _accounts[email];
  @override
  Future<void> saveAccount(LocalAccount account) async =>
      _accounts[account.user.email] = account;
  @override
  Future<AppUser?> readSession() async => _session;
  @override
  Future<void> saveSession(AppUser? user) async => _session = user;
}

/// Device-persistent storage for mock accounts and the active session.
///
/// Passwords are never stored verbatim. This remains an educational/offline
/// implementation; production authentication should be delegated to a secure
/// identity service.
class PreferencesAuthStore implements AuthStore {
  PreferencesAuthStore({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _accountsKey = 'qanat.auth.accounts.v1';
  static const _sessionEmailKey = 'qanat.auth.session_email.v1';

  final Future<SharedPreferences> _preferences;

  @override
  Future<LocalAccount?> findAccount(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final accounts = await _readAccounts();
    return accounts[normalizedEmail];
  }

  @override
  Future<void> saveAccount(LocalAccount account) async {
    final accounts = await _readAccounts();
    accounts[account.user.email.trim().toLowerCase()] = account;
    final encoded = accounts.values
        .map((value) => jsonEncode(value.toJson()))
        .toList(growable: false);
    final preferences = await _preferences;
    await preferences.setStringList(_accountsKey, encoded);
  }

  @override
  Future<AppUser?> readSession() async {
    final preferences = await _preferences;
    final email = preferences.getString(_sessionEmailKey);
    if (email == null) return null;
    final account = await findAccount(email);
    if (account == null) {
      await preferences.remove(_sessionEmailKey);
    }
    return account?.user;
  }

  @override
  Future<void> saveSession(AppUser? user) async {
    final preferences = await _preferences;
    if (user == null) {
      await preferences.remove(_sessionEmailKey);
      return;
    }
    await preferences.setString(
      _sessionEmailKey,
      user.email.trim().toLowerCase(),
    );
  }

  Future<Map<String, LocalAccount>> _readAccounts() async {
    final preferences = await _preferences;
    final encoded = preferences.getStringList(_accountsKey) ?? const [];
    final accounts = <String, LocalAccount>{};
    for (final value in encoded) {
      try {
        final json = Map<String, Object?>.from(jsonDecode(value) as Map);
        final account = LocalAccount.fromJson(json);
        accounts[account.user.email.trim().toLowerCase()] = account;
      } on FormatException {
        // Ignore a damaged entry without preventing other accounts from loading.
      } on TypeError {
        // Ignore data written using an incompatible schema.
      }
    }
    return accounts;
  }
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);
  final AuthStore _store;
  @override
  Future<AppUser?> restoreSession() => _store.readSession();
  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (await _store.findAccount(normalizedEmail) != null) {
      throw const EmailAlreadyUsedException();
    }
    final now = DateTime.now();
    final user = AppUser(
      id: 'user_${now.microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      createdAt: now,
    );
    await _store.saveAccount(
      LocalAccount(user: user, passwordDigest: _digest(password)),
    );
    await _store.saveSession(user);
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final account = await _store.findAccount(email.trim().toLowerCase());
    if (account == null || account.passwordDigest != _digest(password)) {
      throw const InvalidCredentialsException();
    }
    await _store.saveSession(account.user);
    return account.user;
  }

  @override
  Future<void> signOut() => _store.saveSession(null);

  static String _digest(String value) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }
}
