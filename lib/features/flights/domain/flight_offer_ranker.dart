import 'flight_models.dart';

class RankedFlightOffer {
  const RankedFlightOffer({required this.offer, required this.bestScore});
  final FlightOffer offer;
  final double bestScore;
}

class FlightOfferRanker {
  const FlightOfferRanker();
  FlightOffer? cheapest(Iterable<FlightOffer> offers) =>
      _minimum(offers, (offer) => offer.priceKzt);
  FlightOffer? fastest(Iterable<FlightOffer> offers) =>
      _minimum(offers, (offer) => offer.flight.duration.inMinutes);
  FlightOffer? best(Iterable<FlightOffer> offers) {
    final ranked = rank(offers);
    return ranked.isEmpty ? null : ranked.first.offer;
  }

  List<RankedFlightOffer> rank(Iterable<FlightOffer> offers) {
    final items = List<FlightOffer>.of(offers);
    if (items.isEmpty) return const [];
    final minPrice = items.map((e) => e.priceKzt).reduce(_min);
    final maxPrice = items.map((e) => e.priceKzt).reduce(_max);
    final minDuration = items
        .map((e) => e.flight.duration.inMinutes)
        .reduce(_min);
    final maxDuration = items
        .map((e) => e.flight.duration.inMinutes)
        .reduce(_max);
    final maxStops = items.map((e) => e.flight.stops).reduce(_max);
    final ranked =
        items.map((offer) {
          final priceCost = _normalize(offer.priceKzt, minPrice, maxPrice);
          final durationCost = _normalize(
            offer.flight.duration.inMinutes,
            minDuration,
            maxDuration,
          );
          final stopsCost = maxStops == 0 ? 0.0 : offer.flight.stops / maxStops;
          final baggageCost = offer.hasCheckedBaggage ? 0.0 : 1.0;
          final totalCost =
              priceCost * .45 +
              durationCost * .30 +
              stopsCost * .15 +
              baggageCost * .10;
          return RankedFlightOffer(
            offer: offer,
            bestScore: (1 - totalCost) * 100,
          );
        }).toList()..sort((a, b) {
          var order = b.bestScore.compareTo(a.bestScore);
          if (order != 0) return order;
          order = a.offer.priceKzt.compareTo(b.offer.priceKzt);
          if (order != 0) return order;
          order = a.offer.flight.duration.compareTo(b.offer.flight.duration);
          return order != 0 ? order : a.offer.id.compareTo(b.offer.id);
        });
    return List.unmodifiable(ranked);
  }

  FlightOffer? _minimum(
    Iterable<FlightOffer> offers,
    int Function(FlightOffer) value,
  ) {
    FlightOffer? winner;
    for (final offer in offers) {
      if (winner == null ||
          value(offer) < value(winner) ||
          (value(offer) == value(winner) &&
              offer.id.compareTo(winner.id) < 0)) {
        winner = offer;
      }
    }
    return winner;
  }

  static int _min(int a, int b) => a < b ? a : b;
  static int _max(int a, int b) => a > b ? a : b;
  static double _normalize(int value, int minimum, int maximum) =>
      maximum == minimum ? 0 : (value - minimum) / (maximum - minimum);
}
