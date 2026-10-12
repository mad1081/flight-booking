import 'booking_models.dart';

abstract interface class BookingRepository {
  Future<List<Booking>> forUser(String userId);
  Future<Booking> confirm(BookingDraft draft, String userId);
}
