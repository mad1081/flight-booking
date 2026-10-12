import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qanat/core/config/app_environment.dart';
import 'package:qanat/core/network/api_client_provider.dart';

import '../data/api_booking_repository.dart';
import '../data/local_booking_repository.dart';
import '../domain/booking_models.dart';
import '../domain/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => AppEnvironment.isConfigured
      ? ApiBookingRepository(ref.watch(apiClientProvider))
      : LocalBookingRepository(),
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
    if (user == null) throw StateError('Login is required to book a flight.');
    final booking = await ref
        .read(bookingRepositoryProvider)
        .confirm(draft, user.id);
    ref.invalidateSelf();
    return booking;
  }
}
