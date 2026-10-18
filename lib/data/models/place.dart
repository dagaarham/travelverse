import 'package:flutter/material.dart';

/// Kinds of places the catalogue supports. Used for filters, interests and
/// the recommendation engine.
enum PlaceCategory {
  heritage('Heritage', Icons.account_balance, Color(0xFF8D6E63)),
  nature('Nature', Icons.landscape, Color(0xFF2E7D32)),
  beach('Beach', Icons.beach_access, Color(0xFF0288D1)),
  adventure('Adventure', Icons.hiking, Color(0xFFEF6C00)),
  food('Food', Icons.restaurant, Color(0xFFC62828)),
  spiritual('Spiritual', Icons.temple_hindu, Color(0xFF6A1B9A)),
  shopping('Shopping', Icons.shopping_bag, Color(0xFFAD1457)),
  nightlife('Nightlife', Icons.nightlife, Color(0xFF283593));

  const PlaceCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static PlaceCategory fromName(String name) => PlaceCategory.values.firstWhere((c) => c.name == name, orElse: () => PlaceCategory.nature);
}

/// A destination in the catalogue. Immutable; community numbers that change
/// over time live in [PlaceStats].
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.category,
    required this.lat,
    required this.lng,
    required this.budget,
    required this.seedRating,
    required this.seedReviews,
    required this.popularity,
    required this.wikiTitle,
    required this.bestTime,
    required this.idealFor,
    required this.description,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final PlaceCategory category;
  final double lat;
  final double lng;

  /// 1 = budget friendly, 2 = moderate, 3 = premium.
  final int budget;
  final double seedRating;
  final int seedReviews;

  /// 0-100 relative footfall. Low popularity + high rating = hidden gem.
  final int popularity;
  final String wikiTitle;
  final String bestTime;
  final List<String> idealFor;
  final String description;

  String get location => '$city, $state';

  /// Bundled photo, downloaded from Wikimedia Commons by tool/fetch_place_photos.py.
  String get photoAsset => 'assets/places/$id.jpg';
  String get budgetLabel => '₹' * budget;
}

/// Live community numbers for a place: seed baseline plus in-app reviews.
class PlaceStats {
  const PlaceStats({
    this.reviewCount = 0,
    this.ratingSum = 0,
    this.recommendCount = 0,
    this.valueSum = 0,
    this.cleanlinessSum = 0,
    this.accessibilitySum = 0,
    this.visitedCount = 0,
    this.savedCount = 0,
  });

  final int reviewCount;
  final double ratingSum;
  final int recommendCount;
  final double valueSum;
  final double cleanlinessSum;
  final double accessibilitySum;
  final int visitedCount;
  final int savedCount;

  factory PlaceStats.fromMap(Map<String, dynamic> map) => PlaceStats(
    reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
    ratingSum: (map['ratingSum'] as num?)?.toDouble() ?? 0,
    recommendCount: (map['recommendCount'] as num?)?.toInt() ?? 0,
    valueSum: (map['valueSum'] as num?)?.toDouble() ?? 0,
    cleanlinessSum: (map['cleanlinessSum'] as num?)?.toDouble() ?? 0,
    accessibilitySum: (map['accessibilitySum'] as num?)?.toDouble() ?? 0,
    visitedCount: (map['visitedCount'] as num?)?.toInt() ?? 0,
    savedCount: (map['savedCount'] as num?)?.toInt() ?? 0,
  );

  /// Rating combining the curated baseline with app reviews.
  double ratingFor(Place place) {
    final total = place.seedRating * place.seedReviews + ratingSum;
    final count = place.seedReviews + reviewCount;
    return count == 0 ? 0 : total / count;
  }

  int totalReviewsFor(Place place) => place.seedReviews + reviewCount;

  /// Share of in-app reviewers who said they'd recommend the place, or null
  /// when nobody has answered yet.
  int? get recommendPercent => reviewCount == 0 ? null : ((recommendCount / reviewCount) * 100).round();

  double? average(double sum) => reviewCount == 0 ? null : sum / reviewCount;
}
