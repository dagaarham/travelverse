import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/journal_entry.dart';
import '../models/trip.dart';

/// SQLite storage for offline-first data (trips, itinerary items, journal).
class LocalDb {
  LocalDb._(this._db);

  final Database _db;

  static const _version = 1;

  static Future<LocalDb> open({DatabaseFactory? factory, String name = 'travelverse.db'}) async {
    final f = factory ?? (kIsWeb ? databaseFactoryFfiWeb : databaseFactory);
    final path = kIsWeb || name == inMemoryDatabasePath ? name : p.join(await f.getDatabasesPath(), name);
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(version: _version, onCreate: _create, onConfigure: _configure),
    );
    return LocalDb._(db);
  }

  static Future<void> _configure(Database db) => db.execute('PRAGMA foreign_keys = ON');

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        destination TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        travellers INTEGER NOT NULL,
        budget INTEGER NOT NULL,
        trip_type TEXT NOT NULL,
        notes TEXT,
        updated_at TEXT,
        synced INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE trip_items(
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        place_id TEXT NOT NULL,
        day INTEGER NOT NULL,
        position INTEGER NOT NULL,
        note TEXT
      )''');
    await db.execute('''
      CREATE TABLE journal_entries(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        date TEXT NOT NULL,
        mood INTEGER NOT NULL,
        trip_id TEXT,
        place_id TEXT,
        photo_path TEXT,
        updated_at TEXT,
        synced INTEGER NOT NULL DEFAULT 0
      )''');
    // Deletions made while offline, pushed to the cloud on the next sync.
    await db.execute('''
      CREATE TABLE pending_deletes(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        kind TEXT NOT NULL
      )''');
  }

  // ---------------- Trips ----------------

  Future<List<Trip>> trips(String userId) async {
    final rows = await _db.query('trips', where: 'user_id = ?', whereArgs: [userId], orderBy: 'start_date ASC');
    final result = <Trip>[];
    for (final r in rows) {
      result.add(Trip.fromRow(r, await _items(r['id'] as String)));
    }
    return result;
  }

  Future<Trip?> trip(String id) async {
    final rows = await _db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Trip.fromRow(rows.first, await _items(id));
  }

  Future<List<TripItem>> _items(String tripId) async {
    final rows = await _db.query('trip_items', where: 'trip_id = ?', whereArgs: [tripId], orderBy: 'day, position');
    return rows.map(TripItem.fromRow).toList();
  }

  /// Inserts or replaces a trip together with all of its items.
  Future<void> saveTrip(Trip trip) async {
    await _db.transaction((txn) async {
      await txn.insert('trips', trip.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('trip_items', where: 'trip_id = ?', whereArgs: [trip.id]);
      for (final item in trip.items) {
        await txn.insert('trip_items', item.toRow());
      }
    });
  }

  Future<void> deleteTrip(Trip trip) async {
    await _db.transaction((txn) async {
      await txn.delete('trips', where: 'id = ?', whereArgs: [trip.id]);
      await txn.insert('pending_deletes', {
        'id': trip.id,
        'user_id': trip.userId,
        'kind': 'trip',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> markTripSynced(String id) => _db.update('trips', {'synced': 1}, where: 'id = ?', whereArgs: [id]);

  // ---------------- Journal ----------------

  Future<List<JournalEntry>> journal(String userId, {String? tripId}) async {
    final rows = await _db.query(
      'journal_entries',
      where: tripId == null ? 'user_id = ?' : 'user_id = ? AND trip_id = ?',
      whereArgs: tripId == null ? [userId] : [userId, tripId],
      orderBy: 'date DESC',
    );
    return rows.map(JournalEntry.fromRow).toList();
  }

  Future<void> saveJournal(JournalEntry entry) =>
      _db.insert('journal_entries', entry.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteJournal(JournalEntry entry) async {
    await _db.transaction((txn) async {
      await txn.delete('journal_entries', where: 'id = ?', whereArgs: [entry.id]);
      await txn.insert('pending_deletes', {
        'id': entry.id,
        'user_id': entry.userId,
        'kind': 'journal',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> markJournalSynced(String id) => _db.update('journal_entries', {'synced': 1}, where: 'id = ?', whereArgs: [id]);

  // ---------------- Sync bookkeeping ----------------

  Future<List<Trip>> unsyncedTrips(String userId) async => (await trips(userId)).where((t) => !t.synced).toList();

  Future<List<JournalEntry>> unsyncedJournal(String userId) async => (await journal(userId)).where((e) => !e.synced).toList();

  Future<List<Map<String, Object?>>> pendingDeletes(String userId) =>
      _db.query('pending_deletes', where: 'user_id = ?', whereArgs: [userId]);

  Future<void> clearPendingDelete(String id) => _db.delete('pending_deletes', where: 'id = ?', whereArgs: [id]);

  /// Copies a cloud record locally unless a newer local edit exists.
  Future<void> mergeTripFromCloud(Trip cloud) async {
    final local = await trip(cloud.id);
    if (local != null && !local.synced) return;
    await saveTrip(cloud.copyWith(synced: true));
  }

  Future<void> mergeJournalFromCloud(JournalEntry cloud) async {
    final rows = await _db.query('journal_entries', where: 'id = ?', whereArgs: [cloud.id]);
    if (rows.isNotEmpty) {
      final local = JournalEntry.fromRow(rows.first);
      if (!local.synced) return;
      // Keep the photo that only exists on this device.
      await saveJournal(JournalEntry.fromRow({...cloud.toRow(), 'photo_path': local.photoPath, 'synced': 1}));
      return;
    }
    await saveJournal(JournalEntry.fromRow({...cloud.toRow(), 'synced': 1}));
  }

  Future<void> close() => _db.close();
}
