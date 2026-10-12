import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanat/core/config/app_environment.dart';
import 'package:qanat/core/network/api_client_provider.dart';

import '../data/api_flight_repository.dart';
import '../data/mock_flight_repository.dart';
import '../domain/flight_models.dart';
import '../domain/flight_offer_ranker.dart';
import '../domain/flight_repository.dart';

final flightRepositoryProvider = Provider<FlightRepository>(
  (ref) => AppEnvironment.isConfigured
      ? ApiFlightRepository(ref.watch(apiClientProvider))
      : MockFlightRepository(),
);

final airportsProvider = FutureProvider<List<Airport>>(
  (ref) => ref.watch(flightRepositoryProvider).getAirports(),
);

final flightSearchQueryProvider =
    NotifierProvider<FlightSearchQueryController, FlightSearchQuery>(
      FlightSearchQueryController.new,
    );

final flightFiltersProvider =
    NotifierProvider<FlightFiltersController, FlightFilters>(
      FlightFiltersController.new,
    );

final flightSortProvider = NotifierProvider<FlightSortController, FlightSort>(
  FlightSortController.new,
);

final flightSearchControllerProvider =
    AsyncNotifierProvider<FlightSearchController, FlightSearchResult>(
      FlightSearchController.new,
    );

enum FlightSearchValidationIssue {
  missingOrigin,
  missingDestination,
  sameAirport,
  missingDepartureDate,
  returnBeforeDeparture,
}

class FlightSearchValidationException implements Exception {
  const FlightSearchValidationException(this.issue);
  final FlightSearchValidationIssue issue;

  String get message => switch (issue) {
    FlightSearchValidationIssue.missingOrigin => 'Ұшу қаласын таңдаңыз.',
    FlightSearchValidationIssue.missingDestination =>
      'Баратын қаланы таңдаңыз.',
    FlightSearchValidationIssue.sameAirport =>
      'Ұшу және бару қалалары әртүрлі болуы керек.',
    FlightSearchValidationIssue.missingDepartureDate => 'Ұшу күнін таңдаңыз.',
    FlightSearchValidationIssue.returnBeforeDeparture =>
      'Қайту күні ұшу күнінен ерте болмауы керек.',
  };

  @override
  String toString() => message;
}

class FlightSearchQuery {
  const FlightSearchQuery({
    this.origin,
    this.destination,
    this.departureDate,
    this.returnDate,
    this.passengers = const PassengerCounts(),
    this.cabinClass = CabinClass.economy,
  });

  final Airport? origin;
  final Airport? destination;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final PassengerCounts passengers;
  final CabinClass cabinClass;

  bool get isRoundTrip => returnDate != null;

  FlightSearchQuery copyWith({
    Airport? origin,
    Airport? destination,
    DateTime? departureDate,
    DateTime? returnDate,
    bool clearReturnDate = false,
    PassengerCounts? passengers,
    CabinClass? cabinClass,
  }) => FlightSearchQuery(
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    departureDate: departureDate ?? this.departureDate,
    returnDate: clearReturnDate ? null : returnDate ?? this.returnDate,
    passengers: passengers ?? this.passengers,
    cabinClass: cabinClass ?? this.cabinClass,
  );

  FlightSearchCriteria toCriteria() {
    final selectedOrigin = origin;
    if (selectedOrigin == null) {
      throw const FlightSearchValidationException(
        FlightSearchValidationIssue.missingOrigin,
      );
    }
    final selectedDestination = destination;
    if (selectedDestination == null) {
      throw const FlightSearchValidationException(
        FlightSearchValidationIssue.missingDestination,
      );
    }
    if (selectedOrigin == selectedDestination) {
      throw const FlightSearchValidationException(
        FlightSearchValidationIssue.sameAirport,
      );
    }
    final selectedDepartureDate = departureDate;
    if (selectedDepartureDate == null) {
      throw const FlightSearchValidationException(
        FlightSearchValidationIssue.missingDepartureDate,
      );
    }
    if (returnDate != null && returnDate!.isBefore(selectedDepartureDate)) {
      throw const FlightSearchValidationException(
        FlightSearchValidationIssue.returnBeforeDeparture,
      );
    }
    return FlightSearchCriteria(
      origin: selectedOrigin,
      destination: selectedDestination,
      departureDate: selectedDepartureDate,
      returnDate: returnDate,
      passengers: passengers,
      cabinClass: cabinClass,
    );
  }
}

class FlightSearchQueryController extends Notifier<FlightSearchQuery> {
  @override
  FlightSearchQuery build() => const FlightSearchQuery();

  void setOrigin(Airport airport) => state = state.copyWith(origin: airport);
  void setDestination(Airport airport) =>
      state = state.copyWith(destination: airport);

  void swapAirports() {
    state = FlightSearchQuery(
      origin: state.destination,
      destination: state.origin,
      departureDate: state.departureDate,
      returnDate: state.returnDate,
      passengers: state.passengers,
      cabinClass: state.cabinClass,
    );
  }

  void setDates(DateTime departureDate, {DateTime? returnDate}) {
    state = state.copyWith(
      departureDate: _dateOnly(departureDate),
      returnDate: returnDate == null ? null : _dateOnly(returnDate),
      clearReturnDate: returnDate == null,
    );
  }

  void setPassengers(PassengerCounts passengers) =>
      state = state.copyWith(passengers: passengers);
  void setCabinClass(CabinClass cabinClass) =>
      state = state.copyWith(cabinClass: cabinClass);
  void reset() => state = const FlightSearchQuery();

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class FlightFiltersController extends Notifier<FlightFilters> {
  @override
  FlightFilters build() => FlightFilters();
  void replace(FlightFilters filters) => state = filters;
  void reset() => state = FlightFilters();
}

class FlightSortController extends Notifier<FlightSort> {
  @override
  FlightSort build() => FlightSort.recommended;
  void setSort(FlightSort sort) => state = sort;
  void reset() => state = FlightSort.recommended;
}

class FlightSearchResult {
  FlightSearchResult({
    required this.criteria,
    required List<FlightOffer> offers,
    required this.cheapest,
    required this.fastest,
    required this.best,
  }) : offers = List.unmodifiable(offers);

  FlightSearchResult.initial()
    : criteria = null,
      offers = const [],
      cheapest = null,
      fastest = null,
      best = null;

  factory FlightSearchResult.fromOffers(
    FlightSearchCriteria criteria,
    List<FlightOffer> offers,
    FlightOfferRanker ranker,
  ) => FlightSearchResult(
    criteria: criteria,
    offers: offers,
    cheapest: ranker.cheapest(offers),
    fastest: ranker.fastest(offers),
    best: ranker.best(offers),
  );

  final FlightSearchCriteria? criteria;
  final List<FlightOffer> offers;
  final FlightOffer? cheapest;
  final FlightOffer? fastest;
  final FlightOffer? best;
  bool get hasSearched => criteria != null;
  bool get isEmpty => hasSearched && offers.isEmpty;
}

class FlightSearchController extends AsyncNotifier<FlightSearchResult> {
  final FlightOfferRanker _ranker = const FlightOfferRanker();
  FlightSearchCriteria? _lastCriteria;
  int _requestId = 0;

  FlightRepository get _repository => ref.read(flightRepositoryProvider);

  @override
  FlightSearchResult build() => FlightSearchResult.initial();

  Future<void> searchFromQuery() =>
      search(ref.read(flightSearchQueryProvider).toCriteria());

  Future<void> search(FlightSearchCriteria criteria) async {
    _lastCriteria = criteria;
    final requestId = ++_requestId;
    state = const AsyncLoading();
    try {
      final offers = await _repository.searchFlights(
        criteria,
        filters: ref.read(flightFiltersProvider),
        sort: ref.read(flightSortProvider),
      );
      if (requestId != _requestId) return;
      state = AsyncData(
        FlightSearchResult.fromOffers(criteria, offers, _ranker),
      );
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> updateFilters(FlightFilters filters) {
    ref.read(flightFiltersProvider.notifier).replace(filters);
    return refresh();
  }

  Future<void> updateSort(FlightSort sort) {
    ref.read(flightSortProvider.notifier).setSort(sort);
    return refresh();
  }

  Future<void> refresh() async {
    final criteria = _lastCriteria;
    if (criteria != null) await search(criteria);
  }

  void clear() {
    _requestId++;
    _lastCriteria = null;
    state = AsyncData(FlightSearchResult.initial());
  }
}
