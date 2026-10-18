import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travelverse/data/seed/places_seed.dart';

void main() {
  test('every place has a bundled photo', () {
    final missing = seedPlaces.where((p) => !File(p.photoAsset).existsSync()).map((p) => p.id).toList();
    expect(missing, isEmpty, reason: 'Run tool/fetch_place_photos.py (Fetch place photos workflow)');
  });

  test('every bundled photo is credited', () {
    final credits = File('assets/places/CREDITS.md').readAsStringSync();
    final uncredited = seedPlaces.where((p) => !credits.contains('| ${p.name} |')).map((p) => p.id).toList();
    expect(uncredited, isEmpty);
  });
}
