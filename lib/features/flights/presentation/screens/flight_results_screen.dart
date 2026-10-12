import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';
import 'package:qanat/features/flights/application/flight_search_controller.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';

class FlightResultsScreen extends ConsumerWidget {
  const FlightResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(flightSearchControllerProvider);
    final criteria = search.asData?.value.criteria;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              criteria == null
                  ? 'Рейстер'
                  : '${criteria.origin.code}  →  ${criteria.destination.code}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (criteria != null)
              Text(
                _date(criteria.departureDate),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Сүзгілер',
            onPressed: () => _showFilters(context, ref),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: search.when(
        loading: () => const _LoadingResults(),
        error: (_, _) => _StatusMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Нәтижелерді жүктей алмадық',
          message: 'Байланысты тексеріп, қайта көріңіз.',
          action: FilledButton(
            onPressed: () =>
                ref.read(flightSearchControllerProvider.notifier).refresh(),
            child: const Text('Қайта көру'),
          ),
        ),
        data: (result) {
          if (!result.hasSearched) {
            return _StatusMessage(
              icon: Icons.travel_explore_rounded,
              title: 'Іздеу параметрлері жоқ',
              message: 'Бағыт пен күнді қайта таңдаңыз.',
              action: FilledButton(
                onPressed: () => context.go(AppRoutes.explore),
                child: const Text('Іздеуге оралу'),
              ),
            );
          }
          if (result.isEmpty) {
            return const _StatusMessage(
              icon: Icons.search_off_rounded,
              title: 'Рейстер табылмады',
              message: 'Күнді немесе сүзгілерді өзгертіп көріңіз.',
            );
          }
          final currentCriteria = result.criteria!;
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(flightSearchControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.section,
              ),
              children: [
                _Summary(criteria: currentCriteria),
                const SizedBox(height: AppSpacing.lg),
                _SortBar(
                  selected: ref.watch(flightSortProvider),
                  onSelected: (sort) => ref
                      .read(flightSearchControllerProvider.notifier)
                      .updateSort(sort),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '${result.offers.length} нұсқа табылды',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final offer in result.offers) ...[
                  _FlightCard(
                    offer: offer,
                    badge: offer.id == result.best?.id
                        ? 'Үздік нұсқа'
                        : offer.id == result.cheapest?.id
                        ? 'Ең арзан'
                        : offer.id == result.fastest?.id
                        ? 'Ең жылдам'
                        : null,
                    onTap: () =>
                        context.push(AppRoutes.flightDetails, extra: offer),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFilters(BuildContext context, WidgetRef ref) async {
    final current = ref.read(flightFiltersProvider);
    var directOnly = current.directOnly;
    var baggageOnly = current.checkedBaggageOnly;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.page,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сүзгілер',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Сапарыңызға маңызды шарттарды таңдаңыз.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Тек тікелей рейстер'),
                  subtitle: const Text('Ауысып отырусыз'),
                  value: directOnly,
                  onChanged: (value) => setSheetState(() => directOnly = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Тіркелетін багаж'),
                  subtitle: const Text('Бағасына багаж кіретін рейстер'),
                  value: baggageOnly,
                  onChanged: (value) =>
                      setSheetState(() => baggageOnly = value),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref
                        .read(flightSearchControllerProvider.notifier)
                        .updateFilters(
                          FlightFilters(
                            directOnly: directOnly,
                            checkedBaggageOnly: baggageOnly,
                          ),
                        );
                  },
                  child: const Text('Нәтижелерді көрсету'),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref
                          .read(flightSearchControllerProvider.notifier)
                          .updateFilters(FlightFilters());
                    },
                    child: const Text('Сүзгілерді тазарту'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.criteria});
  final FlightSearchCriteria criteria;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: AppRadii.card,
      boxShadow: AppShadows.onDark,
    ),
    child: Row(
      children: [
        const Icon(Icons.flight_takeoff_rounded, color: AppColors.onPrimary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '${criteria.origin.city} → ${criteria.destination.city}',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppColors.onPrimary),
          ),
        ),
        Text(
          '${criteria.passengers.total} жолаушы',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppColors.onPrimaryMuted),
        ),
      ],
    ),
  );
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.selected, required this.onSelected});
  final FlightSort selected;
  final ValueChanged<FlightSort> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final sort in FlightSort.values) ...[
          ChoiceChip(
            label: Text(_sortLabel(sort)),
            selected: selected == sort,
            onSelected: (_) => onSelected(sort),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ],
    ),
  );
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({required this.offer, required this.onTap, this.badge});
  final FlightOffer offer;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final flight = offer.flight;
    final airlineColor = Color(flight.airline.brandColor);
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: AppRadii.card,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: airlineColor.withValues(alpha: .1),
                    child: Text(
                      flight.airline.code,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: airlineColor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.airline.name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          flight.flightNumber,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadii.medium,
                      ),
                      child: Text(
                        badge!,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _TimePoint(
                    time: _time(flight.departureAt),
                    code: flight.origin.code,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _duration(flight.duration),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Divider(),
                        ),
                        Text(
                          flight.isDirect ? 'Тікелей' : '${flight.stops} ауысу',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _TimePoint(
                    time: _time(flight.arrivalAt),
                    code: flight.destination.code,
                    alignEnd: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.luggage_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      offer.hasCheckedBaggage
                          ? '${offer.checkedBaggageKg} кг багаж'
                          : '${offer.cabinBaggageKg} кг қол жүгі',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _price(offer.priceKzt),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePoint extends StatelessWidget {
  const _TimePoint({
    required this.time,
    required this.code,
    this.alignEnd = false,
  });
  final String time;
  final String code;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    child: Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(time, style: Theme.of(context).textTheme.titleLarge),
        Text(code, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _LoadingResults extends StatelessWidget {
  const _LoadingResults();
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(AppSpacing.page),
    itemCount: 4,
    itemBuilder: (_, index) => Container(
      height: index == 0 ? 72 : 230,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
      ),
    ),
  );
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(width: 220, child: action),
          ],
        ],
      ),
    ),
  );
}

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _duration(Duration value) =>
    '${value.inHours} сағ ${value.inMinutes.remainder(60)} мин';
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
String _price(int value) {
  final valueString = value.toString();
  final result = StringBuffer();
  for (var i = 0; i < valueString.length; i++) {
    if (i > 0 && (valueString.length - i) % 3 == 0) result.write(' ');
    result.write(valueString[i]);
  }
  return '$result ₸';
}

String _sortLabel(FlightSort sort) => switch (sort) {
  FlightSort.recommended => 'Ұсынылған',
  FlightSort.cheapest => 'Ең арзан',
  FlightSort.fastest => 'Ең жылдам',
  FlightSort.departureTime => 'Ұшу уақыты',
};
