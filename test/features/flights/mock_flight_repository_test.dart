import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/flights/data/mock_flight_repository.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';

void main() {
  late MockFlightRepository repository;
  late FlightSearchCriteria criteria;
  setUp(() {
    repository = MockFlightRepository(simulatedDelay: Duration.zero);
    criteria = FlightSearchCriteria(
      origin: MockFlightRepository.astana,
      destination: MockFlightRepository.almaty,
      departureDate: DateTime(2026, 10, 12),
    );
  });
  test('returns realistic route offers sorted by price', () async {
    final results = await repository.searchFlights(
      criteria,
      sort: FlightSort.cheapest,
    );
    expect(results, hasLength(4));
    expect(results.first.priceKzt, 28500);
    expect(results.every((e) => e.flight.origin.code == 'NQZ'), isTrue);
  });
  test('applies direct and checked baggage filters', () async {
    final results = await repository.searchFlights(
      criteria,
      filters: FlightFilters(directOnly: true, checkedBaggageOnly: true),
    );
    expect(results, isNotEmpty);
    expect(
      results.every((e) => e.flight.isDirect && e.hasCheckedBaggage),
      isTrue,
    );
  });
  test('retrieves offer from latest result set', () async {
    final results = await repository.searchFlights(criteria);
    final found = await repository.getOfferById(results.first.id);
    expect(found?.id, results.first.id);
  });
}
