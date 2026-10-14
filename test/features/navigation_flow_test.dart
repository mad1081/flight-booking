import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/app/qanat_app.dart';
import 'package:qanat/features/auth/data/repositories/local_auth_repository.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qanat/features/auth/presentation/screens/login_screen.dart';
import 'package:qanat/features/auth/presentation/screens/profile_screen.dart';
import 'package:qanat/features/auth/presentation/screens/register_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/checkout_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/passenger_details_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/seat_selection_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/ticket_screen.dart';
import 'package:qanat/features/bookings/presentation/screens/trips_list_screen.dart';
import 'package:qanat/features/flights/application/flight_search_controller.dart';
import 'package:qanat/features/flights/data/mock_flight_repository.dart';
import 'package:qanat/features/flights/presentation/screens/flight_details_screen.dart';
import 'package:qanat/features/flights/presentation/screens/flight_results_screen.dart';
import 'package:qanat/features/flights/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('main navigation and booking route keep the selected flight', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final auth = LocalAuthRepository(MemoryAuthStore());
    await auth.register(
      name: 'Test User',
      email: 'test@example.com',
      password: 'Password123',
    );
    await auth.signOut();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          flightRepositoryProvider.overrideWithValue(
            MockFlightRepository(simulatedDelay: Duration.zero),
          ),
        ],
        child: const QanatApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Сапарлар'));
    await tester.pumpAndSettle();
    expect(find.byType(TripsListScreen), findsOneWidget);
    await tester.tap(find.text('Аккаунт'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.tap(find.text('Кіру немесе тіркелу'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.text('Аккаунт құру'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Аккаунтым бар — кіру'));
    await tester.tap(find.text('Аккаунтым бар — кіру'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.text('Қонақ ретінде жалғастыру'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.ensureVisible(find.text('Рейстерді табу'));
    await tester.tap(find.text('Рейстерді табу'));
    await tester.pumpAndSettle();
    expect(find.byType(FlightResultsScreen), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'after search results');
    await tester.ensureVisible(find.text('SCAT Airlines').first);
    await tester.tap(find.text('SCAT Airlines').first);
    await tester.pumpAndSettle();
    expect(find.byType(FlightDetailsScreen), findsOneWidget);
    await tester.tap(find.text('Жалғастыру'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
    await tester.tap(find.text('Кіру'));
    await tester.pumpAndSettle();
    expect(find.byType(FlightDetailsScreen), findsOneWidget);
    await tester.tap(find.text('Жалғастыру'));
    await tester.pumpAndSettle();
    expect(find.byType(SeatSelectionScreen), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'after seat screen');

    await tester.ensureVisible(find.byKey(const ValueKey('seat-3A')));
    await tester.tap(find.byKey(const ValueKey('seat-3A')));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(PassengerDetailsScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Test');
    await tester.enterText(find.byType(TextFormField).at(1), 'User');
    await tester.enterText(find.byType(TextFormField).at(2), 'AB12345');
    await tester.tap(find.text('Күнді таңдаңыз'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Броньды тексеру'));
    await tester.tap(find.text('Броньды тексеру'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutScreen), findsOneWidget);
    await tester.tap(find.text('Броньды растау').last);
    await tester.pumpAndSettle();
    expect(find.byType(TicketScreen), findsOneWidget);
    await tester.tap(find.text('Сапарларым'));
    await tester.pumpAndSettle();
    expect(find.byType(TripsListScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
