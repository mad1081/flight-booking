import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';
import 'package:qanat/features/flights/domain/flight_offer_ranker.dart';

void main() {
  const ranker = FlightOfferRanker();
  test('identifies cheapest and fastest deterministically', () {
    final offers = [
      _offer('balanced', price: 40000, minutes: 100, baggage: 23),
      _offer('cheap', price: 28000, minutes: 300, stops: 1, baggage: 20),
      _offer('fast', price: 52000, minutes: 80, baggage: 0),
    ];
    expect(ranker.cheapest(offers)?.id, 'cheap');
    expect(ranker.fastest(offers)?.id, 'fast');
  });
  test('best score balances price, duration, stops and baggage', () {
    final offers = [
      _offer('balanced', price: 40000, minutes: 100, baggage: 23),
      _offer('cheap', price: 28000, minutes: 300, stops: 1, baggage: 20),
      _offer('fast', price: 52000, minutes: 80, baggage: 0),
    ];
    expect(ranker.best(offers)?.id, 'balanced');
    expect(ranker.rank(offers).first.bestScore, inInclusiveRange(0, 100));
  });
  test('empty collection has no winners', () {
    expect(ranker.cheapest(const []), isNull);
    expect(ranker.fastest(const []), isNull);
    expect(ranker.best(const []), isNull);
  });
}

FlightOffer _offer(
  String id, {
  required int price,
  required int minutes,
  required int baggage,
  int stops = 0,
}) {
  const origin = Airport(code: 'NQZ', name: 'Astana', city: 'Astana');
  const destination = Airport(code: 'ALA', name: 'Almaty', city: 'Almaty');
  const airline = Airline(
    code: 'KC',
    name: 'Air Astana',
    brandColor: 0xFF00529B,
  );
  final departure = DateTime(2026, 10, 12, 8);
  return FlightOffer(
    id: id,
    flight: Flight(
      id: 'flight-$id',
      airline: airline,
      flightNumber: 'KC 622',
      origin: origin,
      destination: destination,
      departureAt: departure,
      arrivalAt: departure.add(Duration(minutes: minutes)),
      stopAirportCodes: List.filled(stops, 'KZO'),
    ),
    priceKzt: price,
    fareName: 'Test',
    cabinBaggageKg: 7,
    checkedBaggageKg: baggage,
    remainingSeats: 5,
    isRefundable: false,
    priceAssessment: PriceAssessment.average,
  );
}
