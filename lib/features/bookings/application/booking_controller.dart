import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';

import '../data/local_booking_repository.dart';
import '../domain/booking_models.dart';
import '../domain/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => LocalBookingRepository(),
);

final bookingsProvider =
    AsyncNotifierProvider<BookingsController, List<Booking>>(
      BookingsController.new,
    );

class BookingsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final user = await ref.watch(authControllerProvider.future);
    if (user == null) return const [];
    return ref.read(bookingRepositoryProvider).forUser(user.id);
  }

  Future<Booking> confirm(BookingDraft draft) async {
    final user = await ref.read(authControllerProvider.future);
    final passenger = draft.passenger;
    if (user == null) throw StateError('Login is required to book a flight.');
    if (passenger == null) throw StateError('Passenger details are required.');
    final offer = draft.offer;
    final flight = offer.flight;
    final now = DateTime.now();
    final booking = Booking(
      id: 'QN${now.microsecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      userId: user.id,
      passengerName: passenger.fullName,
      seatCode: draft.seat.code,
      originCode: flight.origin.code,
      destinationCode: flight.destination.code,
      originCity: flight.origin.city,
      destinationCity: flight.destination.city,
      airlineName: flight.airline.name,
      flightNumber: flight.flightNumber,
      departureAt: flight.departureAt,
      arrivalAt: flight.arrivalAt,
      fareName: offer.fareName,
      baggageKg: offer.checkedBaggageKg,
      totalKzt: draft.totalKzt,
      createdAt: now,
    );
    await ref.read(bookingRepositoryProvider).save(booking);
    ref.invalidateSelf();
    return booking;
  }
}
