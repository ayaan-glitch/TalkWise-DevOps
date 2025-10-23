// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: 'AIzaSyBeOUdazZV77bFttDe1llF7s6inaB-j-3g',
        appId: '1:552144048777:web:e7e98994818a0523e92c58',
        messagingSenderId: '552144048777',
        projectId: 'talkwise-89be5',
        authDomain: 'talkwise-89be5.firebaseapp.com',
        storageBucket: 'talkwise-89be5.appspot.com',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: 'AIzaSyBeOUdazZV77bFttDe1llF7s6inaB-j-3g',
          appId: '1:552144048777:android:3adf81c4afc92354e92c58',
          messagingSenderId: '552144048777',
          projectId: 'talkwise-89be5',
          storageBucket: 'talkwise-89be5.appspot.com',
        );

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}