import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Reads and updates the signed-in traveller's profile.
class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore.collection('users').doc(uid);

  Stream<AppUser?> watch(String uid) => _doc(uid).snapshots().map((s) => s.exists ? AppUser.fromMap(uid, s.data()!) : null);

  Future<void> completeOnboarding(String uid, {required List<String> interests, required String travelStyle, required String homeCity}) {
    return _doc(uid)
        .set({'interests': interests, 'travelStyle': travelStyle, 'homeCity': homeCity.trim(), 'onboarded': true}, SetOptions(merge: true));
  }

  Future<void> updateProfile(String uid, {required String name, required String phone, required String homeCity, required String bio}) {
    return _doc(uid).update({'name': name.trim(), 'phone': phone.trim(), 'homeCity': homeCity.trim(), 'bio': bio.trim()});
  }

  Future<void> updateInterests(String uid, List<String> interests, String travelStyle) =>
      _doc(uid).update({'interests': interests, 'travelStyle': travelStyle});

  /// Adds or removes a place from the "Want to visit" list and keeps the
  /// public save counter in step.
  Future<bool> toggleSaved(String uid, String placeId, bool currentlySaved) async {
    final batch = _firestore.batch()
      ..update(_doc(uid), {
        'savedPlaceIds': currentlySaved ? FieldValue.arrayRemove([placeId]) : FieldValue.arrayUnion([placeId]),
      })
      ..set(_firestore.collection('placeStats').doc(placeId), {
        'savedCount': FieldValue.increment(currentlySaved ? -1 : 1),
      }, SetOptions(merge: true));
    await batch.commit();
    return !currentlySaved;
  }

  Future<bool> toggleVisited(String uid, String placeId, bool currentlyVisited) async {
    final batch = _firestore.batch()
      ..update(_doc(uid), {
        'visitedPlaceIds': currentlyVisited ? FieldValue.arrayRemove([placeId]) : FieldValue.arrayUnion([placeId]),
        // Visiting a place takes it off the wish list.
        if (!currentlyVisited) 'savedPlaceIds': FieldValue.arrayRemove([placeId]),
      })
      ..set(_firestore.collection('placeStats').doc(placeId), {
        'visitedCount': FieldValue.increment(currentlyVisited ? -1 : 1),
      }, SetOptions(merge: true));
    await batch.commit();
    return !currentlyVisited;
  }
}
