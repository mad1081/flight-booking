import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/app/qanat_app.dart';
import 'package:qanat/features/auth/data/repositories/local_auth_repository.dart';
import 'package:qanat/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qanat/features/flights/application/flight_search_controller.dart';
import 'package:qanat/features/flights/data/mock_flight_repository.dart';
import 'package:qanat/features/flights/presentation/screens/flight_results_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('flight results fit a 390 pixel screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            LocalAuthRepository(MemoryAuthStore()),
          ),
          flightRepositoryProvider.overrideWithValue(
            MockFlightRepository(simulatedDelay: Duration.zero),
          ),
        ],
        child: const QanatApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Рейстерді табу'));
    await tester.tap(find.text('Рейстерді табу'));
    await tester.pumpAndSettle();
    expect(find.byType(FlightResultsScreen), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
