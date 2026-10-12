import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/place.dart';
import '../models/review.dart';
import '../seed/places_seed.dart';

/// Catalogue (bundled seed data) plus community data in Firestore:
/// reviews/{placeId_userId} and placeStats/{placeId}.
class PlaceRepository {
  PlaceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  List<Place> get places => seedPlaces;
  late final Map<String, Place> byId = {for (final p in seedPlaces) p.id: p};

  Stream<Map<String, PlaceStats>> watchStats() =>
      _firestore.collection('placeStats').snapshots().map((snap) => {for (final d in snap.docs) d.id: PlaceStats.fromMap(d.data())});

  Stream<List<Review>> reviewsFor(String placeId) => _firestore
      .collection('reviews')
      .where('placeId', isEqualTo: placeId)
      .snapshots()
      .map((s) => s.docs.map((d) => Review.fromMap(d.data())).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<List<Review>> reviewsBy(String userId) => _firestore
      .collection('reviews')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map((d) => Review.fromMap(d.data())).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  /// Latest reviews from all travellers, for the community feed.
  Stream<List<Review>> recentReviews({int limit = 15}) => _firestore
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => Review.fromMap(d.data())).toList());

  /// Saves (or replaces) the user's review and updates the aggregate stats
  /// atomically in one transaction.
  Future<void> submitReview(Review review) async {
    final reviewRef = _firestore.collection('reviews').doc(Review.docId(review.placeId, review.userId));
    final statsRef = _firestore.collection('placeStats').doc(review.placeId);
    await _firestore.runTransaction((txn) async {
      final old = await txn.get(reviewRef);
      final prev = old.exists ? Review.fromMap(old.data()!) : null;
      txn.set(reviewRef, review.toMap());
      txn.set(statsRef, {
        'reviewCount': FieldValue.increment(prev == null ? 1 : 0),
        'ratingSum': FieldValue.increment(review.rating - (prev?.rating ?? 0)),
        'valueSum': FieldValue.increment(review.valueRating - (prev?.valueRating ?? 0)),
        'cleanlinessSum': FieldValue.increment(review.cleanlinessRating - (prev?.cleanlinessRating ?? 0)),
        'accessibilitySum': FieldValue.increment(review.accessibilityRating - (prev?.accessibilityRating ?? 0)),
        'recommendCount': FieldValue.increment((review.recommend ? 1 : 0) - ((prev?.recommend ?? false) ? 1 : 0)),
      }, SetOptions(merge: true));
    });
  }

  Future<void> deleteReview(Review review) async {
    final reviewRef = _firestore.collection('reviews').doc(Review.docId(review.placeId, review.userId));
    final statsRef = _firestore.collection('placeStats').doc(review.placeId);
    await _firestore.runTransaction((txn) async {
      final old = await txn.get(reviewRef);
      if (!old.exists) return;
      final prev = Review.fromMap(old.data()!);
      txn.delete(reviewRef);
      txn.set(statsRef, {
        'reviewCount': FieldValue.increment(-1),
        'ratingSum': FieldValue.increment(-prev.rating),
        'valueSum': FieldValue.increment(-prev.valueRating),
        'cleanlinessSum': FieldValue.increment(-prev.cleanlinessRating),
        'accessibilitySum': FieldValue.increment(-prev.accessibilityRating),
        'recommendCount': FieldValue.increment(prev.recommend ? -1 : 0),
      }, SetOptions(merge: true));
    });
  }
}
