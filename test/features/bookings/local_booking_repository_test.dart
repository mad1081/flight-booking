import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/bookings/data/local_booking_repository.dart';
import 'package:qanat/features/bookings/domain/booking_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Booking booking(String id, String userId) => Booking(
    id: id,
    userId: userId,
    passengerName: 'Ayan Tester',
    seatCode: '3A',
    originCode: 'NQZ',
    destinationCode: 'ALA',
    originCity: 'Astana',
    destinationCity: 'Almaty',
    airlineName: 'Air Astana',
    flightNumber: 'KC 622',
    departureAt: DateTime(2027, 1, 10, 8),
    arrivalAt: DateTime(2027, 1, 10, 10),
    fareName: 'Standard',
    baggageKg: 23,
    totalKzt: 42500,
    createdAt: DateTime(2026, 10, 11),
  );

  test(
    'persists tickets across repository instances and isolates users',
    () async {
      final first = LocalBookingRepository();
      await first.save(booking('QN001', 'user-a'));
      await first.save(booking('QN002', 'user-b'));

      final reopened = LocalBookingRepository();
      final aliceTrips = await reopened.forUser('user-a');
      expect(aliceTrips, hasLength(1));
      expect(aliceTrips.single.id, 'QN001');
      expect(aliceTrips.single.passengerName, 'Ayan Tester');
      expect(await reopened.forUser('user-b'), hasLength(1));
      expect(await reopened.forUser('guest'), isEmpty);
    },
  );

  test('does not duplicate the same booking id', () async {
    final repository = LocalBookingRepository();
    await repository.save(booking('QN001', 'user-a'));
    await repository.save(booking('QN001', 'user-a'));
    expect(await repository.forUser('user-a'), hasLength(1));
  });

  test('ticket snapshot contains no document or birth date', () {
    final saved = booking('QN001', 'user-a').toJson();
    expect(saved.keys, isNot(contains('documentNumber')));
    expect(saved.keys, isNot(contains('birthDate')));
  });
}
