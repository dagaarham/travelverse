import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';
import '../models/trip.dart';
import 'local_db.dart';

/// Offline-first sync: SQLite is the source of truth on the device. Local
/// changes are flagged `synced = 0` and pushed to Firestore when online;
/// cloud copies are pulled down on login so trips follow the user.
class SyncService {
  SyncService(this._db, this._firestore);

  final LocalDb _db;
  final FirebaseFirestore _firestore;
  bool _running = false;

  CollectionReference<Map<String, dynamic>> _trips(String uid) => _firestore.collection('users').doc(uid).collection('trips');
  CollectionReference<Map<String, dynamic>> _journal(String uid) => _firestore.collection('users').doc(uid).collection('journal');

  /// Returns the number of records pushed, or -1 if a sync was already running.
  Future<int> sync(String uid) async {
    if (_running) return -1;
    _running = true;
    var pushed = 0;
    try {
      for (final d in await _db.pendingDeletes(uid)) {
        final id = d['id'] as String;
        await (d['kind'] == 'trip' ? _trips(uid) : _journal(uid)).doc(id).delete();
        await _db.clearPendingDelete(id);
        pushed++;
      }
      for (final t in await _db.unsyncedTrips(uid)) {
        await _trips(uid).doc(t.id).set(t.toCloud());
        await _db.markTripSynced(t.id);
        pushed++;
      }
      for (final e in await _db.unsyncedJournal(uid)) {
        await _journal(uid).doc(e.id).set(e.toCloud());
        await _db.markJournalSynced(e.id);
        pushed++;
      }
      final cloudTrips = await _trips(uid).get();
      for (final doc in cloudTrips.docs) {
        await _db.mergeTripFromCloud(Trip.fromCloud(doc.data()));
      }
      final cloudJournal = await _journal(uid).get();
      for (final doc in cloudJournal.docs) {
        await _db.mergeJournalFromCloud(JournalEntry.fromRow({...doc.data(), 'synced': 1}));
      }
    } catch (e) {
      // Offline or rules rejected the write: data stays flagged and is retried.
      debugPrint('Sync deferred: $e');
    } finally {
      _running = false;
    }
    return pushed;
  }
}
