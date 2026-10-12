import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/flights/application/flight_search_controller.dart';
import 'package:qanat/features/flights/data/mock_flight_repository.dart';
import 'package:qanat/features/flights/presentation/screens/flight_results_screen.dart';
import 'package:qanat/features/flights/presentation/screens/home_screen.dart';

void main() {
  testWidgets('both airport pickers scroll on a short screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightRepositoryProvider.overrideWithValue(
            MockFlightRepository(simulatedDelay: Duration.zero),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Қайдан', 'Қайда']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Shymkent'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      Navigator.of(tester.element(find.text('Shymkent'))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('passenger picker fits a short screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flightRepositoryProvider.overrideWithValue(
            MockFlightRepository(simulatedDelay: Duration.zero),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Жолаушылар'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Жолаушылар'));
    await tester.pumpAndSettle();
    expect(find.text('Ересектер'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flight filters fit a short screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FlightResultsScreen())),
    );
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
