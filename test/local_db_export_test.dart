import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travelverse/core/export_builder.dart';
import 'package:travelverse/data/models/journal_entry.dart';
import 'package:travelverse/data/models/trip.dart';
import 'package:travelverse/data/repositories/trip_repository.dart';
import 'package:travelverse/data/seed/places_seed.dart';
import 'package:travelverse/data/services/local_db.dart';

void main() {
  sqfliteFfiInit();
  late LocalDb db;
  late TripRepository repo;
  final places = {for (final p in seedPlaces) p.id: p};

  Trip newTrip() => Trip(
        id: 'trip1',
        userId: 'u1',
        name: 'Goa Getaway',
        destination: 'Goa',
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 22),
        travellers: 2,
        budget: 25000,
        tripType: 'Leisure',
      );

  setUp(() async {
    db = await LocalDb.open(factory: databaseFactoryFfi, name: inMemoryDatabasePath);
    repo = TripRepository(db);
  });
  tearDown(() => db.close());

  test('trip with items round-trips through SQLite and is flagged unsynced', () async {
    var trip = await repo.saveTrip(newTrip());
    trip = await repo.addPlace(trip, placeId: 'fort-aguada', day: 1, note: 'Sunset');
    trip = await repo.addPlace(trip, placeId: 'baga-beach', day: 1);
    final loaded = (await repo.trips('u1')).single;
    expect(loaded.dayCount, 3);
    expect(loaded.itemsForDay(1).map((i) => i.placeId), ['fort-aguada', 'baga-beach']);
    expect(loaded.synced, isFalse);
    expect(await db.unsyncedTrips('u1'), hasLength(1));
  });

  test('removing an item renumbers the day', () async {
    var trip = await repo.saveTrip(newTrip());
    trip = await repo.addPlace(trip, placeId: 'fort-aguada', day: 2);
    trip = await repo.addPlace(trip, placeId: 'baga-beach', day: 2);
    trip = await repo.removeItem(trip, trip.itemsForDay(2).first);
    final day2 = (await repo.trip('trip1'))!.itemsForDay(2);
    expect(day2.single.placeId, 'baga-beach');
    expect(day2.single.position, 0);
  });

  test('deleting a trip removes items and queues a cloud delete', () async {
    var trip = await repo.saveTrip(newTrip());
    trip = await repo.addPlace(trip, placeId: 'fort-aguada', day: 1);
    await repo.deleteTrip(trip);
    expect(await repo.trips('u1'), isEmpty);
    expect((await db.pendingDeletes('u1')).single['id'], 'trip1');
  });

  test('shortening a trip moves later items to the last day', () async {
    var trip = await repo.saveTrip(newTrip());
    trip = await repo.addPlace(trip, placeId: 'fort-aguada', day: 3);
    final shorter = repo.clampItems(trip.copyWith(endDate: DateTime(2026, 10, 21)));
    expect(shorter.items.single.day, 2);
  });

  test('a newer local edit is not overwritten by the cloud copy', () async {
    await repo.saveTrip(newTrip().copyWith(name: 'Local name'));
    await db.mergeTripFromCloud(newTrip().copyWith(name: 'Cloud name', synced: true));
    expect((await repo.trip('trip1'))!.name, 'Local name');
  });

  test('journal entries are stored per trip', () async {
    await repo.saveJournal(JournalEntry(id: 'j1', userId: 'u1', title: 'Day one', body: 'Reached Goa at 8 AM', date: DateTime(2026, 10, 20), mood: 5, tripId: 'trip1'));
    await repo.saveJournal(JournalEntry(id: 'j2', userId: 'u1', title: 'Home', body: 'Back in Mumbai', date: DateTime(2026, 10, 25), mood: 3));
    expect(await repo.journal('u1', tripId: 'trip1'), hasLength(1));
    expect(await repo.journal('u1'), hasLength(2));
  });

  group('Export', () {
    test('trip CSV has a header and one row per stop', () async {
      var trip = await repo.saveTrip(newTrip());
      trip = await repo.addPlace(trip, placeId: 'fort-aguada', day: 1, note: 'Sunset, carry water');
      trip = await repo.addPlace(trip, placeId: 'baga-beach', day: 2);
      final lines = ExportBuilder.tripCsv(trip, places).trim().split('\n');
      expect(lines.first, startsWith('Day,Date,Order,Place'));
      expect(lines, hasLength(3));
      expect(lines[1], contains('Fort Aguada'));
      expect(lines[1], contains('"Sunset, carry water"'));
    });

    test('journal text lists entries oldest first', () {
      final txt = ExportBuilder.journalTxt('Goa journal', [
        JournalEntry(id: 'b', userId: 'u', title: 'Second', body: 'B', date: DateTime(2026, 10, 21), mood: 4),
        JournalEntry(id: 'a', userId: 'u', title: 'First', body: 'A', date: DateTime(2026, 10, 20), mood: 5, placeId: 'fort-aguada'),
      ], places);
      expect(txt.indexOf('First'), lessThan(txt.indexOf('Second')));
      expect(txt, contains('Place: Fort Aguada, Goa'));
      expect(txt, contains('★★★★★'));
    });

    test('file names are made safe', () => expect(ExportBuilder.fileName('  My Goa Trip!! ', 'csv'), 'my_goa_trip.csv'));
  });
}
