import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/bookings/domain/booking_models.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketScreen extends ConsumerWidget {
  const TicketScreen({required this.booking, super.key});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    if (user?.id != booking.userId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Электрондық билет')),
        body: Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.explore),
            child: const Text('Билетті көру үшін аккаунтқа кіріңіз'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Электрондық билет')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.trips),
            child: const Text('Сапарларым'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.section,
        ),
        children: [
          Text(
            'Сапарыңыз дайын',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Бронь сақталды. Бұл оқу жобасындағы сынақ билеті.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.hero,
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  color: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QANAT  ·  MOCK TICKET',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.onPrimaryMuted),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _Airport(
                              code: booking.originCode,
                              city: booking.originCity,
                            ),
                          ),
                          const Icon(
                            Icons.flight_rounded,
                            color: AppColors.accent,
                          ),
                          Expanded(
                            child: _Airport(
                              code: booking.destinationCode,
                              city: booking.destinationCity,
                              end: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '${_date(booking.departureAt)}  ·  ${_time(booking.departureAt)}–${_time(booking.arrivalAt)}',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppColors.onPrimary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _TicketRow('Жолаушы', booking.passengerName),
                      _TicketRow(
                        'Рейс',
                        '${booking.airlineName} · ${booking.flightNumber}',
                      ),
                      _TicketRow('Орын', booking.seatCode),
                      _TicketRow('Тариф', booking.fareName),
                      _TicketRow(
                        'Багаж',
                        booking.baggageKg > 0
                            ? '${booking.baggageKg} кг'
                            : 'Қол жүгі',
                      ),
                      _TicketRow('Барлығы', '${booking.totalKzt} ₸'),
                      const Divider(height: AppSpacing.xl),
                      QrImageView(
                        data: booking.id,
                        version: QrVersions.auto,
                        size: 148,
                        backgroundColor: AppColors.surface,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        booking.id,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'QR коды тек бронь нөмірін қамтиды. Әуежайда жарамды билет емес.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Airport extends StatelessWidget {
  const _Airport({required this.code, required this.city, this.end = false});
  final String code;
  final String city;
  final bool end;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(
        code,
        style: Theme.of(context).textTheme.displaySmall
            ?.copyWith(color: AppColors.onPrimary),
      ),
      Text(
        city,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.onPrimaryMuted),
      ),
    ],
  );
}

class _TicketRow extends StatelessWidget {
  const _TicketRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
