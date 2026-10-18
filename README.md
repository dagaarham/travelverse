# TouchGrass — Discover. Plan. Remember.

A community-driven travel app built with **Flutter** for the Mobile Application Development (702AI0E002) mini project, MPSTME NMIMS, 2026-27.

**Team:** Arham Daga · Manthan Bumb · Prithvi Agarwal

Travellers discover places through structured reviews from other travellers, turn them into day-wise itineraries that work offline, and keep a photo journal of every trip.

## Features

| Area | What it does | Syllabus topic |
|---|---|---|
| Sign up / login / reset password | Firebase Authentication with full validation (name, email, Indian mobile, strong password, confirm, terms checkbox) | Unit 6 Firebase, controls |
| Onboarding | Interests (checkboxes), travel style (radio buttons), home city | Unit 2 check boxes, radio buttons |
| Home | Personalised recommendations, "Because you liked…", near you, hidden gems, community feed | Recommendation engine |
| Explore | Search, category chips, sort spinner, filter bottom sheet (rating slider, budget, companions, distance) | Unit 2 spinner, layouts |
| Place page | Photos, rating breakdown, % recommend, save, mark visited, add to trip, directions (implicit intent), share | Units 2, 3, 7 |
| Reviews | Overall + 3 sub-ratings (touch-listener stars), text, best time, would-you-recommend; **Verified Visit** badge | Unit 2 touch listener |
| Map | OpenStreetMap, current location, all places as markers, "Explore nearby" radius search, saved/visited layers | Unit 4 location tracking |
| Trips | Create/edit with **date pickers**, day tabs, add/remove places, confirmation dialogs, trip map with route, **.csv export** | Units 2, 3, 4 |
| Journal | Entries with **camera or gallery photo**, date picker, place/trip spinners, experience rating, **.txt export** | Unit 3 images & files |
| Profile | Stats, travel personality, badges, want-to-visit / visited / reviews tabs, overflow **menu** | Unit 2 menus |
| Offline-first | Trips and journal live in **SQLite** and sync to Firestore when online; offline banner reacts to the network broadcast | Unit 6 SQLite, broadcast |
| SOS | One-tap emergency numbers and SMS location sharing via implicit intents | Intents |

Self-learned concepts beyond the syllabus: content-based recommendation engine, offline-first sync, Haversine geo-distance discovery, Riverpod state management, declarative routing (go_router), CI/CD with GitHub Actions.

## Tech stack

Flutter 3.47 · Dart · Material 3 (light theme) · Riverpod · go_router · Firebase Auth + Cloud Firestore · sqflite · flutter_map (OpenStreetMap) · geolocator · image_picker · share_plus · url_launcher · connectivity_plus · place photos bundled from Wikimedia Commons.

All services used are free: Firebase Spark plan, OpenStreetMap tiles, Wikimedia Commons photos, GitHub Actions/Pages.

## Project structure

```
lib/
  core/          validators, geo maths, recommender, badges, theme, export builder
  data/
    models/      Place, Review, AppUser, Trip, TripItem, JournalEntry
    seed/        curated catalogue of 50 Indian destinations
    services/    SQLite (LocalDb), SyncService, WikiService, LocationService, ExportService
    repositories auth, user, place/review, trip/journal
  features/      one folder per module (auth, onboarding, home, explore, place, map, trips, journal, profile, safety)
  shared/        app shell (bottom navigation) and reusable widgets
  providers.dart Riverpod dependency graph
  router.dart    routes + auth/onboarding redirects
test/            unit and widget tests (56 tests)
firestore.rules  security rules
```

## Running locally (Android Studio)

1. Install Flutter 3.47+ and Android Studio with the Flutter plugin.
2. `flutter pub get`
3. Start an emulator (or plug in a phone with USB debugging) and press **Run**, or `flutter run`.
4. Tests: `flutter test`

To develop without the real Firebase project, run the Firebase Emulator Suite (`firebase emulators:start`) and launch with `--dart-define=USE_EMULATOR=true` (use `--dart-define=EMULATOR_HOST=10.0.2.2` on the Android emulator).

## Firebase setup (once)

1. Firebase console → Authentication → enable **Email/Password**.
2. Firestore Database → create (asia-south1) → **Rules** tab → paste `firestore.rules` → Publish.
3. Put the Android and Web app values in `lib/firebase_options.dart` and set `isConfigured = true`.
4. For the web demo, add `<your-user>.github.io` under Authentication → Settings → Authorized domains.

## Deployment

Every push to `main` runs GitHub Actions (`.github/workflows/build.yml`):

- **Tests**: `flutter analyze` + `flutter test`
- **Android**: signed release **APK** and Play-ready **AAB**, published to the `latest` GitHub Release
- **Web**: built and published to GitHub Pages (`gh-pages` branch)

The release keystore (`android/app/travelverse-release.jks`, passwords in `android/key.properties`) is committed deliberately so CI can sign builds without extra setup. For a real Play Store launch, generate a private upload key and keep it out of the repository.

## Credits

Maps © OpenStreetMap contributors. Place photos from Wikimedia Commons under the licences listed in [assets/places/CREDITS.md](assets/places/CREDITS.md).
