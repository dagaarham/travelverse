import 'package:uuid/uuid.dart';

import '../models/journal_entry.dart';
import '../models/trip.dart';
import '../services/local_db.dart';

/// Trips and journal entries: written to SQLite immediately (works offline)
/// and marked unsynced so [SyncService] uploads them later.
class TripRepository {
  TripRepository(this._db);

  final LocalDb _db;
  static const _uuid = Uuid();

  String newId() => _uuid.v4();

  Future<List<Trip>> trips(String uid) => _db.trips(uid);
  Future<Trip?> trip(String id) => _db.trip(id);

  Future<Trip> saveTrip(Trip trip) async {
    final updated = trip.copyWith(updatedAt: DateTime.now(), synced: false);
    await _db.saveTrip(updated);
    return updated;
  }

  Future<void> deleteTrip(Trip trip) => _db.deleteTrip(trip);

  Future<Trip> addPlace(Trip trip, {required String placeId, required int day, String note = ''}) {
    final position = trip.itemsForDay(day).length;
    final item = TripItem(id: newId(), tripId: trip.id, placeId: placeId, day: day, position: position, note: note.trim());
    return saveTrip(trip.copyWith(items: [...trip.items, item]));
  }

  Future<Trip> removeItem(Trip trip, TripItem item) {
    final remaining = trip.items.where((i) => i.id != item.id).toList();
    // Re-number the day so positions stay contiguous.
    final dayItems = remaining.where((i) => i.day == item.day).toList()..sort((a, b) => a.position.compareTo(b.position));
    final renumbered = [
      ...remaining.where((i) => i.day != item.day),
      for (var k = 0; k < dayItems.length; k++)
        TripItem(id: dayItems[k].id, tripId: trip.id, placeId: dayItems[k].placeId, day: item.day, position: k, note: dayItems[k].note),
    ];
    return saveTrip(trip.copyWith(items: renumbered));
  }

  /// Items scheduled on days beyond a shortened trip are moved to its last day.
  Trip clampItems(Trip trip) {
    final last = trip.dayCount;
    return trip.copyWith(
      items: [
        for (final i in trip.items)
          i.day <= last
              ? i
              : TripItem(id: i.id, tripId: i.tripId, placeId: i.placeId, day: last, position: 1000 + i.position, note: i.note),
      ],
    );
  }

  Future<List<JournalEntry>> journal(String uid, {String? tripId}) => _db.journal(uid, tripId: tripId);

  Future<void> saveJournal(JournalEntry entry) =>
      _db.saveJournal(JournalEntry.fromRow({...entry.toRow(), 'updated_at': DateTime.now().toIso8601String(), 'synced': 0}));

  Future<void> deleteJournal(JournalEntry entry) => _db.deleteJournal(entry);
}
