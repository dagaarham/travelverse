// Firebase configuration for the TravelVerse Firebase project.
// Values come from the Firebase console (Project settings > Your apps).
// They identify the project and are safe to ship in the app; access is
// controlled by Firestore security rules (see firestore.rules).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Set to false to show the setup screen instead of connecting.
  static const bool isConfigured = true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('TravelVerse supports Android and web only.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-VN-sROD_ahik3P814eGLFGjTTl0lc94',
    appId: '1:1082766315122:android:73295ebd73a8c07e1f7ceb',
    messagingSenderId: '1082766315122',
    projectId: 'travelverse-9999',
    storageBucket: 'travelverse-9999.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAjV0ezUCzTR1ODl0UrrU7NRrQcr1AIWDw',
    appId: '1:1082766315122:web:bfd09545aadd17ba1f7ceb',
    messagingSenderId: '1082766315122',
    projectId: 'travelverse-9999',
    authDomain: 'travelverse-9999.firebaseapp.com',
    storageBucket: 'travelverse-9999.firebasestorage.app',
    measurementId: 'G-STQBNZDHCG',
  );
}
