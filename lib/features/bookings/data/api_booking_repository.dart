import 'package:qanat/core/network/api_client.dart';

import '../domain/booking_models.dart';
import '../domain/booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Booking>> forUser(String userId) async {
    final rows = await _api.get('/api/v1/bookings', authorized: true) as List;
    return rows
        .map((row) => _parse(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<Booking> confirm(BookingDraft draft, String userId) async {
    final passenger = draft.passenger;
    if (passenger == null) throw StateError('Passenger details are required.');
    final result = await _api.post('/api/v1/bookings', {
      'offer_id': draft.offer.id,
      'seat_code': draft.seat.code,
      'passenger_name': passenger.fullName,
    }, authorized: true);
    return _parse(Map<String, dynamic>.from(result as Map));
  }

  Booking _parse(Map<String, dynamic> data) => Booking(
    id: data['id'] as String,
    userId: data['user_id'] as String,
    passengerName: data['passenger_name'] as String,
    seatCode: data['seat_code'] as String,
    originCode: data['origin_code'] as String,
    destinationCode: data['destination_code'] as String,
    originCity: data['origin_city'] as String,
    destinationCity: data['destination_city'] as String,
    airlineName: data['airline_name'] as String,
    flightNumber: data['flight_number'] as String,
    departureAt: DateTime.parse(data['departure_at'] as String).toLocal(),
    arrivalAt: DateTime.parse(data['arrival_at'] as String).toLocal(),
    fareName: data['fare_name'] as String,
    baggageKg: data['checked_baggage_kg'] as int,
    totalKzt: data['total_kzt'] as int,
    createdAt: DateTime.parse(data['created_at'] as String).toLocal(),
  );
}
