import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/bookings/domain/booking_models.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({required this.offer, super.key});
  final FlightOffer offer;

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  static const _occupied = {
    '1A',
    '1F',
    '2C',
    '3B',
    '4D',
    '5A',
    '5E',
    '6C',
    '7F',
  };
  Seat? _selected;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Орын таңдау')),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.page),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: FilledButton(
          onPressed: _selected == null
              ? null
              : () => context.push(
                  AppRoutes.passengerDetails,
                  extra: BookingDraft(offer: widget.offer, seat: _selected!),
                ),
          child: Text(
            _selected == null
                ? 'Орын таңдаңыз'
                : '${_selected!.code} · Жалғастыру',
          ),
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
          'Ұшу жайлырақ болсын',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${widget.offer.flight.origin.code} → ${widget.offer.flight.destination.code} · ${widget.offer.flight.flightNumber}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: const [
            _Legend(color: AppColors.primarySoft, label: 'Бос'),
            _Legend(color: AppColors.primary, label: 'Таңдалған'),
            _Legend(color: AppColors.border, label: 'Бос емес'),
            _Legend(color: AppColors.accent, label: 'Кең орын +9 000 ₸'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.hero,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.flight_rounded,
                color: AppColors.primary,
                size: 34,
              ),
              const SizedBox(height: AppSpacing.xl),
              for (var row = 1; row <= 8; row++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$row',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    for (final letter in ['A', 'B', 'C'])
                      _seatButton(row, letter),
                    const SizedBox(width: AppSpacing.md),
                    for (final letter in ['D', 'E', 'F'])
                      _seatButton(row, letter),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        if (_selected case final seat?) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadii.medium,
            ),
            child: Text(
              seat.kind == SeatKind.premium
                  ? '${seat.code} · Кең орын · +9 000 ₸'
                  : '${seat.code} · Стандарт орын · Қосымша төлем жоқ',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _seatButton(int row, String letter) {
    final code = '$row$letter';
    final occupied = _occupied.contains(code);
    final selected = _selected?.code == code;
    final premium = row <= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 32,
        height: 40,
        child: Material(
          color: occupied
              ? AppColors.border
              : selected
              ? AppColors.primary
              : premium
              ? AppColors.accent
              : AppColors.primarySoft,
          borderRadius: AppRadii.medium,
          child: InkWell(
            key: ValueKey('seat-$code'),
            onTap: occupied
                ? null
                : () => setState(() {
                    _selected = Seat(
                      code: code,
                      kind: premium ? SeatKind.premium : SeatKind.standard,
                    );
                  }),
            borderRadius: AppRadii.medium,
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: color, borderRadius: AppRadii.medium),
      ),
      const SizedBox(width: AppSpacing.xxs),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}
