import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/auth/domain/models/app_user.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return SafeArea(
      child: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(authControllerProvider),
            child: const Text('Профильді қайта жүктеу'),
          ),
        ),
        data: (user) => user == null
            ? const _GuestProfile()
            : _AuthenticatedProfile(user: user),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.page),
    children: [
      const SizedBox(height: AppSpacing.lg),
      Text('Профиль', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Брондаулар мен жеке деректерді бір жерде сақтаңыз.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.xl),
      Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadii.hero,
          boxShadow: AppShadows.onDark,
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.onPrimaryFaint,
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.onPrimary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Qanat аккаунты',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: AppColors.onPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Сапарларыңызды барлық құрылғыда қолжетімді етіңіз.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.onPrimaryMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
              ),
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Кіру немесе тіркелу'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _AuthenticatedProfile extends ConsumerWidget {
  const _AuthenticatedProfile({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(AppSpacing.page),
    children: [
      const SizedBox(height: AppSpacing.lg),
      Text('Профиль', style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: AppSpacing.xl),
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.hero,
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              child: Text(
                user.name.trim().isEmpty
                    ? '?'
                    : user.name.trim()[0].toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.verified_rounded, color: AppColors.success),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      OutlinedButton.icon(
        onPressed: () async {
          final router = GoRouter.of(context);
          final signedOut = await ref
              .read(authControllerProvider.notifier)
              .signOut();
          if (signedOut) router.go(AppRoutes.login);
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Аккаунттан шығу'),
      ),
    ],
  );
}
