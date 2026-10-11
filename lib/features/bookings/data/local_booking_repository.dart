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

  @override
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
