// Firebase configuration for the TravelVerse Firebase project.
// Values come from the Firebase console (Project settings > Your apps).
// They identify the project and are safe to ship in the app; access is
// controlled by Firestore security rules (see firestore.rules).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// False until the real project values below are filled in.
  static const bool isConfigured = false;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('TravelVerse supports Android and web only.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-travelverse',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-travelverse',
    authDomain: 'demo-travelverse.firebaseapp.com',
  );
}
