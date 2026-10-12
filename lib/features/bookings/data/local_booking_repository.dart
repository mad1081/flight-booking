import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/booking_models.dart';
import '../domain/booking_repository.dart';

class LocalBookingRepository implements BookingRepository {
  LocalBookingRepository({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _storageKey = 'qanat.bookings.v1';
  final Future<SharedPreferences> _preferences;

  @override
  Future<List<Booking>> forUser(String userId) async {
    final all = await _readAll();
    return all.where((booking) => booking.userId == userId).toList()
      ..sort((a, b) => a.departureAt.compareTo(b.departureAt));
  }

  Future<void> save(Booking booking) async {
    final preferences = await _preferences;
    final all = await _readAll();
    if (all.any((existing) => existing.id == booking.id)) return;
    all.add(booking);
    await preferences.setStringList(
      _storageKey,
      all.map((value) => jsonEncode(value.toJson())).toList(),
    );
  }

  @override
  Future<Booking> confirm(BookingDraft draft, String userId) async {
    final passenger = draft.passenger;
    if (passenger == null) throw StateError('Passenger details are required.');
    final offer = draft.offer;
    final flight = offer.flight;
    final now = DateTime.now();
    final booking = Booking(
      id: 'QN${now.microsecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      userId: userId,
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
    await save(booking);
    return booking;
  }

  Future<List<Booking>> _readAll() async {
    final preferences = await _preferences;
    final stored = preferences.getStringList(_storageKey) ?? const [];
    final bookings = <Booking>[];
    for (final encoded in stored) {
      try {
        bookings.add(
          Booking.fromJson(jsonDecode(encoded) as Map<String, Object?>),
        );
      } on FormatException {
        // Keep valid tickets even when a single local record is damaged.
      } on TypeError {
        // Skip records from an incompatible schema.
      }
    }
    return bookings;
  }
}
