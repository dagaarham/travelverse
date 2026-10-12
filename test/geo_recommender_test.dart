import 'package:flutter_test/flutter_test.dart';
import 'package:travelverse/core/geo.dart';
import 'package:travelverse/core/recommender.dart';
import 'package:travelverse/data/models/place.dart';
import 'package:travelverse/data/models/review.dart';
import 'package:travelverse/data/seed/places_seed.dart';

Review _review(String placeId, double rating) => Review(
      placeId: placeId,
      userId: 'u1',
      userName: 'Test',
      rating: rating,
      valueRating: rating,
      cleanlinessRating: rating,
      accessibilityRating: rating,
      text: 'A review that is long enough',
      recommend: rating >= 3,
      bestTime: '',
      verifiedVisit: true,
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  group('Geo', () {
    test('Mumbai to Pune is about 120 km', () {
      final km = Geo.distanceKm(19.0760, 72.8777, 18.5204, 73.8567);
      expect(km, closeTo(120, 5));
    });
    test('distance to self is zero', () => expect(Geo.distanceKm(10, 10, 10, 10), 0));
    test('formats metres and kilometres', () {
      expect(Geo.format(0.45), '450 m');
      expect(Geo.format(3.24), '3.2 km');
      expect(Geo.format(42.6), '43 km');
    });
  });

  group('Seed data', () {
    test('ids are unique', () => expect(seedPlaces.map((p) => p.id).toSet().length, seedPlaces.length));
    test('coordinates are inside India', () {
      for (final p in seedPlaces) {
        expect(p.lat, inInclusiveRange(6, 37), reason: p.name);
        expect(p.lng, inInclusiveRange(68, 98), reason: p.name);
      }
    });
  });

  group('Recommender', () {
    const r = Recommender();
    double ratingOf(Place p) => p.seedRating;

    test('interests push matching categories to the top', () {
      final recs = r.recommend(places: seedPlaces, interests: ['beach'], myReviews: const [], visitedIds: const {}, ratingOf: ratingOf);
      expect(recs.first.place.category, PlaceCategory.beach);
      expect(recs.first.reason, contains('Beach'));
    });

    test('visited places are never recommended', () {
      final recs = r.recommend(places: seedPlaces, interests: ['heritage'], myReviews: const [], visitedIds: {'taj-mahal'}, ratingOf: ratingOf, limit: 50);
      expect(recs.any((x) => x.place.id == 'taj-mahal'), isFalse);
    });

    test('learns from high review ratings', () {
      final affinity = r.categoryAffinity([_review('solang-valley', 5), _review('baga-beach', 1)], {for (final p in seedPlaces) p.id: p});
      expect(affinity[PlaceCategory.adventure], 1.0);
      expect(affinity[PlaceCategory.beach], -1.0);
    });

    test('nearby places get a proximity reason', () {
      final recs = r.recommend(
          places: seedPlaces, interests: const [], myReviews: const [], visitedIds: const {}, ratingOf: ratingOf, lat: 18.92, lng: 72.83, limit: 50);
      expect(recs.any((x) => x.reason.contains('away')), isTrue);
    });

    test('hidden gems are well rated and less popular', () {
      final gems = r.hiddenGems(seedPlaces, ratingOf);
      expect(gems, isNotEmpty);
      for (final g in gems) {
        expect(g.popularity, lessThanOrEqualTo(50));
        expect(g.seedRating, greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('PlaceStats', () {
    test('combines seed baseline with app reviews', () {
      final place = seedPlaces.first; // 4.5 from 1840 ratings
      const stats = PlaceStats(reviewCount: 1, ratingSum: 1, recommendCount: 0);
      expect(stats.ratingFor(place), closeTo((4.5 * 1840 + 1) / 1841, 1e-9));
      expect(stats.recommendPercent, 0);
      expect(const PlaceStats().recommendPercent, isNull);
    });
  });
}
