import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/flights/application/flight_search_controller.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _defaultsScheduled = false;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(flightSearchQueryProvider);
    final airports = ref.watch(airportsProvider);
    _scheduleDefaults(airports, query);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.section,
        ),
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flight_rounded,
                  color: AppColors.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Qanat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Хабарламалар',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Жаңа хабарламалар жоқ.')),
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Қайда ұшамыз?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Тиімді рейстерді іздеп, бір жерден салыстырыңыз.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.hero,
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Бір бағыт')),
                    ButtonSegment(value: true, label: Text('Барып-қайту')),
                  ],
                  selected: {query.isRoundTrip},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    final roundTrip = selection.first;
                    final departure =
                        query.departureDate ??
                        DateTime.now().add(const Duration(days: 1));
                    ref
                        .read(flightSearchQueryProvider.notifier)
                        .setDates(
                          departure,
                          returnDate: roundTrip
                              ? departure.add(const Duration(days: 7))
                              : null,
                        );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Column(
                      children: [
                        _SearchField(
                          icon: Icons.flight_takeoff_rounded,
                          label: 'Қайдан',
                          value: _airportLabel(query.origin),
                          onTap: airports.asData == null
                              ? null
                              : () => _pickAirport(
                                  airports.asData!.value,
                                  origin: true,
                                ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SearchField(
                          icon: Icons.flight_land_rounded,
                          label: 'Қайда',
                          value: _airportLabel(query.destination),
                          onTap: airports.asData == null
                              ? null
                              : () => _pickAirport(
                                  airports.asData!.value,
                                  origin: false,
                                ),
                        ),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Бағыттарды ауыстыру',
                          onPressed:
                              query.origin == null || query.destination == null
                              ? null
                              : () => ref
                                    .read(flightSearchQueryProvider.notifier)
                                    .swapAirports(),
                          icon: const Icon(
                            Icons.swap_vert_rounded,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _SearchField(
                        compact: true,
                        icon: Icons.calendar_today_outlined,
                        label: 'Ұшу күні',
                        value: query.departureDate == null
                            ? 'Күнді таңдаңыз'
                            : _date(query.departureDate!),
                        onTap: () => _pickDate(query),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: query.isRoundTrip
                          ? _SearchField(
                              compact: true,
                              icon: Icons.event_repeat_rounded,
                              label: 'Қайту күні',
                              value: _date(query.returnDate!),
                              onTap: () => _pickReturnDate(query),
                            )
                          : _SearchField(
                              compact: true,
                              icon: Icons.person_outline_rounded,
                              label: 'Жолаушылар',
                              value: '${query.passengers.total} жолаушы',
                              onTap: () => _pickPassengers(query.passengers),
                            ),
                    ),
                  ],
                ),
                if (query.isRoundTrip) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _SearchField(
                    icon: Icons.person_outline_rounded,
                    label: 'Жолаушылар',
                    value: '${query.passengers.total} жолаушы',
                    onTap: () => _pickPassengers(query.passengers),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: airports.isLoading ? null : _search,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Рейстерді табу'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Танымал бағыттар',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 136,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _DestinationCard(
                  code: 'ALA',
                  city: 'Алматы',
                  subtitle: 'Таулар мен қала',
                  icon: Icons.landscape_rounded,
                ),
                SizedBox(width: AppSpacing.sm),
                _DestinationCard(
                  code: 'SCO',
                  city: 'Ақтау',
                  subtitle: 'Каспий жағалауы',
                  icon: Icons.water_rounded,
                ),
                SizedBox(width: AppSpacing.sm),
                _DestinationCard(
                  code: 'CIT',
                  city: 'Шымкент',
                  subtitle: 'Күн шуақты оңтүстік',
                  icon: Icons.wb_sunny_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleDefaults(
    AsyncValue<List<Airport>> airports,
    FlightSearchQuery query,
  ) {
    if (_defaultsScheduled || query.origin != null || airports.asData == null) {
      return;
    }
    _defaultsScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final values = airports.requireValue;
      if (values.length < 2) return;
      ref.read(flightSearchQueryProvider.notifier)
        ..setOrigin(values[0])
        ..setDestination(values[1])
        ..setDates(DateTime.now().add(const Duration(days: 1)));
    });
  }

  Future<void> _pickAirport(
    List<Airport> airports, {
    required bool origin,
  }) async {
    final selected = await showModalBottomSheet<Airport>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Text(
                  origin ? 'Ұшу қаласы' : 'Баратын қала',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              for (final airport in airports)
                ListTile(
                  leading: CircleAvatar(child: Text(airport.code)),
                  title: Text(airport.city),
                  subtitle: Text(airport.name),
                  onTap: () => Navigator.pop(context, airport),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    final controller = ref.read(flightSearchQueryProvider.notifier);
    origin
        ? controller.setOrigin(selected)
        : controller.setDestination(selected);
  }

  Future<void> _pickDate(FlightSearchQuery query) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: query.departureDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected == null) return;
    ref
        .read(flightSearchQueryProvider.notifier)
        .setDates(
          selected,
          returnDate: query.isRoundTrip
              ? selected.add(const Duration(days: 7))
              : null,
        );
  }

  Future<void> _pickReturnDate(FlightSearchQuery query) async {
    final departure = query.departureDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: query.returnDate ?? departure.add(const Duration(days: 7)),
      firstDate: departure,
      lastDate: departure.add(const Duration(days: 365)),
    );
    if (selected != null) {
      ref
          .read(flightSearchQueryProvider.notifier)
          .setDates(departure, returnDate: selected);
    }
  }

  Future<void> _pickPassengers(PassengerCounts current) async {
    var adults = current.adults;
    var children = current.children;
    final selected = await showModalBottomSheet<PassengerCounts>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Жолаушылар',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PassengerCounter(
                  label: 'Ересектер',
                  subtitle: '12 жастан жоғары',
                  value: adults,
                  onMinus: adults > 1
                      ? () => setSheetState(() => adults--)
                      : null,
                  onPlus: adults + children < 9
                      ? () => setSheetState(() => adults++)
                      : null,
                ),
                _PassengerCounter(
                  label: 'Балалар',
                  subtitle: '2–11 жас',
                  value: children,
                  onMinus: children > 0
                      ? () => setSheetState(() => children--)
                      : null,
                  onPlus: adults + children < 9
                      ? () => setSheetState(() => children++)
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    PassengerCounts(adults: adults, children: children),
                  ),
                  child: const Text('Дайын'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) {
      ref.read(flightSearchQueryProvider.notifier).setPassengers(selected);
    }
  }

  Future<void> _search() async {
    try {
      await ref.read(flightSearchControllerProvider.notifier).searchFromQuery();
      if (mounted) context.push(AppRoutes.results);
    } on FlightSearchValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    borderRadius: AppRadii.medium,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadii.medium,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: compact ? AppSpacing.sm : AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 21),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PassengerCounter extends StatelessWidget {
  const _PassengerCounter({
    required this.label,
    required this.subtitle,
    required this.value,
    this.onMinus,
    this.onPlus,
  });
  final String label;
  final String subtitle;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(subtitle),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center)),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    ),
  );
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.code,
    required this.city,
    required this.subtitle,
    required this.icon,
  });
  final String code;
  final String city;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 186,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const Spacer(),
            Text(code, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const Spacer(),
        Text(city, style: Theme.of(context).textTheme.titleLarge),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

String _airportLabel(Airport? airport) =>
    airport == null ? 'Әуежайды таңдаңыз' : '${airport.city} · ${airport.code}';
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
