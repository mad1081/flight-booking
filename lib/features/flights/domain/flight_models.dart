enum CabinClass { economy, premiumEconomy, business }

enum PriceAssessment { good, average, high }

enum FlightSort { recommended, cheapest, fastest, departureTime }

class Airport {
  const Airport({
    required this.code,
    required this.name,
    required this.city,
    this.country = 'Kazakhstan',
  });
  final String code;
  final String name;
  final String city;
  final String country;
  @override
  bool operator ==(Object other) => other is Airport && other.code == code;
  @override
  int get hashCode => code.hashCode;
}

class Airline {
  const Airline({
    required this.code,
    required this.name,
    required this.brandColor,
  });
  final String code;
  final String name;
  final int brandColor;
}

class PriceHistoryPoint {
  const PriceHistoryPoint({required this.recordedAt, required this.priceKzt});
  final DateTime recordedAt;
  final int priceKzt;
}

class PassengerCounts {
  const PassengerCounts({this.adults = 1, this.children = 0, this.infants = 0})
    : assert(adults > 0),
      assert(children >= 0),
      assert(infants >= 0),
      assert(infants <= adults);
  final int adults;
  final int children;
  final int infants;
  int get total => adults + children + infants;
}

class FlightSearchCriteria {
  FlightSearchCriteria({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.passengers = const PassengerCounts(),
    this.cabinClass = CabinClass.economy,
  }) : assert(origin != destination),
       assert(returnDate == null || !returnDate.isBefore(departureDate));
  final Airport origin;
  final Airport destination;
  final DateTime departureDate;
  final DateTime? returnDate;
  final PassengerCounts passengers;
  final CabinClass cabinClass;
  bool get isRoundTrip => returnDate != null;
}

class FlightFilters {
  FlightFilters({
    this.minPriceKzt,
    this.maxPriceKzt,
    Set<String> airlineCodes = const {},
    this.departureHourFrom,
    this.departureHourTo,
    this.directOnly = false,
    this.checkedBaggageOnly = false,
  }) : assert(minPriceKzt == null || minPriceKzt >= 0),
       assert(maxPriceKzt == null || maxPriceKzt >= 0),
       assert(
         minPriceKzt == null ||
             maxPriceKzt == null ||
             minPriceKzt <= maxPriceKzt,
       ),
       airlineCodes = Set.unmodifiable(airlineCodes);
  final int? minPriceKzt;
  final int? maxPriceKzt;
  final Set<String> airlineCodes;
  final int? departureHourFrom;
  final int? departureHourTo;
  final bool directOnly;
  final bool checkedBaggageOnly;
}

class Flight {
  Flight({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.arrivalAt,
    List<String> stopAirportCodes = const [],
  }) : assert(arrivalAt.isAfter(departureAt)),
       stopAirportCodes = List.unmodifiable(stopAirportCodes);
  final String id;
  final Airline airline;
  final String flightNumber;
  final Airport origin;
  final Airport destination;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final List<String> stopAirportCodes;
  Duration get duration => arrivalAt.difference(departureAt);
  int get stops => stopAirportCodes.length;
  bool get isDirect => stops == 0;
}

class FlightOffer {
  FlightOffer({
    required this.id,
    required this.flight,
    required this.priceKzt,
    required this.fareName,
    required this.cabinBaggageKg,
    required this.checkedBaggageKg,
    required this.remainingSeats,
    required this.isRefundable,
    required this.priceAssessment,
    List<PriceHistoryPoint> priceHistory = const [],
  }) : assert(priceKzt > 0),
       assert(cabinBaggageKg >= 0),
       assert(checkedBaggageKg >= 0),
       assert(remainingSeats >= 0),
       priceHistory = List.unmodifiable(priceHistory);
  final String id;
  final Flight flight;
  final int priceKzt;
  final String fareName;
  final int cabinBaggageKg;
  final int checkedBaggageKg;
  final int remainingSeats;
  final bool isRefundable;
  final PriceAssessment priceAssessment;
  final List<PriceHistoryPoint> priceHistory;
  bool get hasCheckedBaggage => checkedBaggageKg > 0;
}
