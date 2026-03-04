// lib/firebase_options.dart
//
// All values are supplied via --dart-define at build time:
//   --dart-define=FIREBASE_API_KEY=<value>
//   --dart-define=FIREBASE_PROJECT_ID=<value>
//   --dart-define=FIREBASE_APP_ID=<value>
//   --dart-define=FIREBASE_MESSAGING_SENDER_ID=<value>
//   --dart-define=FIREBASE_ANDROID_API_KEY=<value>
//   --dart-define=FIREBASE_ANDROID_APP_ID=<value>
//   --dart-define=FIREBASE_IOS_API_KEY=<value>
//   --dart-define=FIREBASE_IOS_APP_ID=<value>
//   --dart-define=FIREBASE_MACOS_API_KEY=<value>
//   --dart-define=FIREBASE_MACOS_APP_ID=<value>

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _apiKey,
    authDomain: '$_projectId.firebaseapp.com',
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
    messagingSenderId: _messagingSenderId,
    appId: _appId,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: ''),
    authDomain: '',
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
    messagingSenderId: _messagingSenderId,
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: ''),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: ''),
    authDomain: '',
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
    messagingSenderId: _messagingSenderId,
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: ''),
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_MACOS_API_KEY', defaultValue: ''),
    authDomain: '',
    projectId: _projectId,
    storageBucket: '$_projectId.firebasestorage.app',
    messagingSenderId: _messagingSenderId,
    appId: String.fromEnvironment('FIREBASE_MACOS_APP_ID', defaultValue: ''),
  );
}

