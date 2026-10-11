import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/flights/application/flight_search_controller.dart';
import 'package:qanat/features/flights/data/mock_flight_repository.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';
import 'package:qanat/features/flights/domain/flight_repository.dart';

void main() {
  test('query validates fields and keeps selections when swapping', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(flightSearchQueryProvider).toCriteria(),
      throwsA(isA<FlightSearchValidationException>()),
    );

    container.read(flightSearchQueryProvider.notifier)
      ..setOrigin(MockFlightRepository.astana)
      ..setDestination(MockFlightRepository.almaty)
      ..setDates(DateTime(2026, 10, 12))
      ..setPassengers(const PassengerCounts(adults: 2))
      ..swapAirports();

    final criteria = container.read(flightSearchQueryProvider).toCriteria();
    expect(criteria.origin.code, 'ALA');
    expect(criteria.destination.code, 'NQZ');
    expect(criteria.departureDate, DateTime(2026, 10, 12));
    expect(criteria.passengers.total, 2);
  });

  test('search exposes cheapest, fastest, and best offers', () async {
    final repository = _TestRepository([
      _offer('cheap', price: 28000, minutes: 260),
      _offer('balanced', price: 36000, minutes: 100, baggageKg: 23),
      _offer('fast', price: 50000, minutes: 80),
    ]);
    final container = ProviderContainer(
      overrides: [flightRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(flightSearchControllerProvider.future);

    await container
        .read(flightSearchControllerProvider.notifier)
        .search(
          FlightSearchCriteria(
            origin: MockFlightRepository.astana,
            destination: MockFlightRepository.almaty,
            departureDate: DateTime(2026, 10, 12),
          ),
        );

    final result = container.read(flightSearchControllerProvider).requireValue;
    expect(result.cheapest?.id, 'cheap');
    expect(result.fastest?.id, 'fast');
    expect(result.best?.id, 'balanced');
  });
}

FlightOffer _offer(
  String id, {
  required int price,
  required int minutes,
  int baggageKg = 0,
}) {
  final departure = DateTime(2026, 10, 12, 8);
  return FlightOffer(
    id: id,
    flight: Flight(
      id: 'flight-$id',
      airline: MockFlightRepository.airAstana,
      flightNumber: 'KC 622',
      origin: MockFlightRepository.astana,
      destination: MockFlightRepository.almaty,
      departureAt: departure,
      arrivalAt: departure.add(Duration(minutes: minutes)),
    ),
    priceKzt: price,
    fareName: 'Standard',
    cabinBaggageKg: 7,
    checkedBaggageKg: baggageKg,
    remainingSeats: 5,
    isRefundable: false,
    priceAssessment: PriceAssessment.average,
  );
}

class _TestRepository implements FlightRepository {
  const _TestRepository(this.offers);
  final List<FlightOffer> offers;

  @override
  Future<List<Airport>> getAirports() async => const [];

  @override
  Future<FlightOffer?> getOfferById(String offerId) async => null;

  @override
  Future<List<FlightOffer>> searchFlights(
    FlightSearchCriteria criteria, {
    FlightFilters? filters,
    FlightSort sort = FlightSort.recommended,
  }) async => offers;
}
