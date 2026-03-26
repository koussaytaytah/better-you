import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcZjQ4qF03_dpB2haEodhkSHC-rXVnh8M',
    appId: '1:726099505354:android:0c9155642fa974f5f14433',
    messagingSenderId: '726099505354',
    projectId: 'better-you-f6919',
    storageBucket: 'better-you-f6919.firebasestorage.app',
  );
}
