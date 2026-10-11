import 'package:qanat/features/flights/domain/flight_models.dart';

enum SeatKind { standard, premium }

class Seat {
  const Seat({required this.code, required this.kind});
  final String code;
  final SeatKind kind;
  int get surchargeKzt => kind == SeatKind.premium ? 9000 : 0;
}

class PassengerDetails {
  const PassengerDetails({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.documentNumber,
    required this.citizenship,
  });

  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String documentNumber;
  final String citizenship;
  String get fullName => '$firstName $lastName';
}

/// Exists only while the checkout flow is open. Document data is never saved.
class BookingDraft {
  const BookingDraft({required this.offer, required this.seat, this.passenger});
  final FlightOffer offer;
  final Seat seat;
  final PassengerDetails? passenger;
  int get totalKzt => offer.priceKzt + seat.surchargeKzt;

  BookingDraft withPassenger(PassengerDetails value) =>
      BookingDraft(offer: offer, seat: seat, passenger: value);
}

/// The persisted ticket contains only the fields needed to display a trip.
class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.passengerName,
    required this.seatCode,
    required this.originCode,
    required this.destinationCode,
    required this.originCity,
    required this.destinationCity,
    required this.airlineName,
    required this.flightNumber,
    required this.departureAt,
    required this.arrivalAt,
    required this.fareName,
    required this.baggageKg,
    required this.totalKzt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String passengerName;
  final String seatCode;
  final String originCode;
  final String destinationCode;
  final String originCity;
  final String destinationCity;
  final String airlineName;
  final String flightNumber;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final String fareName;
  final int baggageKg;
  final int totalKzt;
  final DateTime createdAt;

  bool get isUpcoming => !departureAt.isBefore(DateTime.now());

  Map<String, Object> toJson() => {
    'id': id,
    'userId': userId,
    'passengerName': passengerName,
    'seatCode': seatCode,
    'originCode': originCode,
    'destinationCode': destinationCode,
    'originCity': originCity,
    'destinationCity': destinationCity,
    'airlineName': airlineName,
    'flightNumber': flightNumber,
    'departureAt': departureAt.toIso8601String(),
    'arrivalAt': arrivalAt.toIso8601String(),
    'fareName': fareName,
    'baggageKg': baggageKg,
    'totalKzt': totalKzt,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Booking.fromJson(Map<String, Object?> json) => Booking(
    id: json['id']! as String,
    userId: json['userId']! as String,
    passengerName: json['passengerName']! as String,
    seatCode: json['seatCode']! as String,
    originCode: json['originCode']! as String,
    destinationCode: json['destinationCode']! as String,
    originCity: json['originCity']! as String,
    destinationCity: json['destinationCity']! as String,
    airlineName: json['airlineName']! as String,
    flightNumber: json['flightNumber']! as String,
    departureAt: DateTime.parse(json['departureAt']! as String),
    arrivalAt: DateTime.parse(json['arrivalAt']! as String),
    fareName: json['fareName']! as String,
    baggageKg: json['baggageKg']! as int,
    totalKzt: json['totalKzt']! as int,
    createdAt: DateTime.parse(json['createdAt']! as String),
  );
}
