import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/shell/application_shell.dart';
import 'package:qanat/app/splash/splash_screen.dart';
import 'package:qanat/features/auth/presentation/screens/login_screen.dart';
import 'package:qanat/features/auth/presentation/screens/profile_screen.dart';
import 'package:qanat/features/auth/presentation/screens/register_screen.dart';
import 'package:qanat/features/bookings/domain/booking_models.dart';
import 'package:qanat/features/bookings/presentation/screens/checkout_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/passenger_details_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/seat_selection_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/ticket_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/trips_list_screen.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';
import 'package:qanat/features/flights/presentation/screens/flight_details_screen.dart';
import 'package:qanat/features/flights/presentation/screens/flight_results_screen.dart';
import 'package:qanat/features/flights/presentation/screens/home_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const explore = '/explore';
  static const trips = '/trips';
  static const profile = '/profile';
  static const login = '/login';
  static const register = '/register';
  static const results = '/results';
  static const flightDetails = '/flight-details';
  static const seatSelection = '/seat-selection';
  static const passengerDetails = '/passenger-details';
  static const checkout = '/checkout';
  static const ticket = '/ticket';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final pendingOffer = state.extra is FlightOffer
              ? state.extra! as FlightOffer
              : null;
          return LoginScreen(
            onSuccess: () => pendingOffer == null
                ? context.go(AppRoutes.explore)
                : context.go(AppRoutes.flightDetails, extra: pendingOffer),
            onRegister: () => context.pushReplacement(
              AppRoutes.register,
              extra: pendingOffer,
            ),
            onContinueAsGuest: () => context.go(AppRoutes.explore),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) {
          final pendingOffer = state.extra is FlightOffer
              ? state.extra! as FlightOffer
              : null;
          return RegisterScreen(
            onSuccess: () => pendingOffer == null
                ? context.go(AppRoutes.explore)
                : context.go(AppRoutes.flightDetails, extra: pendingOffer),
            onLogin: () =>
                context.pushReplacement(AppRoutes.login, extra: pendingOffer),
            onContinueAsGuest: () => context.go(AppRoutes.explore),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.results,
        builder: (_, _) => const FlightResultsScreen(),
      ),
      GoRoute(
        path: AppRoutes.flightDetails,
        builder: (context, state) {
          final offer = state.extra;
          if (offer is! FlightOffer) {
            return const Scaffold(
              body: Center(child: Text('Рейс туралы ақпарат табылмады.')),
            );
          }
          return FlightDetailsScreen(offer: offer);
        },
      ),
      GoRoute(
        path: AppRoutes.seatSelection,
        builder: (_, state) => state.extra is FlightOffer
            ? SeatSelectionScreen(offer: state.extra! as FlightOffer)
            : const _MissingFlowData(),
      ),
      GoRoute(
        path: AppRoutes.passengerDetails,
        builder: (_, state) => state.extra is BookingDraft
            ? PassengerDetailsScreen(draft: state.extra! as BookingDraft)
            : const _MissingFlowData(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, state) => state.extra is BookingDraft
            ? CheckoutScreen(draft: state.extra! as BookingDraft)
            : const _MissingFlowData(),
      ),
      GoRoute(
        path: AppRoutes.ticket,
        builder: (_, state) => state.extra is Booking
            ? TicketScreen(booking: state.extra! as Booking)
            : const _MissingFlowData(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ApplicationShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.trips,
                builder: (_, _) => const TripsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _MissingFlowData extends StatelessWidget {
  const _MissingFlowData();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => context.go(AppRoutes.explore),
        child: const Text('Сапарды қайта бастау'),
      ),
    ),
  );
}
