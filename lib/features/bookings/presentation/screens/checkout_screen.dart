import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/bookings/application/booking_controller.dart';
import 'package:qanat/features/bookings/domain/booking_models.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({required this.draft, super.key});
  final BookingDraft draft;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final offer = draft.offer;
    final flight = offer.flight;
    return Scaffold(
      appBar: AppBar(title: const Text('Броньды растау')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.page),
          color: AppColors.surface,
          child: FilledButton(
            onPressed: _submitting ? null : _confirm,
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Броньды растау'),
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
            'Сапарды тексеріңіз',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Төлем оқу мақсатында имитацияланады.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          _CheckoutCard(
            title: 'Рейс',
            children: [
              _Line(
                'Бағыт',
                '${flight.origin.code} → ${flight.destination.code}',
              ),
              _Line('Күні', _date(flight.departureAt)),
              _Line('Әуе компаниясы', flight.airline.name),
              _Line('Рейс нөмірі', flight.flightNumber),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _CheckoutCard(
            title: 'Жолаушы',
            children: [
              _Line('Аты-жөні', draft.passenger!.fullName),
              _Line('Орын', draft.seat.code),
              _Line('Тариф', offer.fareName),
              _Line(
                'Багаж',
                offer.hasCheckedBaggage
                    ? '${offer.checkedBaggageKg} кг'
                    : 'Қол жүгі',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _CheckoutCard(
            title: 'Баға',
            children: [
              _Line('Билет', _price(offer.priceKzt)),
              _Line(
                'Орын',
                draft.seat.surchargeKzt == 0
                    ? 'Тегін'
                    : _price(draft.seat.surchargeKzt),
              ),
              const Divider(),
              _Line('Барлығы', _price(draft.totalKzt), strong: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadii.card,
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Оқу жобасы: нақты карта деректері мен ақша алынбайды.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      final booking = await ref
          .read(bookingsProvider.notifier)
          .confirm(widget.draft);
      if (!mounted) return;
      context.go(AppRoutes.ticket, extra: booking);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Броньды сақтай алмадық. Қайта көріңіз.')),
      );
      setState(() => _submitting = false);
    }
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
      boxShadow: AppShadows.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: strong
              ? Theme.of(context).textTheme.titleLarge
              : Theme.of(context).textTheme.labelLarge,
        ),
      ],
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
String _price(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+$)'), (_) => ' ')} ₸';
