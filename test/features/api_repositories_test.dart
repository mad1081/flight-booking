import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qanat/core/network/api_client.dart';
import 'package:qanat/features/bookings/data/api_booking_repository.dart';
import 'package:qanat/features/bookings/domain/booking_models.dart';
import 'package:qanat/features/flights/data/api_flight_repository.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';

void main() {
  final offer = <String, Object>{
    'offer_id': 'offer-1',
    'flight_id': 'flight-1',
    'price_kzt': 42500,
    'fare_name': 'Standard',
    'cabin_baggage_kg': 7,
    'checked_baggage_kg': 23,
    'remaining_seats': 12,
    'is_refundable': true,
    'price_assessment': 'good',
    'flight_number': 'KC 622',
    'departure_at': '2026-10-15T03:15:00+00:00',
    'arrival_at': '2026-10-15T04:55:00+00:00',
    'stop_airport_codes': <String>[],
    'origin_code': 'NQZ',
    'origin_city': 'Astana',
    'origin_name': 'Astana Airport',
    'destination_code': 'ALA',
    'destination_city': 'Almaty',
    'destination_name': 'Almaty Airport',
    'airline_code': 'KC',
    'airline_name': 'Air Astana',
    'airline_brand_color': 21147,
  };

  test('remote flight search parses catalog and price history', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/flights') {
        expect(request.url.queryParameters['origin'], 'NQZ');
        expect(request.url.queryParameters['departure_date'], '2026-10-15');
        return http.Response(jsonEncode([offer]), 200);
      }
      if (request.url.path == '/api/v1/offers/offer-1') {
        return http.Response(
          jsonEncode({
            'offer': offer,
            'price_history': [
              {'recorded_at': '2026-10-12T00:00:00+00:00', 'price_kzt': 48000},
            ],
          }),
          200,
        );
      }
      return http.Response('[]', 200);
    });
    final repository = ApiFlightRepository(
      ApiClient(baseUrl: 'https://api.example.test', client: client),
    );
    final results = await repository.searchFlights(
      FlightSearchCriteria(
        origin: const Airport(
          code: 'NQZ',
          city: 'Astana',
          name: 'Astana Airport',
        ),
        destination: const Airport(
          code: 'ALA',
          city: 'Almaty',
          name: 'Almaty Airport',
        ),
        departureDate: DateTime(2026, 10, 15),
      ),
    );
    expect(results.single.flight.flightNumber, 'KC 622');
    expect(results.single.priceHistory.single.priceKzt, 48000);
  });

  test(
    'remote booking sends only minimal passenger data with user JWT',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer user-token');
        expect(request.url.path, '/api/v1/bookings');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {
          'offer_id': 'offer-1',
          'seat_code': '3A',
          'passenger_name': 'Ayan Tester',
        });
        return http.Response(
          jsonEncode({
            'id': 'b7042db0-f341-48f2-955d-6df77918845e',
            'user_id': '4032da40-2ed6-4107-9b45-6101d52b5639',
            'offer_id': 'offer-1',
            'seat_code': '3A',
            'passenger_name': 'Ayan Tester',
            'total_kzt': 42500,
            'status': 'confirmed',
            'created_at': '2026-10-12T12:00:00+00:00',
            'origin_code': 'NQZ',
            'origin_city': 'Astana',
            'destination_code': 'ALA',
            'destination_city': 'Almaty',
            'airline_name': 'Air Astana',
            'flight_number': 'KC 622',
            'departure_at': '2026-10-15T03:15:00+00:00',
            'arrival_at': '2026-10-15T04:55:00+00:00',
            'fare_name': 'Standard',
            'checked_baggage_kg': 23,
          }),
          201,
        );
      });
      final repository = ApiBookingRepository(
        ApiClient(
          baseUrl: 'https://api.example.test',
          client: client,
          accessToken: () => 'user-token',
        ),
      );
      final flight = Flight(
        id: 'flight-1',
        airline: const Airline(
          code: 'KC',
          name: 'Air Astana',
          brandColor: 21147,
        ),
        flightNumber: 'KC 622',
        origin: const Airport(
          code: 'NQZ',
          city: 'Astana',
          name: 'Astana Airport',
        ),
        destination: const Airport(
          code: 'ALA',
          city: 'Almaty',
          name: 'Almaty Airport',
        ),
        departureAt: DateTime(2026, 10, 15, 8, 15),
        arrivalAt: DateTime(2026, 10, 15, 9, 55),
      );
      final draft = BookingDraft(
        offer: FlightOffer(
          id: 'offer-1',
          flight: flight,
          priceKzt: 42500,
          fareName: 'Standard',
          cabinBaggageKg: 7,
          checkedBaggageKg: 23,
          remainingSeats: 12,
          isRefundable: true,
          priceAssessment: PriceAssessment.good,
        ),
        seat: const Seat(code: '3A', kind: SeatKind.standard),
        passenger: PassengerDetails(
          firstName: 'Ayan',
          lastName: 'Tester',
          birthDate: DateTime(2000),
          documentNumber: 'SECRET-NOT-SENT',
          citizenship: 'Kazakhstan',
        ),
      );
      final booking = await repository.confirm(
        draft,
        '4032da40-2ed6-4107-9b45-6101d52b5639',
      );
      expect(booking.totalKzt, 42500);
      expect(booking.seatCode, '3A');
    },
  );
}
