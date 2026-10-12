import '../data/models/place.dart';
import '../data/models/review.dart';
import 'geo.dart';

/// A recommended place with the reason shown to the user.
class Recommendation {
  const Recommendation(this.place, this.score, this.reason);

  final Place place;
  final double score;
  final String reason;
}

/// Content-based recommendation engine.
///
/// Score = interest match + learned category affinity (from the traveller's
/// own review ratings) + community rating + travel-style fit + proximity.
/// Places the user has already visited are excluded.
class Recommender {
  const Recommender({
    this.interestWeight = 2.0,
    this.affinityWeight = 3.0,
    this.ratingWeight = 1.5,
    this.styleWeight = 0.5,
    this.proximityWeight = 1.0,
  });

  final double interestWeight;
  final double affinityWeight;
  final double ratingWeight;
  final double styleWeight;
  final double proximityWeight;

  /// Average rating the user gave per category, centred on 3 and scaled to
  /// -1..1, so a 5-star category pulls recommendations towards it and a
  /// 1-star category pushes them away.
  Map<PlaceCategory, double> categoryAffinity(List<Review> myReviews, Map<String, Place> byId) {
    final sums = <PlaceCategory, double>{};
    final counts = <PlaceCategory, int>{};
    for (final r in myReviews) {
      final place = byId[r.placeId];
      if (place == null) continue;
      sums[place.category] = (sums[place.category] ?? 0) + r.rating;
      counts[place.category] = (counts[place.category] ?? 0) + 1;
    }
    return {for (final c in sums.keys) c: ((sums[c]! / counts[c]!) - 3) / 2};
  }

  List<Recommendation> recommend({
    required List<Place> places,
    required List<String> interests,
    required List<Review> myReviews,
    required Set<String> visitedIds,
    required double Function(Place) ratingOf,
    String travelStyle = '',
    double? lat,
    double? lng,
    int limit = 10,
  }) {
    final byId = {for (final p in places) p.id: p};
    final affinity = categoryAffinity(myReviews, byId);
    final results = <Recommendation>[];

    for (final p in places) {
      if (visitedIds.contains(p.id)) continue;
      var score = 0.0;
      final reasons = <String, double>{};

      if (interests.contains(p.category.name)) {
        score += interestWeight;
        reasons['Matches your interest in ${p.category.label}'] = interestWeight;
      }
      final a = affinity[p.category];
      if (a != null) {
        score += affinityWeight * a;
        if (a > 0) reasons['Because you rated ${p.category.label} places highly'] = affinityWeight * a;
      }
      final rating = ratingOf(p);
      final ratingScore = ratingWeight * ((rating - 3.5) / 1.5).clamp(-1.0, 1.0);
      score += ratingScore;
      if (rating >= 4.6) reasons['Loved by travellers (${rating.toStringAsFixed(1)}★)'] = ratingScore;

      if (travelStyle.isNotEmpty && p.idealFor.contains(travelStyle)) {
        score += styleWeight;
        reasons['Great for $travelStyle trips'] = styleWeight;
      }
      if (lat != null && lng != null) {
        final km = Geo.distanceKm(lat, lng, p.lat, p.lng);
        final near = proximityWeight * (1 - (km / 500).clamp(0.0, 1.0));
        score += near;
        if (km < 50) reasons['Only ${Geo.format(km)} away'] = near + 0.01;
      }

      final reason = reasons.isEmpty
          ? 'Popular with travellers'
          : (reasons.entries.toList()..sort((x, y) => y.value.compareTo(x.value))).first.key;
      results.add(Recommendation(p, score, reason));
    }

    results.sort((x, y) => y.score.compareTo(x.score));
    return results.take(limit).toList();
  }

  /// Highly rated but rarely visited places.
  List<Place> hiddenGems(List<Place> places, double Function(Place) ratingOf, {int limit = 8}) {
    final gems = places.where((p) => p.popularity <= 50 && ratingOf(p) >= 4.5).toList()..sort((a, b) => ratingOf(b).compareTo(ratingOf(a)));
    return gems.take(limit).toList();
  }

  /// Places in the same category as [liked], nearest first.
  List<Place> similarTo(Place liked, List<Place> places, {Set<String> exclude = const {}, int limit = 6}) {
    final similar = places.where((p) => p.id != liked.id && p.category == liked.category && !exclude.contains(p.id)).toList()
      ..sort((a, b) => Geo.distanceKm(liked.lat, liked.lng, a.lat, a.lng).compareTo(Geo.distanceKm(liked.lat, liked.lng, b.lat, b.lng)));
    return similar.take(limit).toList();
  }
}
