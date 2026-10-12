import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';

class FlightDetailsScreen extends ConsumerStatefulWidget {
  const FlightDetailsScreen({required this.offer, super.key});
  final FlightOffer offer;

  @override
  ConsumerState<FlightDetailsScreen> createState() =>
      _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends ConsumerState<FlightDetailsScreen> {
  bool _trackingPrice = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final flight = offer.flight;
    return Scaffold(
      appBar: AppBar(title: const Text('Рейс туралы')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Барлығы',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _price(offer.priceKzt),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 190,
                child: FilledButton(
                  onPressed: _continueBooking,
                  child: const Text('Жалғастыру'),
                ),
              ),
            ],
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadii.hero,
              boxShadow: AppShadows.onDark,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _HeroAirport(airport: flight.origin)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Icon(
                        Icons.flight_takeoff_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    Expanded(
                      child: _HeroAirport(
                        airport: flight.destination,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    _HeroMeta(label: 'Ұшу', value: _time(flight.departureAt)),
                    _HeroMeta(
                      label: 'Ұзақтығы',
                      value: _duration(flight.duration),
                    ),
                    _HeroMeta(
                      label: 'Келу',
                      value: _time(flight.arrivalAt),
                      alignEnd: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Рейс',
            children: [
              _InfoRow(
                icon: Icons.airlines_rounded,
                label: 'Авиакомпания',
                value: flight.airline.name,
              ),
              _InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Рейс нөмірі',
                value: flight.flightNumber,
              ),
              _InfoRow(
                icon: Icons.route_rounded,
                label: 'Бағыт',
                value: flight.isDirect
                    ? 'Тікелей рейс'
                    : '${flight.stops} ауысу',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Тариф және багаж',
            children: [
              _InfoRow(
                icon: Icons.sell_outlined,
                label: 'Тариф',
                value: offer.fareName,
              ),
              _InfoRow(
                icon: Icons.work_outline_rounded,
                label: 'Қол жүгі',
                value: '${offer.cabinBaggageKg} кг',
              ),
              _InfoRow(
                icon: Icons.luggage_outlined,
                label: 'Тіркелетін багаж',
                value: offer.hasCheckedBaggage
                    ? '${offer.checkedBaggageKg} кг'
                    : 'Қосылмаған',
              ),
              _InfoRow(
                icon: Icons.replay_rounded,
                label: 'Қайтару',
                value: offer.isRefundable ? 'Рұқсат етіледі' : 'Қайтарылмайды',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Баға динамикасы',
            trailing: _AssessmentBadge(assessment: offer.priceAssessment),
            children: [
              SizedBox(
                height: 94,
                width: double.infinity,
                child: CustomPaint(
                  painter: _PriceChartPainter(offer.priceHistory),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Бағаны бақылау'),
                  subtitle: const Text('Баға өзгергенде хабарлау'),
                  value: _trackingPrice,
                  onChanged: (value) {
                    setState(() => _trackingPrice = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Бағаны бақылау қосылды'
                              : 'Бағаны бақылау өшірілді',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _continueBooking() {
    final user = ref.read(authControllerProvider).asData?.value;
    if (user == null) {
      context.push(AppRoutes.login, extra: widget.offer);
      return;
    }
    context.push(AppRoutes.seatSelection, extra: widget.offer);
  }
}

class _HeroAirport extends StatelessWidget {
  const _HeroAirport({required this.airport, this.alignEnd = false});
  final Airport airport;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        airport.code,
        style: Theme.of(context).textTheme.displaySmall
            ?.copyWith(color: AppColors.onPrimary),
      ),
      Text(
        airport.city,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.onPrimaryMuted),
      ),
    ],
  );
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });
  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppColors.onPrimaryMuted),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.onPrimary),
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
      boxShadow: AppShadows.card,
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}

class _AssessmentBadge extends StatelessWidget {
  const _AssessmentBadge({required this.assessment});
  final PriceAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final label = switch (assessment) {
      PriceAssessment.good => 'Жақсы баға',
      PriceAssessment.average => 'Орташа баға',
      PriceAssessment.high => 'Баға жоғары',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.medium,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  const _PriceChartPainter(this.points);
  final List<PriceHistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final prices = points.map((point) => point.priceKzt).toList();
    final minimum = prices.reduce(math.min);
    final maximum = prices.reduce(math.max);
    final range = math.max(1, maximum - minimum);
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final x = size.width * index / (points.length - 1);
      final normalized = (points[index].priceKzt - minimum) / range;
      final y = size.height - 12 - normalized * (size.height - 24);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_PriceChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _duration(Duration value) =>
    '${value.inHours} сағ ${value.inMinutes.remainder(60)} мин';
String _price(int value) {
  final valueString = value.toString();
  final result = StringBuffer();
  for (var i = 0; i < valueString.length; i++) {
    if (i > 0 && (valueString.length - i) % 3 == 0) result.write(' ');
    result.write(valueString[i]);
  }
  return '$result ₸';
}
