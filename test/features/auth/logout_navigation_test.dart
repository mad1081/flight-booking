import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/features/auth/data/repositories/local_auth_repository.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qanat/features/auth/presentation/screens/login_screen.dart';
import 'package:qanat/features/auth/presentation/screens/profile_screen.dart';

void main() {
  testWidgets('explicit sign out clears the session and opens login', (
    tester,
  ) async {
    final repository = LocalAuthRepository(MemoryAuthStore());
    await repository.register(
      name: 'Test User',
      email: 'test@example.com',
      password: 'Password123',
    );
    final router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const Scaffold(body: ProfileScreen()),
        ),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Аккаунттан шығу'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await repository.restoreSession(), isNull);
    expect(tester.takeException(), isNull);
  });
}
