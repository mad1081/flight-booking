import 'flight_models.dart';

abstract interface class FlightRepository {
  Future<List<Airport>> getAirports();
  Future<List<FlightOffer>> searchFlights(
    FlightSearchCriteria criteria, {
    FlightFilters? filters,
    FlightSort sort = FlightSort.recommended,
  });
  Future<FlightOffer?> getOfferById(String offerId);
}
