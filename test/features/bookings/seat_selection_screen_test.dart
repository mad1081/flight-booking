import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qanat/features/bookings/presentation/screens/seat_selection_screen.dart';
import 'package:qanat/features/flights/data/mock_flight_repository.dart';
import 'package:qanat/features/flights/domain/flight_models.dart';

void main() {
  testWidgets('seat map fits a small screen and enables continuation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockFlightRepository(simulatedDelay: Duration.zero);
    final offers = await tester.runAsync(
      () => repository.searchFlights(
        FlightSearchCriteria(
          origin: MockFlightRepository.astana,
          destination: MockFlightRepository.almaty,
          departureDate: DateTime(2027, 1, 10),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: SeatSelectionScreen(offer: offers!.first)),
    );
    expect(tester.takeException(), isNull);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('seat-3A')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
