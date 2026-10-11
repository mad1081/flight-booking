import '../domain/flight_models.dart';
import '../domain/flight_offer_ranker.dart';
import '../domain/flight_repository.dart';

class MockFlightRepository implements FlightRepository {
  MockFlightRepository({
    this.simulatedDelay = const Duration(milliseconds: 250),
  });
  final Duration simulatedDelay;
  final _ranker = const FlightOfferRanker();
  List<FlightOffer> _lastResults = const [];

  static const astana = Airport(
    code: 'NQZ',
    name: 'Nursultan Nazarbayev International Airport',
    city: 'Astana',
  );
  static const almaty = Airport(
    code: 'ALA',
    name: 'Almaty International Airport',
    city: 'Almaty',
  );
  static const shymkent = Airport(
    code: 'CIT',
    name: 'Shymkent International Airport',
    city: 'Shymkent',
  );
  static const aktau = Airport(
    code: 'SCO',
    name: 'Aktau International Airport',
    city: 'Aktau',
  );
  static const atyrau = Airport(
    code: 'GUW',
    name: 'Atyrau International Airport',
    city: 'Atyrau',
  );
  static const airAstana = Airline(
    code: 'KC',
    name: 'Air Astana',
    brandColor: 0xFF00529B,
  );
  static const flyArystan = Airline(
    code: 'FS',
    name: 'FlyArystan',
    brandColor: 0xFFE31937,
  );
  static const scat = Airline(
    code: 'DV',
    name: 'SCAT Airlines',
    brandColor: 0xFF005DAA,
  );

  @override
  Future<List<Airport>> getAirports() async {
    await Future<void>.delayed(simulatedDelay);
    return const [astana, almaty, shymkent, aktau, atyrau];
  }

  @override
  Future<List<FlightOffer>> searchFlights(
    FlightSearchCriteria criteria, {
    FlightFilters? filters,
    FlightSort sort = FlightSort.recommended,
  }) async {
    await Future<void>.delayed(simulatedDelay);
    var offers = _buildOffers(criteria)
        .where((offer) => _matches(offer, filters))
        .toList();
    switch (sort) {
      case FlightSort.recommended:
        offers = _ranker.rank(offers).map((e) => e.offer).toList();
      case FlightSort.cheapest:
        offers.sort((a, b) => a.priceKzt.compareTo(b.priceKzt));
      case FlightSort.fastest:
        offers.sort((a, b) => a.flight.duration.compareTo(b.flight.duration));
      case FlightSort.departureTime:
        offers.sort(
          (a, b) => a.flight.departureAt.compareTo(b.flight.departureAt),
        );
    }
    _lastResults = List.unmodifiable(offers);
    return _lastResults;
  }

  @override
  Future<FlightOffer?> getOfferById(String offerId) async {
    await Future<void>.delayed(simulatedDelay);
    for (final offer in _lastResults) {
      if (offer.id == offerId) return offer;
    }
    return null;
  }

  List<FlightOffer> _buildOffers(FlightSearchCriteria criteria) {
    final origin = criteria.origin;
    final destination = criteria.destination;
    final date = criteria.departureDate;
    final route = '${origin.code}-${destination.code}';
    if (route != 'NQZ-ALA' && route != 'ALA-NQZ') {
      return [
        _offer(
          id: '$route-kc',
          airline: airAstana,
          number: 'KC 951',
          origin: origin,
          destination: destination,
          date: date,
          hour: 9,
          minute: 20,
          durationMinutes: 125,
          price: 48900,
          checkedKg: 23,
          assessment: PriceAssessment.average,
        ),
        _offer(
          id: '$route-fs',
          airline: flyArystan,
          number: 'FS 7061',
          origin: origin,
          destination: destination,
          date: date,
          hour: 15,
          minute: 40,
          durationMinutes: 135,
          price: 36990,
          checkedKg: 0,
          assessment: PriceAssessment.good,
        ),
      ];
    }
    return [
      _offer(
        id: '$route-fs7152',
        airline: flyArystan,
        number: 'FS 7152',
        origin: origin,
        destination: destination,
        date: date,
        hour: 6,
        minute: 40,
        durationMinutes: 105,
        price: 31990,
        checkedKg: 0,
        assessment: PriceAssessment.good,
      ),
      _offer(
        id: '$route-kc622',
        airline: airAstana,
        number: 'KC 622',
        origin: origin,
        destination: destination,
        date: date,
        hour: 8,
        minute: 15,
        durationMinutes: 100,
        price: 42500,
        checkedKg: 23,
        refundable: true,
        assessment: PriceAssessment.average,
      ),
      _offer(
        id: '$route-dv704',
        airline: scat,
        number: 'DV 704',
        origin: origin,
        destination: destination,
        date: date,
        hour: 17,
        minute: 10,
        durationMinutes: 105,
        price: 36700,
        checkedKg: 20,
        assessment: PriceAssessment.good,
      ),
      _offer(
        id: '$route-dv-stop',
        airline: scat,
        number: 'DV 812',
        origin: origin,
        destination: destination,
        date: date,
        hour: 11,
        minute: 25,
        durationMinutes: 370,
        price: 28500,
        checkedKg: 20,
        stops: const ['KZO'],
        assessment: PriceAssessment.good,
      ),
    ];
  }

  FlightOffer _offer({
    required String id,
    required Airline airline,
    required String number,
    required Airport origin,
    required Airport destination,
    required DateTime date,
    required int hour,
    required int minute,
    required int durationMinutes,
    required int price,
    required int checkedKg,
    required PriceAssessment assessment,
    bool refundable = false,
    List<String> stops = const [],
  }) {
    final departure = DateTime(date.year, date.month, date.day, hour, minute);
    return FlightOffer(
      id: id,
      flight: Flight(
        id: 'flight-$id',
        airline: airline,
        flightNumber: number,
        origin: origin,
        destination: destination,
        departureAt: departure,
        arrivalAt: departure.add(Duration(minutes: durationMinutes)),
        stopAirportCodes: stops,
      ),
      priceKzt: price,
      fareName: checkedKg > 0 ? 'Standard' : 'Basic',
      cabinBaggageKg: 7,
      checkedBaggageKg: checkedKg,
      remainingSeats: 4 + id.length % 8,
      isRefundable: refundable,
      priceAssessment: assessment,
      priceHistory: List.generate(
        7,
        (index) => PriceHistoryPoint(
          recordedAt: date.subtract(Duration(days: 7 - index)),
          priceKzt: price + ((index % 3) - 1) * 1800,
        ),
      ),
    );
  }

  bool _matches(FlightOffer offer, FlightFilters? filters) {
    if (filters == null) return true;
    if (filters.minPriceKzt case final minimum? when offer.priceKzt < minimum) {
      return false;
    }
    if (filters.maxPriceKzt case final maximum? when offer.priceKzt > maximum) {
      return false;
    }
    if (filters.airlineCodes.isNotEmpty &&
        !filters.airlineCodes.contains(offer.flight.airline.code)) {
      return false;
    }
    if (filters.directOnly && !offer.flight.isDirect) return false;
    if (filters.checkedBaggageOnly && !offer.hasCheckedBaggage) return false;
    final hour = offer.flight.departureAt.hour;
    final from = filters.departureHourFrom;
    final to = filters.departureHourTo;
    if (from != null && to != null) {
      if (!(from <= to
          ? hour >= from && hour <= to
          : hour >= from || hour <= to)) {
        return false;
      }
    } else if (from != null && hour < from) {
      return false;
    } else if (to != null && hour > to) {
      return false;
    }
    return true;
  }
}
