import 'package:qanat/core/network/api_client.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';
import 'package:qanat/features/flights/domain/flight_repository.dart';

class ApiFlightRepository implements FlightRepository {
  ApiFlightRepository(this._api);
  final ApiClient _api;
  final Map<String, FlightOffer> _cache = {};

  @override
  Future<List<Airport>> getAirports() async {
    final rows = await _api.get('/api/v1/airports') as List;
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row as Map);
      return Airport(
        code: data['code'] as String,
        city: data['city'] as String,
        name: data['name'] as String,
        country: data['country'] as String,
      );
    }).toList();
  }

  @override
  Future<List<FlightOffer>> searchFlights(
    FlightSearchCriteria criteria, {
    FlightFilters? filters,
    FlightSort sort = FlightSort.recommended,
  }) async {
    final date = criteria.departureDate;
    final query = <String, String>{
      'origin': criteria.origin.code,
      'destination': criteria.destination.code,
      'departure_date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'sort': switch (sort) {
        FlightSort.recommended => 'recommended',
        FlightSort.cheapest => 'cheapest',
        FlightSort.fastest => 'fastest',
        FlightSort.departureTime => 'departure_time',
      },
      'passengers': '${criteria.passengers.total}',
      if (filters?.maxPriceKzt != null)
        'max_price_kzt': '${filters!.maxPriceKzt}',
      if (filters?.directOnly == true) 'direct_only': 'true',
      if (filters?.checkedBaggageOnly == true) 'checked_baggage_only': 'true',
      if (filters?.departureHourFrom != null)
        'departure_hour_from': '${filters!.departureHourFrom}',
      if (filters?.departureHourTo != null)
        'departure_hour_to': '${filters!.departureHourTo}',
      if (filters != null && filters.airlineCodes.length == 1)
        'airline_code': filters.airlineCodes.single,
    };
    final rows = await _api.get('/api/v1/flights', query: query) as List;
    final offers = <FlightOffer>[];
    for (final row in rows) {
      final offer = _parseOffer(Map<String, dynamic>.from(row as Map));
      if (filters?.minPriceKzt != null &&
          offer.priceKzt < filters!.minPriceKzt!) {
        continue;
      }
      if (filters != null &&
          filters.airlineCodes.isNotEmpty &&
          !filters.airlineCodes.contains(offer.flight.airline.code)) {
        continue;
      }
      _cache[offer.id] = offer;
      offers.add(offer);
    }
    // Details include the mock price history used by the chart.
    return Future.wait(
      offers.map((offer) async => await getOfferById(offer.id) ?? offer),
    );
  }

  @override
  Future<FlightOffer?> getOfferById(String offerId) async {
    final response = await _api.get(
      '/api/v1/offers/${Uri.encodeComponent(offerId)}',
    );
    final data = Map<String, dynamic>.from(response as Map);
    final offer = _parseOffer(
      Map<String, dynamic>.from(data['offer'] as Map),
      history: data['price_history'] as List? ?? const [],
    );
    _cache[offer.id] = offer;
    return offer;
  }

  FlightOffer _parseOffer(
    Map<String, dynamic> data, {
    List history = const [],
  }) {
    final flight = Flight(
      id: data['flight_id'] as String,
      airline: Airline(
        code: data['airline_code'] as String,
        name: data['airline_name'] as String,
        brandColor: data['airline_brand_color'] as int,
      ),
      flightNumber: data['flight_number'] as String,
      origin: Airport(
        code: data['origin_code'] as String,
        city: data['origin_city'] as String,
        name: data['origin_name'] as String,
      ),
      destination: Airport(
        code: data['destination_code'] as String,
        city: data['destination_city'] as String,
        name: data['destination_name'] as String,
      ),
      departureAt: DateTime.parse(data['departure_at'] as String).toLocal(),
      arrivalAt: DateTime.parse(data['arrival_at'] as String).toLocal(),
      stopAirportCodes: List<String>.from(data['stop_airport_codes'] as List),
    );
    return FlightOffer(
      id: data['offer_id'] as String,
      flight: flight,
      priceKzt: data['price_kzt'] as int,
      fareName: data['fare_name'] as String,
      cabinBaggageKg: data['cabin_baggage_kg'] as int,
      checkedBaggageKg: data['checked_baggage_kg'] as int,
      remainingSeats: data['remaining_seats'] as int,
      isRefundable: data['is_refundable'] as bool,
      priceAssessment: switch (data['price_assessment']) {
        'good' => PriceAssessment.good,
        'high' => PriceAssessment.high,
        _ => PriceAssessment.average,
      },
      priceHistory: history.map((point) {
        final item = Map<String, dynamic>.from(point as Map);
        return PriceHistoryPoint(
          recordedAt: DateTime.parse(item['recorded_at'] as String).toLocal(),
          priceKzt: item['price_kzt'] as int,
        );
      }).toList(),
    );
  }
}
