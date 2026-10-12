import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/theme.dart';
import 'data/services/local_db.dart';
import 'firebase_options.dart';
import 'providers.dart';
import 'router.dart';

/// Pass --dart-define=USE_EMULATOR=true to run against the local Firebase
/// Emulator Suite (used for development and automated testing).
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');
const String emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dates and rupee amounts are formatted for India regardless of the
  // device language.
  await initializeDateFormatting('en_IN');
  Intl.defaultLocale = 'en_IN';

  if (!DefaultFirebaseOptions.isConfigured && !useEmulator) {
    runApp(const _SetupNeededApp());
    return;
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (useEmulator) {
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    }
    // Firestore keeps its own offline cache so reviews and places stay
    // readable without a connection.
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    }
  } catch (e) {
    runApp(_StartupErrorApp(message: 'Could not connect to TravelVerse services.\n$e'));
    return;
  }

  final db = await LocalDb.open();
  runApp(ProviderScope(overrides: [localDbProvider.overrideWithValue(db)], child: const TravelVerseApp()));
}

class TravelVerseApp extends ConsumerWidget {
  const TravelVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TravelVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _SetupNeededApp extends StatelessWidget {
  const _SetupNeededApp();

  @override
  Widget build(BuildContext context) => const _StartupErrorApp(
    message: 'Firebase is not configured yet.\nAdd the project values to lib/firebase_options.dart and set isConfigured = true.',
  );
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_suggest_outlined, size: 56, color: AppTheme.seed),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
}
