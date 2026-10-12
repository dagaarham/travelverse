import 'package:flutter/material.dart';

import '../data/models/place.dart';

class TravelBadge {
  const TravelBadge(this.title, this.description, this.icon, this.earned, this.progress);

  final String title;
  final String description;
  final IconData icon;
  final bool earned;

  /// 0..1 towards earning the badge.
  final double progress;
}

/// Gamification badges derived from the traveller's activity.
List<TravelBadge> computeBadges({
  required List<Place> visited,
  required int reviewCount,
  required int tripCount,
  required int journalCount,
}) {
  int count(PlaceCategory c) => visited.where((p) => p.category == c).length;
  final cities = visited.map((p) => p.city).toSet().length;
  TravelBadge b(String t, String d, IconData i, int have, int need) => TravelBadge(t, d, i, have >= need, (have / need).clamp(0.0, 1.0));
  return [
    b('First Steps', 'Mark your first place as visited', Icons.directions_walk, visited.length, 1),
    b('History Buff', 'Visit 3 heritage sites', Icons.account_balance, count(PlaceCategory.heritage), 3),
    b('Nature Lover', 'Visit 3 nature spots', Icons.forest, count(PlaceCategory.nature), 3),
    b('Thrill Seeker', 'Visit 2 adventure places', Icons.hiking, count(PlaceCategory.adventure), 2),
    b('Wanderer', 'Visit places in 5 different cities', Icons.public, cities, 5),
    b('Critic', 'Write 3 reviews', Icons.rate_review, reviewCount, 3),
    b('Planner', 'Create 2 trips', Icons.event_note, tripCount, 2),
    b('Storyteller', 'Write 3 journal entries', Icons.menu_book, journalCount, 3),
  ];
}

/// One-line "travel personality" from the categories the user visits or
/// is interested in most.
String travelPersonality(List<Place> visited, List<String> interests) {
  final counts = <PlaceCategory, int>{};
  for (final p in visited) {
    counts[p.category] = (counts[p.category] ?? 0) + 2;
  }
  for (final i in interests) {
    final c = PlaceCategory.fromName(i);
    counts[c] = (counts[c] ?? 0) + 1;
  }
  if (counts.isEmpty) return '🧭 Curious Explorer';
  final top = (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  return switch (top) {
    PlaceCategory.heritage => '🏛 History Explorer',
    PlaceCategory.nature => '🌿 Nature Seeker',
    PlaceCategory.beach => '🏖 Beach Bum',
    PlaceCategory.adventure => '🏔 Adventure Seeker',
    PlaceCategory.food => '🍜 Foodie',
    PlaceCategory.spiritual => '🕉 Soul Searcher',
    PlaceCategory.shopping => '🛍 Bazaar Hunter',
    PlaceCategory.nightlife => '🌃 Night Owl',
  };
}
