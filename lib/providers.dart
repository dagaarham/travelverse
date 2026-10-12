import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'core/recommender.dart';
import 'data/models/app_user.dart';
import 'data/models/journal_entry.dart';
import 'data/models/place.dart';
import 'data/models/review.dart';
import 'data/models/trip.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/place_repository.dart';
import 'data/repositories/trip_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/services/export_service.dart';
import 'data/services/local_db.dart';
import 'data/services/location_service.dart';
import 'data/services/sync_service.dart';
import 'data/services/wiki_service.dart';

// ---------------- Infrastructure ----------------

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Opened in main() and injected with an override.
final localDbProvider = Provider<LocalDb>((ref) => throw UnimplementedError('LocalDb not opened'));

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)));
final userRepositoryProvider = Provider((ref) => UserRepository(ref.watch(firestoreProvider)));
final placeRepositoryProvider = Provider((ref) => PlaceRepository(ref.watch(firestoreProvider)));
final tripRepositoryProvider = Provider((ref) => TripRepository(ref.watch(localDbProvider)));
final syncServiceProvider = Provider((ref) => SyncService(ref.watch(localDbProvider), ref.watch(firestoreProvider)));
final wikiServiceProvider = Provider((ref) => WikiService());
final locationServiceProvider = Provider((ref) => LocationService());
final exportServiceProvider = Provider((ref) => ExportService());
final recommenderProvider = Provider((ref) => const Recommender());

// ---------------- Session ----------------

final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

final uidProvider = Provider<String?>((ref) => ref.watch(authStateProvider).value?.uid);

final profileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watch(uid);
});

/// Emits true while the device has a network connection (a broadcast from
/// the OS, delivered through connectivity_plus).
final onlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool isOnline(List<ConnectivityResult> r) => r.any((c) => c != ConnectivityResult.none);
  yield isOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(isOnline);
});

// ---------------- Places ----------------

final placesProvider = Provider<List<Place>>((ref) => ref.watch(placeRepositoryProvider).places);
final placeByIdProvider = Provider<Map<String, Place>>((ref) => ref.watch(placeRepositoryProvider).byId);

final placeStatsProvider = StreamProvider<Map<String, PlaceStats>>((ref) => ref.watch(placeRepositoryProvider).watchStats());

/// Combined community rating for a place (seed baseline + app reviews).
final ratingOfProvider = Provider<double Function(Place)>((ref) {
  final stats = ref.watch(placeStatsProvider).value ?? const {};
  return (p) => (stats[p.id] ?? const PlaceStats()).ratingFor(p);
});

final placeReviewsProvider = StreamProvider.family<List<Review>, String>(
  (ref, placeId) => ref.watch(placeRepositoryProvider).reviewsFor(placeId),
);

final myReviewsProvider = StreamProvider<List<Review>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(placeRepositoryProvider).reviewsBy(uid);
});

final communityFeedProvider = StreamProvider<List<Review>>((ref) => ref.watch(placeRepositoryProvider).recentReviews());

// ---------------- Location ----------------

/// Last known device position; null until the user asks for it.
class PositionNotifier extends Notifier<AsyncValue<Position?>> {
  @override
  AsyncValue<Position?> build() => const AsyncData(null);

  Future<void> locate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(locationServiceProvider).current());
  }
}

final positionProvider = NotifierProvider<PositionNotifier, AsyncValue<Position?>>(PositionNotifier.new);

final recommendationsProvider = Provider<List<Recommendation>>((ref) {
  final profile = ref.watch(profileProvider).value;
  final pos = ref.watch(positionProvider).value;
  return ref
      .watch(recommenderProvider)
      .recommend(
        places: ref.watch(placesProvider),
        interests: profile?.interests ?? const [],
        myReviews: ref.watch(myReviewsProvider).value ?? const [],
        visitedIds: (profile?.visitedPlaceIds ?? const []).toSet(),
        ratingOf: ref.watch(ratingOfProvider),
        travelStyle: profile?.travelStyle ?? '',
        lat: pos?.latitude,
        lng: pos?.longitude,
      );
});

// ---------------- Trips & journal (SQLite) ----------------

final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const [];
  return ref.watch(tripRepositoryProvider).trips(uid);
});

final tripProvider = FutureProvider.family<Trip?, String>((ref, id) async {
  ref.watch(tripsProvider);
  return ref.watch(tripRepositoryProvider).trip(id);
});

final journalProvider = FutureProvider.family<List<JournalEntry>, String?>((ref, tripId) async {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const [];
  return ref.watch(tripRepositoryProvider).journal(uid, tripId: tripId);
});

/// Refreshes trip/journal lists after a local change and pushes pending
/// changes to the cloud when online.
class DataSync {
  DataSync(this._ref);

  final Ref _ref;

  Future<void> refresh() async {
    _ref.invalidate(tripsProvider);
    _ref.invalidate(journalProvider);
    final uid = _ref.read(uidProvider);
    if (uid == null || !(_ref.read(onlineProvider).value ?? false)) return;
    final pushed = await _ref.read(syncServiceProvider).sync(uid);
    if (pushed != 0) {
      _ref.invalidate(tripsProvider);
      _ref.invalidate(journalProvider);
    }
  }
}

final dataSyncProvider = Provider((ref) => DataSync(ref));
