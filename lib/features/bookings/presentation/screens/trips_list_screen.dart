import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qanat/features/bookings/application/booking_controller.dart';
import 'package:qanat/features/bookings/domain/booking_models.dart';

class TripsListScreen extends ConsumerStatefulWidget {
  const TripsListScreen({super.key});

  @override
  ConsumerState<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends ConsumerState<TripsListScreen> {
  bool _upcoming = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final bookings = ref.watch(bookingsProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.section,
        ),
        children: [
          Text('Сапарлар', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user == null
                ? 'Брондауларыңызды көру үшін аккаунтқа кіріңіз.'
                : 'Барлық билеттеріңіз бір жерде.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (user == null)
            _EmptyTrips(
              icon: Icons.lock_outline_rounded,
              title: 'Аккаунт қажет',
              description:
                  'Сапарларыңызды көру үшін кіріңіз немесе тіркеліңіз.',
              action: 'Кіру немесе тіркелу',
              onPressed: () => context.push(AppRoutes.login),
            )
          else ...[
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Алдағы')),
                ButtonSegment(value: false, label: Text('Өткен')),
              ],
              selected: {_upcoming},
              onSelectionChanged: (selection) =>
                  setState(() => _upcoming = selection.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            bookings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _EmptyTrips(
                icon: Icons.error_outline_rounded,
                title: 'Сапарлар жүктелмеді',
                description: 'Қайта көруге болады.',
                action: 'Қайталау',
                onPressed: () => ref.invalidate(bookingsProvider),
              ),
              data: (all) {
                final visible =
                    all
                        .where((booking) => booking.isUpcoming == _upcoming)
                        .toList()
                      ..sort(
                        (a, b) => _upcoming
                            ? a.departureAt.compareTo(b.departureAt)
                            : b.departureAt.compareTo(a.departureAt),
                      );
                if (visible.isEmpty) {
                  return _EmptyTrips(
                    icon: Icons.luggage_rounded,
                    title: _upcoming ? 'Әзірге сапар жоқ' : 'Өткен сапар жоқ',
                    description: _upcoming
                        ? 'Өзіңізге ыңғайлы рейсті тауып, алғашқы сапарыңызды жоспарлаңыз.'
                        : 'Өткен сапарларыңыз осы жерде көрінеді.',
                    action: 'Рейс іздеу',
                    onPressed: () => context.go(AppRoutes.explore),
                  );
                }
                return Column(
                  children: [
                    for (final booking in visible) ...[
                      _TripCard(booking: booking),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: AppRadii.card,
    child: InkWell(
      onTap: () => context.push(AppRoutes.ticket, extra: booking),
      borderRadius: AppRadii.card,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${booking.originCode}  →  ${booking.destinationCode}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${booking.originCity} → ${booking.destinationCity}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _date(booking.departureAt),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  booking.flightNumber,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.event_seat_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Орын ${booking.seatCode}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                Text(
                  'Билет ашу',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.hero,
      boxShadow: AppShadows.card,
    ),
    child: Column(
      children: [
        Icon(icon, size: 56, color: AppColors.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
